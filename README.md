# AWS-AIOps
AI-Driven Cloud Monitoring &amp; Automation
The Architecture of this project:
![image](https://github.com/user-attachments/assets/cca3f439-38e6-4f88-94b8-fd6ded846756)

Explanation of Components:
IaC (Terraform/CloudFormation): Represents your Infrastructure as Code, which provisions the VPC, EKS cluster, and EC2 instances.
AWS VPC: The virtual network that contains your resources.
EKS Cluster: Your Amazon Elastic Kubernetes Service cluster for running containerized applications.
EC2 Instances: Your Amazon EC2 instances for running applications or services.
CloudWatch: Collects logs and metrics from EKS and EC2.
Kinesis Firehose: Streams logs to S3.
S3 Bucket (Raw Data): Stores the raw logs and metrics data.
Data Preprocessing: Prepares the data for model training.
SageMaker (Model Training): Trains the machine learning models for predictive analysis.
SageMaker (Model Endpoint): Deploys the trained models for real-time inference.
Anomaly Detection: Applies the deployed models to detect anomalies in the data.
Lambda Functions: Executes automated remediation actions based on anomaly detection results.
Amazon SNS: Sends notifications to Slack/MS Teams.
Slack/MS Teams: The communication channels for receiving alerts.

Data Flow:
IaC provisions the infrastructure (VPC, EKS, EC2).
EKS and EC2 generate logs and metrics, which are collected by CloudWatch.
CloudWatch streams logs to Kinesis Firehose, which delivers them to S3.
The MLOps pipeline processes the raw data in S3, trains ML models in SageMaker, and deploys them to a SageMaker endpoint.
The SageMaker endpoint generates predictions, which are used for anomaly detection.
If anomalies are detected, Lambda functions trigger remediation actions on EKS and EC2.
Amazon SNS sends alerts to Slack/MS Teams.

Project Structure
Here’s a detailed breakdown of the proposed structure:
terraform/
This folder contains all Terraform configuration files for provisioning AWS infrastructure. Each file is modularized based on the AWS service it manages.
s3.tf: Defines S3 buckets for data storage, model artifacts, and logs.
iam.tf: Defines IAM roles, policies, and permissions for SageMaker, Lambda, Step Functions, etc.
kinesis.tf: Defines Kinesis streams for live data ingestion.
sagemaker.tf: Defines SageMaker resources (e.g., models, endpoints, training jobs).
stepfunctions.tf: Defines Step Functions state machines for orchestrating workflows.
eks.tf: Defines EKS clusters for Kubernetes-based workloads.
eksng.tf: Defines EKS node groups for worker nodes.
ec2.tf: Defines EC2 instances for additional compute resources.
cloudwatch.tf: Defines CloudWatch alarms, logs, and dashboards for monitoring.
network.tf: Defines networking resources (VPC, subnets, security groups, IGW, route tables).
provider.tf → Defines the cloud provider (AWS) and required configurations.
output.tf → Captures and displays outputs such as S3 bucket names, SageMaker endpoints, and Kinesis stream ARNs.
variables.tf → Stores variables for reusability (e.g., region, instance types, bucket names).

In-progress:
Fetch the logs from any applications which is going to install in EC2 Instances, AWS Services (VPC Flow Logs, EKS, EC2 Instances ....) and push to S3 Bucket with timestamps.
Need to add the python script files which runs the model (train the stored logs from S3 bucket, apply predective analysis, remediate on it own)
