resource "aws_kinesis_stream" "log_stream" {
  name             = "${var.project_name}-${var.environment}-log-stream"
  shard_count      = 1
  retention_period = 24
}

resource "aws_kinesis_firehose_delivery_stream" "log_firehose" {
  name        = "${var.project_name}-${var.environment}-log-firehose"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.kinesis_firehose_role.arn
    bucket_arn = aws_s3_bucket.log_data_bucket.arn
    prefix     = "logs/ec2/${formatdate("YYYY/MM/DD/HH", timestamp())}/"
    error_output_prefix = "errors/ec2/"
    buffering_interval = 1800

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          open_x_json_ser_de {}
        }
      }
      output_format_configuration {
        serializer {
          orc_ser_de {
            compression = "GZIP"
          }
        }
      }
      schema_configuration {
        role_arn = aws_iam_role.glue_role.arn
        database_name = "default"
        table_name = "logs"
      }
      enabled = true
    }
  }
}