import pandas as pd
import sklearn
from sklearn.ensemble import IsolationForest
from sklearn.feature_extraction.text import TfidfVectorizer
import boto3
import io
import logging
import joblib
import os
import time
from datetime import datetime, timedelta

# Configure Logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Configuration
S3_BUCKET = "ai-mlops-staging-log-data-bucket-2"
LOG_SOURCES = ["logs/ec2.log", "logs/eks.log", "logs/vpc-flow.log"] # Changed LOG_SOURCES
ANOMALY_OUTPUT_PREFIX = "anomalies/"
MODEL_OUTPUT_PREFIX = "models/anomaly/"
MODEL_FILENAME = "anomaly_model.joblib"
ANOMALY_FILENAME = "anomaly_results.csv"
TIME_WINDOW_HOURS = 3 # changed time window
CONTAMINATION_RATE = 0.1
RETRY_MAX_ATTEMPTS = 3
RETRY_BACKOFF_SECONDS = 2
LOG_COLUMNS = ["timestamp", "log_stream_name", "message"]  # Changed column names
MODEL_RETRAIN_THRESHOLD_HOURS = 24
TFIDF_MAX_FEATURES = 100


# Initialize S3 client
s3 = boto3.client('s3')

def fetch_logs_from_s3(bucket, log_file, start_time, end_time):
    """Fetch logs from a single file in S3 with retries."""
    data = []
    for attempt in range(RETRY_MAX_ATTEMPTS):
        try:
            obj = s3.get_object(Bucket=bucket, Key=log_file)
            log_content = obj['Body'].read().decode('utf-8')
            # Process log lines
            for line in log_content.splitlines():
                parts = line.split(" ", 2)  # Split into timestamp, log_stream_name, message
                if len(parts) == 3:
                    try:
                        timestamp_str, log_stream_name, message = parts
                        timestamp = datetime.strptime(timestamp_str, '%Y-%m-%d %H:%M:%S')
                        if start_time <= timestamp <= end_time:
                            data.append({
                                "timestamp": timestamp,
                                "log_stream_name": log_stream_name,
                                "message": message
                            })
                    except ValueError:
                        logging.warning(f"Skipping invalid log line: {line}")
                else:
                    logging.warning(f"Skipping malformed log line: {line}")
            break # Exit the retry loop if successful
        except Exception as e:
            logging.warning(f"Error fetching logs from {log_file}, attempt {attempt + 1}/{RETRY_MAX_ATTEMPTS}: {e}")
            if attempt < RETRY_MAX_ATTEMPTS - 1:
                time.sleep(RETRY_BACKOFF_SECONDS * (2 ** attempt))
            else:
                raise  # Re-raise the exception after the final attempt
    return pd.DataFrame(data) if data else pd.DataFrame(columns=LOG_COLUMNS)



def preprocess_logs(df):
    """Preprocess logs:  Convert timestamps and extract TF-IDF features."""
    if df.empty:
        return df
    df['timestamp'] = pd.to_datetime(df['timestamp'])
    tfidf_vectorizer = TfidfVectorizer(max_features=TFIDF_MAX_FEATURES)
    tfidf_features = tfidf_vectorizer.fit_transform(df['message']).toarray()
    tfidf_df = pd.DataFrame(tfidf_features, columns=[f'tfidf_{i}' for i in range(tfidf_features.shape[1])])
    df = pd.concat([df.reset_index(drop=True), tfidf_df], axis=1)
    return df



def train_anomaly_model(df, model=None):
    """Train or update an Isolation Forest model."""
    if df.empty:
        return None
    features = df.drop(columns=['timestamp', 'log_stream_name', 'message'], errors='ignore')
    if model is None:
        model = IsolationForest(contamination=CONTAMINATION_RATE, random_state=42)
    model.fit(features)
    return model



def detect_anomalies(df, model):
    """Detect anomalies using the trained model."""
    if df.empty or model is None:
        return pd.DataFrame(columns=['timestamp', 'log_stream_name', 'message'])
    try:
        features = df.drop(columns=['timestamp', 'log_stream_name', 'message'], errors='ignore')
        df['anomaly'] = model.predict(features)
        df['is_anomaly'] = df['anomaly'].apply(lambda x: "❌ Anomaly" if x == -1 else "✅ Normal")
        return df[df['is_anomaly'] == "❌ Anomaly"].copy()
    except Exception as e:
        logging.error(f"Error during anomaly detection: {e}")
        return pd.DataFrame(columns=['timestamp', 'log_stream_name', 'message'])



