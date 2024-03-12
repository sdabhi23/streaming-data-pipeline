import json
import time
import boto3
import random
import datetime
from faker import Faker

# Initialize the Kinesis client
kinesis_client = boto3.client('kinesis')  # Assuming LocalStack is running on default port

# Define the name of the Kinesis stream
stream_name = 'AppsForBharat'

# Initialize Faker
fake = Faker()

# Define a function to put records into the Kinesis stream
def put_record_into_kinesis(data: dict, key: str):
    try:
        data_string = json.dumps(data)

        probability = round(random.random() * 100)

        if probability < 15:
            random_length = round(random.random() * len(data_string))
            data_string = data_string[:random_length]

        response = kinesis_client.put_record(
            StreamName=stream_name,
            Data=data_string,
            PartitionKey=key,
        )
        print("Record put successfully:", response)
    except Exception as e:
        print("Error putting record:", e)

# main function to continuously put records into the Kinesis stream
def main():
    try:
        while True:
            now = round(datetime.datetime.now().replace(second=0, microsecond=0).timestamp())
            event_template = {
                "event": {
                    "property": {
                        "call_id": fake.uuid4(),
                        "call_duration": str(fake.random_number(digits=2)),
                        "call_status": fake.random_element(elements=('completed', 'in-progress', 'failed'))
                    },
                    "super_property": {
                        "source": "mandir",
                        "type": "purchase",
                        "producer": "user",
                        "name": "astrology_session_purchase",
                        "timestamp": str(now)
                    }
                },
                "user": {
                    "user_id": str(fake.random_number(digits=3)),
                    "state": {
                        "coins": str(fake.random_number(digits=3)),
                        "is_logged_in": fake.boolean(),
                        "language": fake.language_code(),
                        "language_mode": fake.language_code(),
                        "country_code": fake.country_code(representation="alpha-2"),
                        "tz": fake.timezone()
                    },
                    "device_segment": str(fake.random_number(digits=2))
                },
                "platform": {
                    "version": {
                        "integer": "226",
                        "string": "7.1.0"
                    },
                    "code": "com.mandir",
                    "type": fake.random_element(elements=('iOS', 'Android'))
                },
                "geo_location": None,
                "device": {
                    "a_id": fake.uuid4(),
                    "state": {
                        "is_background": fake.boolean(),
                        "is_online": fake.boolean(),
                        "is_playing_music": fake.boolean()
                    },
                    "hardware": {
                        "model_name": fake.word(),
                        "brand_name": fake.company(),
                        "type": fake.random_element(elements=("Mobile", "Web", "PWA"))
                    },
                    "software": {
                        "mobile": {
                            "version": fake.random_number(digits=2),
                            "name": fake.word()
                        },
                        "web": None
                    },
                    "ip": {
                        "ipv4": fake.ipv4(),
                        "ipv6": fake.ipv6()
                    },
                    "system_language": fake.language_name(),
                    "system_id": fake.uuid4()
                },
                "session": {
                    "number": str(fake.random_number(digits=1)),
                    "id": fake.uuid4()
                },
                "referral": {
                    "user_id": str(fake.random_number(digits=3)),
                    "user_code": fake.uuid4()
                }
            }

            print(event_template)

            # put the data into the stream
            put_record_into_kinesis(event_template, str(now))

            # put 1 event per second
            time.sleep(1)
    except KeyboardInterrupt:
        print("Exiting...")

if __name__ == '__main__':
    main()
