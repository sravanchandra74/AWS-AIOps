import json
import boto3
import base64
from datetime import datetime
import os

s3 = boto3.client('s3')
S3_BUCKET = os.environ['S3_BUCKET']

def decode_kinesis_record(record):
    """Decode and parse a Kinesis data record."""
    try:
        # Decode the base64-encoded data
        data = base64.b64decode(record['kinesis']['data']).decode('utf-8')
        # Parse the JSON data.  CloudWatch Logs sends JSON.
        log_event = json.loads(data)
        return log_event
    except Exception as e:
        print(f"Error decoding Kinesis record: {e}")
        return None

def append_logs_to_s3(log_events, log_type):
    """
    Append log events to a single file in S3.

    Args:
        log_events: A list of log events to append.
        log_type:  The type of log (e.g., 'ec2', 'eks', 'vpc').
    """
    s3_key = f"logs/{log_type}.log"
    try:
        # 1. Read existing data from S3 (if the file exists)
        existing_data = ""
        try:
            response = s3.get_object(Bucket=S3_BUCKET, Key=s3_key)
            existing_data = response['Body'].read().decode('utf-8')
        except s3.exceptions.NoSuchKey:
            print(f"File {s3_key} not found. Creating a new file.")
            existing_data = ""

        # 2.  Split existing data into lines, and create a set of existing log entries
        existing_lines = existing_data.strip().splitlines()
        existing_log_set = set(existing_lines)
        
        # 3.  Convert new log events to lines, and filter out duplicates
        new_log_lines = []
        for event in log_events:
            timestamp = datetime.fromtimestamp(event['timestamp'] / 1000).strftime('%Y-%m-%d %H:%M:%S')
            message = event['message'].replace('\n', '\\n') #  Escape newlines
            log_line = f"{timestamp} {event['logStreamName']} {message}"  # simplified log format
            if log_line not in existing_log_set:
                new_log_lines.append(log_line)

        # 4. Combine existing and new data
        combined_data = existing_data + "\n".join(new_log_lines) + "\n"

        # 5. Write the combined data back to S3
        s3.put_object(Bucket=S3_BUCKET, Key=s3_key, Body=combined_data.encode('utf-8'))
        print(f"Successfully appended {len(new_log_lines)} new log events to {s3_key}")

    except Exception as e:
        print(f"Error appending logs to S3: {e}")
        raise

def lambda_handler(event, context):
    """
    Lambda function handler.  This function is triggered by Kinesis.
    """
    log_events_ec2 = []
    log_events_eks = []
    log_events_vpc = []

    for record in event['Records']:
        log_event = decode_kinesis_record(record)
        if log_event:
            # Determine the log type and add to the appropriate list.
            if "/aws/ec2/" in log_event['logStreamName']:  #  Check the logStreamName
                log_events_ec2.append(log_event)
            elif "/aws/eks/" in log_event['logStreamName']:
                log_events_eks.append(log_event)
            elif "/aws/vpc/" in log_event['logStreamName']:
                log_events_vpc.append(log_event)

    # Append the logs for each source.
    if log_events_ec2:
        append_logs_to_s3(log_events_ec2, 'ec2')
    if log_events_eks:
        append_logs_to_s3(log_events_eks, 'eks')
    if log_events_vpc:
        append_logs_to_s3(log_events_vpc, 'vpc')

    return {
        'statusCode': 200,
        'body': json.dumps('Logs processed successfully')
    }
