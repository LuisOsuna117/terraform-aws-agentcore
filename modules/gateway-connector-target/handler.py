"""CloudFormation lifecycle provider for AgentCore connector targets.

The AgentCore control-plane API can support a connector before the Lambda
runtime's bundled SDK model does. Requests are therefore sent through the
documented REST API and signed with the function's workload credentials.
"""

import hashlib
import json
import logging
import re
import time
import urllib.error
import urllib.parse
import urllib.request

import botocore.session
import cfnresponse
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest


LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

READY = "READY"
FAILED = {"FAILED", "UPDATE_UNSUCCESSFUL", "SYNCHRONIZE_UNSUCCESSFUL"}
TARGET_ID = re.compile(r"^[0-9A-Za-z]{10}$")


class AgentCoreApiError(RuntimeError):
    """An error returned by the AgentCore control plane."""

    def __init__(self, status, message):
        super().__init__(f"AgentCore API returned HTTP {status}: {message}")
        self.status = status


def _api_request(method, properties, path, body=None):
    endpoint = properties["Endpoint"].rstrip("/")
    url = f"{endpoint}{path}"
    payload = None
    headers = {"accept": "application/json"}
    if body is not None:
        payload = json.dumps(body, separators=(",", ":")).encode("utf-8")
        headers["content-type"] = "application/json"

    session = botocore.session.get_session()
    credentials = session.get_credentials().get_frozen_credentials()
    signed = AWSRequest(method=method, url=url, data=payload, headers=headers)
    SigV4Auth(credentials, "bedrock-agentcore", properties["Region"]).add_auth(signed)

    request = urllib.request.Request(
        url,
        data=payload,
        headers=dict(signed.headers.items()),
        method=method,
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            response_body = response.read()
    except urllib.error.HTTPError as error:
        response_body = error.read()
        try:
            error_payload = json.loads(response_body or b"{}")
            message = error_payload.get("message") or error_payload.get("Message")
        except json.JSONDecodeError:
            message = response_body.decode("utf-8", errors="replace")
        raise AgentCoreApiError(error.code, message or error.reason) from error

    return json.loads(response_body) if response_body else {}


def _target_path(properties, target_id=None):
    gateway_id = urllib.parse.quote(properties["GatewayIdentifier"], safe="")
    path = f"/gateways/{gateway_id}/targets/"
    if target_id:
        path += f"{urllib.parse.quote(target_id, safe='')}/"
    return path


def _target_configuration(properties):
    return {
        "mcp": {
            "connector": {
                "source": {
                    "connectorId": properties["ConnectorId"],
                    "version": properties["ConnectorVersion"],
                },
                "configurations": properties["Configurations"],
            }
        }
    }


def _target_request(properties):
    return {
        "name": properties["Name"],
        "description": properties.get(
            "Description", "Managed AgentCore Gateway connector target."
        ),
        "targetConfiguration": _target_configuration(properties),
        "credentialProviderConfigurations": [
            {"credentialProviderType": "GATEWAY_IAM_ROLE"}
        ],
    }


def _get(properties, target_id):
    return _api_request("GET", properties, _target_path(properties, target_id))


def _wait_ready(properties, target_id):
    for _ in range(150):
        target = _get(properties, target_id)
        status = target["status"]
        if status == READY:
            return target
        if status in FAILED:
            reasons = "; ".join(target.get("statusReasons", []))
            raise RuntimeError(f"AgentCore target entered {status}: {reasons}")
        time.sleep(4)
    raise TimeoutError("AgentCore target did not become READY within 10 minutes")


def _delete(properties, target_id):
    if not target_id or not TARGET_ID.fullmatch(target_id):
        return
    try:
        _api_request("DELETE", properties, _target_path(properties, target_id))
    except AgentCoreApiError as error:
        if error.status == 404:
            return
        raise

    for _ in range(150):
        try:
            _get(properties, target_id)
        except AgentCoreApiError as error:
            if error.status == 404:
                return
            raise
        time.sleep(4)
    raise TimeoutError("AgentCore target was not deleted within 10 minutes")


def _assert_pinned(target, properties):
    source = target["targetConfiguration"]["mcp"]["connector"]["source"]
    expected = (properties["ConnectorId"], properties["ConnectorVersion"])
    actual = (source.get("connectorId"), source.get("version"))
    if actual != expected:
        raise RuntimeError(
            f"AgentCore returned connector {actual!r}; expected {expected!r}"
        )


def _create(event, properties):
    body = _target_request(properties)
    body["clientToken"] = hashlib.sha256(
        f"{event['StackId']}:{event['LogicalResourceId']}:{event['RequestId']}".encode()
    ).hexdigest()
    response = _api_request("POST", properties, _target_path(properties), body)
    target_id = response["targetId"]
    try:
        target = _wait_ready(properties, target_id)
        _assert_pinned(target, properties)
        return target
    except Exception:
        _delete(properties, target_id)
        raise


def _update(properties, target_id):
    response = _api_request(
        "PUT",
        properties,
        _target_path(properties, target_id),
        _target_request(properties),
    )
    target = _wait_ready(properties, response["targetId"])
    _assert_pinned(target, properties)
    return target


def handler(event, context):
    properties = event["ResourceProperties"]
    target_id = event.get("PhysicalResourceId")

    try:
        if event["RequestType"] == "Delete":
            _delete(properties, target_id)
            cfnresponse.send(event, context, cfnresponse.SUCCESS, {}, target_id)
            return

        target = (
            _create(event, properties)
            if event["RequestType"] == "Create"
            else _update(properties, target_id)
        )
        data = {"TargetId": target["targetId"], "GatewayArn": target["gatewayArn"]}
        cfnresponse.send(
            event, context, cfnresponse.SUCCESS, data, target["targetId"]
        )
    except Exception as error:
        LOGGER.exception("Connector target lifecycle failed")
        cfnresponse.send(
            event,
            context,
            cfnresponse.FAILED,
            {},
            target_id,
            reason=str(error),
        )
