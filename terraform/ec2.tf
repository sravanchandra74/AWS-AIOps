resource "aws_instance" "ec2_instance" {
  ami           = "ami-0274f4b62b6ae3bd5"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.subnet_4.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  key_name = aws_key_pair.generated_key.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  # Use template_file
  user_data = data.template_file.cloudwatch_agent_config.rendered #  Use the data source

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2"
  }
  depends_on = [aws_iam_instance_profile.ec2_instance_profile, aws_security_group.ec2_sg]
}

#  Add this data source
data "template_file" "cloudwatch_agent_config" {
  template = file("${path.module}/cloudwatch-agent-config.json") #  Path to your config
  vars = {
    log_group_name = "/aws/ec2/${var.project_name}-${var.environment}-ec2" # Corrected
    region         = var.region
  }
}