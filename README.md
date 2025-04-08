<<<<<<< HEAD
# AWS-AIOps  
**AI-Driven Cloud Monitoring & Automation**  

## Architecture  
![AWS-AIOps Architecture](https://github.com/user-attachments/assets/cca3f439-38e6-4f88-94b8-fd6ded846756)  

## Explanation of Components  

### Infrastructure  
- **IaC (Terraform)**: Provisions VPC, EKS cluster, EC2 instances and other AWS Services from the Architecture
- **AWS VPC**: Virtual network containing resources  
- **EKS Cluster**: Amazon Elastic Kubernetes Service for containerized applications  
- **EC2 Instances**: Compute resources for applications/services  

### Monitoring & Data Pipeline  
- **CloudWatch**: Collects logs/metrics from EKS and EC2  
- **Kinesis Firehose**: Streams logs to S3  
- **S3 Bucket (Raw Data)**: Stores raw logs and metrics  

### AI/ML Components  
- **Data Preprocessing**: Prepares data for training  
- **SageMaker (Model Training)**: Trains ML models  
- **SageMaker (Model Endpoint)**: Hosts models for real-time inference  
- **Anomaly Detection**: Identifies anomalies using model predictions  

### Alerting & Remediation  
- **Lambda Functions**: Executes automated remediation  
- **Amazon SNS**: Sends notifications  
- **Slack/MS Teams**: Alert destinations  

## Data Flow  
1. IaC provisions infrastructure (VPC, EKS, EC2)  
2. EKS/EC2, VPC Flow logs ... generate logs → CloudWatch  
3. CloudWatch → Kinesis Firehose → S3 (Raw Data)  
4. MLOps pipeline:  
   - Processes S3 data  
   - Trains models in SageMaker Notebook 
   - Deploys to SageMaker endpoint  
5. Anomaly detection triggers:  
   - Lambda remediation  
   - SNS → Slack/MS Teams alerts  

## Project Structure  

### Terraform Modules  
This folder contains all Terraform configuration files for provisioning AWS infrastructure. Each file is modularized based on the AWS service it manages.

terraform/

- **s3.tf**: Defines S3 buckets for data storage, model artifacts, and logs.
- **iam.tf**: Defines IAM roles, policies, and permissions for SageMaker, Lambda, Step Functions, etc.
- **kinesis.tf**: Defines Kinesis streams for live data ingestion.
- **sagemaker.tf**: Defines SageMaker resources (e.g., models, endpoints, training jobs).
- **stepfunctions.tf**: Defines Step Functions state machines for orchestrating workflows.
- **eks.tf**: Defines EKS clusters for Kubernetes-based workloads.
- **eksng.tf**: Defines EKS node groups for worker nodes.
- **ec2.tf**: Defines EC2 instances for additional compute resources.
- **cloudwatch.tf**: Defines CloudWatch alarms, logs, and dashboards for monitoring.
- **network.tf**: Defines networking resources (VPC, subnets, security groups, IGW, route tables).
- **provider.tf**: Defines the cloud provider (AWS) and required configurations.
- **output.tf**: Captures and displays outputs such as S3 bucket names, SageMaker endpoints, and Kinesis stream ARNs.
- **variables.tf**: Stores variables for reusability (e.g., region, instance types, bucket names).

### In-progress:
- [ ] Fetch application logs from AWS services (VPC Flow Logs, EKS, EC2, etc.)  
- [ ] Push timestamped logs to S3  
- [ ] Add Python scripts for:  
  - Model training (from S3 logs)  
  - Apply Predictive analysis  
  - Automated remediation
=======
# AI-Driven Log Anomaly Detection and Remediation on AWS

## Architecture  
![AWS-AIOps Architecture](https://github.com/user-attachments/assets/cca3f439-38e6-4f88-94b8-fd6ded846756)

## Project Goal

The primary goal of this project is to implement an intelligent log monitoring system on AWS that can:

* **Detect anomalies** in log data from various AWS services (EC2, EKS, etc.) in near real-time.
* **Store logs efficiently** in S3 for analysis and long-term retention.
* **Remediate detected anomalies** automatically, reducing the need for manual intervention.
* **Provide a unified platform** for log management and analysis.

## Core Components

1.  **Log Collection and Storage**
    * CloudWatch: Collects logs from various AWS services.
    * Kinesis Firehose: Efficiently streams logs to S3.
    * S3: Stores logs in a centralized data lake.
    * Lambda (log_appender): Processes and appends logs from Kinesis to S3.

2.  **Anomaly Detection**
    * Machine Learning (Isolation Forest): Detects anomalies in log patterns.
    * Lambda: Runs anomaly detection code.

3.  **Anomaly Remediation**
    * Step Functions: Orchestrates the anomaly remediation workflow.
    * Lambda: Executes remediation actions.

## File Structure and Updates

### 1. `log_appender.py`

* **Location**: `log_appender.py`
* **Description**: This Lambda function processes log data received from Kinesis and appends it to files in S3.
* **Key Updates**:
    * Decodes and parses Kinesis data records (CloudWatch Logs format).
    * Appends log events to corresponding log files in S3 (ec2.log, eks.log, vpc.log).
    * Handles existing log files in S3 by reading, appending, and writing back.
    * Filters out duplicate log entries to prevent data redundancy.
    * Improves log message formatting and handles newlines.
    * Categorizes logs based on source (`ec2`, `eks`, `vpc`) using information from the `logStreamName`.

### 2. `model.py`

* **Location:** `model.py`
* **Description:** This script fetches and processes logs from S3, detects anomalies, and manages the anomaly detection model.
* **Key Updates:**
    * Combines log processing and anomaly detection functionalities.
    * Refactored to read logs from multiple sources (`logs/ec2.log`, `logs/eks.log`, and `logs/vpc-flow.log`).
    * Added retry mechanism with exponential backoff for S3 operations.
    * Improved error handling and logging.
    * Handles empty DataFrames gracefully.
    * Modularized functions for better readability.
    * Added a function to load pre-trained models.
    * Incorporates TF-IDF for feature extraction.

### 3. `cloudwatch.tf`

* **Location**: `cloudwatch.tf`
* **Description**: This file configures CloudWatch resources for log management.
* **Key Updates**:
    * Configured Log Groups for EKS, EC2, and VPC Flow Logs.
    * Implemented CloudWatch Logs Subscription Filters to send logs to Kinesis.

### 4. `ec2.tf`

* **Location**: `ec2.tf`
* **Description**: This file defines the EC2 instance.
* **Key Updates**:
    * Uses the `template_file` data source to inject the CloudWatch agent configuration.

### 5. `ecr.tf`

* **Location**: `ecr.tf`
* **Description**: This file defines the ECR repositories for storing Docker images.
* **Key Updates**:
    * Creates ECR repositories for Lambda and SageMaker.
    * Enables image scanning on push.

### 6. `eks.tf`

* **Location**: `eks.tf`
* **Description**: This file configures the EKS cluster and node group.
* **Key Updates**:
    * Configures an EKS cluster and node group.
    * Uses the `aws_eks_addon` resource to enable EKS logging.

### 7. `iam.tf`

* **Location**: `iam.tf`
* **Description**: This file defines the IAM roles and policies required for various AWS services.
* **Key Updates**:
    * Defined IAM roles for EC2, VPC Flow Logs, Lambda, SageMaker, Kinesis, and Step Functions.
    * Implemented the principle of least privilege.

### 8. `kinesis.tf`

* **Location**: `kinesis.tf`
* **Description**: This file configures the Kinesis stream.
* **Key Updates**:
    * Configures Kinesis stream for log ingestion.

### 9. `lambda.tf`

* **Location**: `lambda.tf`
* **Description**: This file defines the Lambda functions for anomaly detection, remediation, and log processing.
* **Key Updates**:
    * Configures Lambda functions.
    * Configures Kinesis event source mapping to trigger `log_appender_lambda`.

### 10. `main.tf`

* **Location**: `main.tf`
* **Description**: This file configures the AWS provider.

### 11. `network.tf`

* **Location**: `network.tf`
* **Description**: This file defines the network infrastructure, including VPC, subnets, and security groups.
* **Key Updates**:
    * Configures VPC, subnets, internet gateway, and route tables.
    * Creates security groups for EKS and EC2.

### 12. `providers.tf`

* **Location**: `providers.tf`
* **Description**: This file specifies the required Terraform provider.

### 13. `s3.tf`

* **Location**: `s3.tf`
* **Description**: This file configures the S3 bucket for storing log data.
* **Key Updates**:
    * Configures S3 bucket with versioning, encryption, and restricted public access.

### 14. `sagemaker.tf`

* **Location**: `sagemaker.tf`
* **Description**: This file configures the SageMaker notebook instance.
* **Key Updates**:
    * Configures a SageMaker notebook instance with a lifecycle configuration.

### 15. `stepfunction.tf`

* **Location**: `stepfunction.tf`
* **Description**: This file defines the Step Functions state machine for anomaly remediation.
* **Key Updates**:
    * Configures a Step Functions state machine for anomaly remediation.

### 16. `variables.tf`

* **Location**: `variables.tf`
* **Description**: This file defines the variables used in the Terraform configuration.

## Contribution

* Shravan Chandra Parikipandla
>>>>>>> c3a2fd3 (updated the Readme.md file)
