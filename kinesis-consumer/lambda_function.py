import json
import base64
import logging


class FirehoseOutputRecordStatuses:
    OK = "Ok"
    DROPPED = "Dropped"
    PROCESSING_FAILED = "ProcessingFailed"


def lambda_handler(event, context):
    output = []

    for record in event["records"]:
        payload = json.loads(base64.b64decode(record["data"]).decode("utf-8"))
        result = FirehoseOutputRecordStatuses.OK

        try:
            payload["user"]["user_id"] = int(payload["user"]["user_id"])
        except Exception:
            logging.exception("Error parsing 'user.user_id' as an integer")
            # catch any issues and send them off to the error queue / bucket from Firehose
            result = FirehoseOutputRecordStatuses.PROCESSING_FAILED

        try:
            payload["referral"]["user_id"] = int(payload["referral"]["user_id"])
        except Exception:
            logging.exception("Error parsing 'referral.user_id' as an integer")
            # catch any issues and send them off to the error queue / bucket from Firehose
            result = FirehoseOutputRecordStatuses.PROCESSING_FAILED

        output_record = {
            "partitionKey": record["partitionKey"],
            "sequenceNumber": record["sequenceNumber"],
            "approximateArrivalTimestamp": record["approximateArrivalTimestamp"],
            "subSequenceNumber": record["subSequenceNumber"],
            "action": record["action"],
            "kinesisRecordMetadata": record["kinesisRecordMetadata"],
            "result": result,
            "data": base64.b64encode((json.dumps(payload) + "\n").encode("utf-8")).decode("utf-8"),
        }
        output.append(output_record)

    print("Successfully processed {} records.".format(len(event["records"])))

    return {"records": output}
