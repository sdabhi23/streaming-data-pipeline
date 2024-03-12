import json
import base64
import logging
import binascii


class FirehoseOutputRecordStatuses:
    OK = "Ok"
    DROPPED = "Dropped"
    PROCESSING_FAILED = "ProcessingFailed"


def log_error(msg, record_id, kinesis_metadata):
    print(f"Record ID: {record_id}")
    print(f"Shard ID: {kinesis_metadata['shardId']}")
    print(f"Sequence Number: {kinesis_metadata['sequenceNumber']}")
    logging.exception(msg)


def lambda_handler(event, context):
    output = []

    for record in event["records"]:
        result = FirehoseOutputRecordStatuses.OK
        payload = ""

        # catch any issues and send the records to the error queue / bucket from Firehose
        try:
            json_string = base64.b64decode(record["data"]).decode("utf-8")
            payload = json.loads(json_string)

            try:
                payload["user"]["user_id"] = int(payload["user"]["user_id"])
            except Exception:
                log_error(
                    "Error parsing 'user.user_id' as an integer",
                    record["recordId"],
                    record["kinesisRecordMetadata"],
                )
                result = FirehoseOutputRecordStatuses.PROCESSING_FAILED

            try:
                payload["referral"]["user_id"] = int(payload["referral"]["user_id"])
            except Exception:
                log_error(
                    "Error parsing 'referral.user_id' as an integer",
                    record["recordId"],
                    record["kinesisRecordMetadata"],
                )
                result = FirehoseOutputRecordStatuses.PROCESSING_FAILED

            output_data = base64.b64encode(
                (json.dumps(payload) + "\n").encode("utf-8")
            ).decode("utf-8")
        except json.JSONDecodeError:
            log_error(
                "Error decoding JSON string",
                record["recordId"],
                record["kinesisRecordMetadata"],
            )
            result = FirehoseOutputRecordStatuses.PROCESSING_FAILED
            output_data = base64.b64encode((json_string + "\n").encode("utf-8")).decode(
                "utf-8"
            )
        except binascii.Error:
            log_error(
                "Error decoding the record from base64 format",
                record["recordId"],
                record["kinesisRecordMetadata"],
            )
            result = FirehoseOutputRecordStatuses.PROCESSING_FAILED
            output_data = record["data"]

        output_record = {
            "recordId": record["recordId"],
            "result": result,
            "data": output_data,
        }

        output.append(output_record)

    print("Successfully processed {} records.".format(len(event["records"])))

    return {"records": output}
