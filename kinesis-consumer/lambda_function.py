import json
import base64


def lambda_handler(event, context):
    for event in event["Records"]:
        print(base64.b64decode(event["kinesis"]["data"]).decode("utf-8"))

    return {"statusCode": 200, "body": json.dumps("Hello from Lambda!")}
