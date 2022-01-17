from kafka import KafkaProducer
from faker import Faker

import random
import time
import json
import sys

fake = Faker()

sensor_ids = []
for i in range(0,10):
    sensor_ids.append(fake.uuid4())

def generate_reading():
    return {
        "sensor_id": sensor_ids[random.randint(0,9)],
        "val": random.randint(80,100)
    }

producer = KafkaProducer(
    bootstrap_servers=sys.argv[1],
    security_protocol="SSL",
    ssl_cafile="creds/ca.pem",
    ssl_certfile="creds/service.cert",
    ssl_keyfile="creds/service.key",
    value_serializer=lambda v: json.dumps(v).encode('utf-8'),
    key_serializer=lambda v: json.dumps(v).encode('utf-8')
)

target = sys.argv[2]
if target not in ["influx","m3"]:
    print("Usage: produce_data.py <kafka-service-uri> [influx|m3]")

while True:
    sensor_reading = generate_reading()
    try:
        FutureRecord = producer.send("sensor-readings-to-" + target, value=sensor_reading)
        producer.flush()
        record_metadata = FutureRecord.get(timeout=10)
        print("sent fake sensor reading to Kafka topic {} partition {} offset {}".format(
            record_metadata.topic, record_metadata.partition, record_metadata.offset))
    except Exception as e:
        print(e)
    time.sleep(1)