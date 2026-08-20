"""CloudFormation lifecycle adapter for the current AWS Agent Registry API."""

import json
import os
import time
import urllib.error
import urllib.request

from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest
from botocore.session import Session


REGION = os.environ["AWS_REGION"]
ENDPOINT = f"https://agent-registry-control.{REGION}.api.aws"


def _call(method, path, payload=None):
    body = json.dumps(payload).encode() if payload is not None else None
    request = AWSRequest(
        method=method,
        url=f"{ENDPOINT}{path}",
        data=body,
        headers={"Content-Type": "application/json"},
    )
    credentials = Session().get_credentials().get_frozen_credentials()
    SigV4Auth(credentials, "agent-registry", REGION).add_auth(request)
    outbound = urllib.request.Request(
        request.url,
        data=body,
        headers=dict(request.headers),
        method=method,
    )
    try:
        with urllib.request.urlopen(outbound, timeout=30) as response:
            content = response.read()
            return response.status, json.loads(content) if content else {}
    except urllib.error.HTTPError as error:
        content = error.read()
        return error.code, json.loads(content) if content else {}


def _wait_ready(registry_id):
    for _ in range(24):
        status, body = _call("GET", f"/registries/{registry_id}")
        if status != 200:
            raise RuntimeError(f"get registry failed ({status})")
        state = body.get("status")
        if state == "READY":
            return
        if state and "FAILED" in state:
            raise RuntimeError(f"registry entered {state}")
        time.sleep(5)
    raise TimeoutError("registry did not become READY within 120 seconds")


def _find(name):
    status, body = _call("POST", "/registries-list", {})
    if status != 200:
        raise RuntimeError(f"list registries failed ({status})")
    for registry in body.get("registries", []):
        if registry.get("name") == name:
            return registry.get("registryId"), registry.get("registryArn")
    return None, None


def _create(name, client_token):
    registry_id, registry_arn = _find(name)
    if registry_id:
        _wait_ready(registry_id)
        return registry_id, registry_arn
    status, body = _call(
        "POST",
        "/registries",
        {
            "name": name,
            "description": "AEGIS shadow discovery; never an authorization source",
            "approvalConfiguration": {"autoApprovalRules": []},
            "clientToken": client_token,
        },
    )
    if status not in {200, 201, 202}:
        raise RuntimeError(f"create registry failed ({status})")
    registry_arn = body["registryArn"]
    registry_id = registry_arn.rsplit("/", 1)[-1]
    _wait_ready(registry_id)
    return registry_id, registry_arn


def _delete(registry_id):
    status, body = _call("POST", f"/registries/{registry_id}/records-list", {})
    if status not in {200, 404}:
        raise RuntimeError(f"list registry records failed ({status})")
    for record in body.get("registryRecords", []):
        record_id = record.get("recordId")
        if record_id:
            status, _ = _call("DELETE", f"/registries/{registry_id}/records/{record_id}")
            if status not in {200, 202, 204, 404}:
                raise RuntimeError(f"delete registry record failed ({status})")
    status, _ = _call("DELETE", f"/registries/{registry_id}")
    if status not in {200, 202, 204, 404}:
        raise RuntimeError(f"delete registry failed ({status})")


def _respond(event, context, status, data=None, reason=None, physical_id=None):
    body = json.dumps(
        {
            "Status": status,
            "Reason": (reason or f"See {context.log_stream_name}")[:512],
            "PhysicalResourceId": physical_id
            or event.get("PhysicalResourceId")
            or context.log_stream_name,
            "StackId": event["StackId"],
            "RequestId": event["RequestId"],
            "LogicalResourceId": event["LogicalResourceId"],
            "NoEcho": False,
            "Data": data or {},
        }
    ).encode()
    request = urllib.request.Request(event["ResponseURL"], data=body, method="PUT")
    request.add_header("Content-Type", "")
    request.add_header("Content-Length", str(len(body)))
    with urllib.request.urlopen(request, timeout=30):
        return


def lambda_handler(event, context):
    physical_id = event.get("PhysicalResourceId")
    try:
        request_type = event["RequestType"]
        name = event["ResourceProperties"]["RegistryName"]
        if request_type == "Delete":
            if physical_id:
                _delete(physical_id)
            _respond(event, context, "SUCCESS", physical_id=physical_id)
            return
        old_name = event.get("OldResourceProperties", {}).get("RegistryName")
        if request_type == "Update" and old_name != name and physical_id:
            _delete(physical_id)
        registry_id, registry_arn = _create(name, event["RequestId"])
        _respond(
            event,
            context,
            "SUCCESS",
            {"RegistryId": registry_id, "RegistryArn": registry_arn},
            physical_id=registry_id,
        )
    except Exception as error:
        _respond(event, context, "FAILED", reason=str(error), physical_id=physical_id)
