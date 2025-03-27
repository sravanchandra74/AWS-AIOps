data "aws_ssm_parameter" "amazon_linux_2_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "ec2_instance" {
  ami           = data.aws_ssm_parameter.amazon_linux_2_ami.value
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet_4.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name = aws_key_pair.generated_key.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install amazon-cloudwatch-agent -y

    # CloudWatch Agent Configuration (Replace with your desired config)
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

    # Example Config - Replace as needed.
    cat <<EOT | sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
    {
      "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "root"
      },
      "metrics": {
        "namespace": "System/Linux",
        "metrics_collected": {
          "cpu": {
            "measurement": [
              "cpu_usage_idle",
              "cpu_usage_iowait",
              "cpu_usage_user",
              "cpu_usage_system"
            ],
            "totalcpu": true
          },
          "disk": {
            "measurement": [
              "used_percent",
              "inodes_free"
            ],
            "resources": [
              "*"
            ]
          },
          "mem": {
            "measurement": [
              "mem_used_percent"
            ]
          },
          "net": {
            "measurement": [
              "bytes_sent",
              "bytes_recv",
              "packets_sent",
              "packets_recv"
            ],
            "resources": [
              "eth0"
            ]
          },
          "diskio": {
            "measurement": [
              "reads",
              "writes"
            ],
            "resources": [
              "*"
            ]
          }
        }
      },
      "logs": {
        "logs_collected": {
          "files": {
            "collect_list": [
              {
                "file_path": "/var/log/messages",
                "log_group_name": "/aws/ec2/ai-mlops-ec2",
                "log_stream_name": "{instance_id}"
              }
            ]
          }
        }
      }
    }
    EOT
    sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
  EOF

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2"
  }
  depends_on = [aws_iam_instance_profile.ec2_instance_profile, aws_security_group.ec2_sg]
}