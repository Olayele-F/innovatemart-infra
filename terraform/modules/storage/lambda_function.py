import json
import logging
import urllib.parse

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    """
    Triggered by S3 ObjectCreated events.
    Logs the filename of every uploaded object.
    """
    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = urllib.parse.unquote_plus(
            record["s3"]["object"]["key"], encoding="utf-8"
        )
        logger.info("Image received: %s (bucket: %s)", key, bucket)
        print(f"Image received: {key}")

    return {
        "statusCode": 200,
        "body": json.dumps("Processing complete")
    }