def save_to_s3(df, bucket, prefix, filename):
    """Save DataFrame to S3 with retries."""
    if df.empty:
        logging.info("No data to save.")
        return
    for attempt in range(RETRY_MAX_ATTEMPTS):
        try:
            csv_buffer = io.StringIO()
            df.to_csv(csv_buffer, index=False)
            s3.put_object(Bucket=bucket, Key=os.path.join(prefix, filename), Body=csv_buffer.getvalue().encode('utf-8'))
            logging.info(f"Saved {filename} to s3://{bucket}/{prefix}")
            break
        except Exception as e:
            logging.warning(f"Error saving to S3, attempt {attempt + 1}/{RETRY_MAX_ATTEMPTS}: {e}")
            if attempt < RETRY_MAX_ATTEMPTS - 1:
                time.sleep(RETRY_BACKOFF_SECONDS * (2 ** attempt))
            else:
                raise



def save_model_to_s3(model, bucket, prefix):
    """Save trained model to S3 with retries."""
    if model is None:
        logging.info("No model to save.")
        return
    for attempt in range(RETRY_MAX_ATTEMPTS):
        try:
            model_buffer = io.BytesIO()
            joblib.dump(model, model_buffer)
            model_buffer.seek(0)
            s3.put_object(Bucket=bucket, Key=os.path.join(prefix, MODEL_FILENAME), Body=model_buffer.getvalue())
            logging.info(f"Model saved to s3://{bucket}/{prefix}{MODEL_FILENAME}")
            break
        except Exception as e:
            logging.warning(f"Error saving model to S3, attempt {attempt + 1}/{RETRY_MAX_ATTEMPTS}: {e}")
            if attempt < RETRY_MAX_ATTEMPTS - 1:
                time.sleep(RETRY_BACKOFF_SECONDS * (2 ** attempt))
            else:
                raise



def load_model_from_s3(bucket, prefix):
    """Load trained model from S3 with retries."""
    for attempt in range(RETRY_MAX_ATTEMPTS):
        try:
            obj = s3.get_object(Bucket=bucket, Key=os.path.join(prefix, MODEL_FILENAME))
            model_data = io.BytesIO(obj['Body'].read())
            model = joblib.load(model_data)
            logging.info(f"Model loaded from s3://{bucket}/{prefix}{MODEL_FILENAME}")
            return model
        except s3.exceptions.NoSuchKey:
            logging.info("No existing model found, training a new one.")
            return None
        except Exception as e:
            logging.error(f"Error loading model from S3, attempt {attempt + 1}/{RETRY_MAX_ATTEMPTS}: {e}")
            if attempt < RETRY_MAX_ATTEMPTS - 1:
                time.sleep(RETRY_BACKOFF_SECONDS * (2 ** attempt))
            else:
                raise



def should_retrain_model(bucket, prefix, threshold_hours=MODEL_RETRAIN_THRESHOLD_HOURS):
    """Check if the model should be retrained based on time since last training."""
    try:
        obj = s3.get_object(Bucket=bucket, Key=os.path.join(prefix, "last_trained.txt"))
        last_trained_str = obj['Body'].read().decode('utf-8')
        last_trained = datetime.strptime(last_trained_str, "%Y-%m-%d %H:%M:%S")
        return (datetime.utcnow() - last_trained).total_seconds() / 3600 >= threshold_hours
    except s3.exceptions.NoSuchKey:
        logging.info("No last_trained.txt found, retraining model.")
        return True
    except Exception as e:
        logging.error(f"Error checking model retrain: {e}")
        return True



def main():
    """Main workflow for anomaly detection."""
    end_time = datetime.utcnow()
    start_time = end_time - timedelta(hours=TIME_WINDOW_HOURS)
    all_logs = []

    for log_source in LOG_SOURCES:
        logging.info(f"Fetching logs from {log_source}")
        df = fetch_logs_from_s3(S3_BUCKET, log_source, start_time, end_time)
        if not df.empty:
            all_logs.append(df)

    if not all_logs:
        logging.info("No logs found for analysis.")
        return

    df = pd.concat(all_logs, ignore_index=True)
    df = preprocess_logs(df)

    model = load_model_from_s3(S3_BUCKET, MODEL_OUTPUT_PREFIX)
    retrain_model = should_retrain_model(S3_BUCKET, MODEL_OUTPUT_PREFIX)

    if retrain_model:
        logging.info("Retraining the anomaly detection model.")
        model = train_anomaly_model(df)
        save_model_to_s3(model, S3_BUCKET, MODEL_OUTPUT_PREFIX)
        # Save the last trained time
        s3.put_object(
            Bucket=S3_BUCKET,
            Key=os.path.join(MODEL_OUTPUT_PREFIX, "last_trained.txt"),
            Body=datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S").encode('utf-8')
        )
    else:
        logging.info("Using the existing anomaly detection model.")

    anomalies = detect_anomalies(df, model)
    save_to_s3(anomalies, S3_BUCKET, ANOMALY_OUTPUT_PREFIX, ANOMALY_FILENAME)
    logging.info("Anomalies detected and saved.")



if __name__ == "__main__":
    main()

