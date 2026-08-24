"""CloudFormation lifecycle provider for versioned AgentCore connector targets."""

import logging
import time

import boto3
import cfnresponse
from botocore.exceptions import ClientError


LOGGER = logging.getLogger()
LOGGER.setLevel(logging.INFO)

READY = "READY"
FAILED = {
    "FAILED",
    "UPDATE_UNSUCCESSFUL",
    "SYNCHRONIZE_UNSUCCESSFUL",
}
NOT_FOUND = "ResourceNotFoundException"


def _configuration(properties):
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


def _request(properties):
    request = {
        "name": properties["Name"],
        "description": properties.get(
            "Description", "Managed AgentCore Gateway connector target."
        ),
        "targetConfiguration": _configuration(properties),
        "credentialProviderConfigurations": [
            {"credentialProviderType": "GATEWAY_IAM_ROLE"}
        ],
    }
    return request


def _get(client, gateway_id, target_id):
    return client.get_gateway_target(
        gatewayIdentifier=gateway_id,
        targetId=target_id,
    )


def _wait_ready(client, gateway_id, target_id):
    for _ in range(150):
        target = _get(client, gateway_id, target_id)
        status = target["status"]
        if status == READY:
            return target
        if status in FAILED:
            reasons = "; ".join(target.get("statusReasons", []))
            raise RuntimeError(f"AgentCore target entered {status}: {reasons}")
        time.sleep(4)
    raise TimeoutError("AgentCore target did not become READY within 10 minutes")


def _delete(client, gateway_id, target_id):
    try:
        client.delete_gateway_target(
            gatewayIdentifier=gateway_id,
            targetId=target_id,
        )
    except ClientError as error:
        if error.response["Error"]["Code"] != NOT_FOUND:
            raise
        return

    for _ in range(150):
        try:
            _get(client, gateway_id, target_id)
        except ClientError as error:
            if error.response["Error"]["Code"] == NOT_FOUND:
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
            f"AgentCore returned connector {actual!r}; expected pinned connector {expected!r}"
        )


def _create(client, properties):
    response = client.create_gateway_target(
        gatewayIdentifier=properties["GatewayIdentifier"],
        **_request(properties),
    )
    target = _wait_ready(
        client,
        properties["GatewayIdentifier"],
        response["targetId"],
    )
    _assert_pinned(target, properties)
    return target


def _update(client, target_id, properties):
    response = client.update_gateway_target(
        gatewayIdentifier=properties["GatewayIdentifier"],
        targetId=target_id,
        **_request(properties),
    )
    target = _wait_ready(
        client,
        properties["GatewayIdentifier"],
        response["targetId"],
    )
    _assert_pinned(target, properties)
    return target


def handler(event, context):
    properties = event["ResourceProperties"]
    old_properties = event.get("OldResourceProperties", {})
    target_id = event.get("PhysicalResourceId")
    client = boto3.client(
        "bedrock-agentcore-control",
        region_name=properties["Region"],
    )

    try:
        if event["RequestType"] == "Delete":
            if target_id:
                _delete(client, properties["GatewayIdentifier"], target_id)
            cfnresponse.send(event, context, cfnresponse.SUCCESS, {}, target_id)
            return

        gateway_changed = (
            event["RequestType"] == "Update"
            and old_properties.get("GatewayIdentifier")
            != properties["GatewayIdentifier"]
        )
        if event["RequestType"] == "Create" or gateway_changed:
            target = _create(client, properties)
            if gateway_changed and target_id:
                _delete(client, old_properties["GatewayIdentifier"], target_id)
        else:
            target = _update(client, target_id, properties)

        data = {
            "TargetId": target["targetId"],
            "GatewayArn": target["gatewayArn"],
        }
        cfnresponse.send(
            event,
            context,
            cfnresponse.SUCCESS,
            data,
            target["targetId"],
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
