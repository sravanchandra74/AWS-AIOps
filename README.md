# AWS-AIOps  
**AI-Driven Cloud Monitoring & Automation**  

## Architecture  
![AWS-AIOps Architecture](https://github.com/user-attachments/assets/cca3f439-38e6-4f88-94b8-fd6ded846756)  

## Explanation of Components  

### Infrastructure  
- **IaC (Terraform/CloudFormation)**: Provisions VPC, EKS cluster, and EC2 instances  
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
2. EKS/EC2 generate logs → CloudWatch  
3. CloudWatch → Kinesis Firehose → S3 (Raw Data)  
4. MLOps pipeline:  
   - Processes S3 data  
   - Trains models in SageMaker  
   - Deploys to SageMaker endpoint  
5. Anomaly detection triggers:  
   - Lambda remediation  
   - SNS → Slack/MS Teams alerts  

## Project Structure  

### Terraform Modules  
This folder contains all Terraform configuration files for provisioning AWS infrastructure. Each file is modularized based on the AWS service it manages.

- terraform/

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
- [ ] Fetch application logs from EC2/AWS services (VPC Flow Logs, EKS, etc.)  
- [ ] Push timestamped logs to S3  
- [ ] Add Python scripts for:  
  - Model training (from S3 logs)  
  - Predictive analysis  
  - Automated remediation 
