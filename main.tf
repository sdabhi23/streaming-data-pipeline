provider "aws" {
  region = "ap-south-1"
}


# IAM User for Kinesis Access
resource "aws_iam_user" "kinesis_user" {
  name = "stream-user"
}

# IAM Role for Kinesis Access
resource "aws_iam_role" "kinesis_role" {
  name               = "kinesis_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "kinesis.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach policy to allow read/write access to Kinesis streams
resource "aws_iam_role_policy_attachment" "kinesis_policy_attachment" {
  role       = aws_iam_role.kinesis_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFullAccess"
}

# Kinesis Data Stream
resource "aws_kinesis_stream" "apps_for_bharat_stream" {
  name        = "AppsForBharat"
  shard_count = 4
  shard_level_metrics = [
    "IncomingBytes",
    "IncomingRecords",
    "IteratorAgeMilliseconds",
    "OutgoingBytes",
    "OutgoingRecords",
    "ReadProvisionedThroughputExceeded",
    "WriteProvisionedThroughputExceeded",
  ]
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "Service" : "lambda.amazonaws.com"
      },
      "Action" : "sts:AssumeRole"
    }]
  })
}

# Attach policy to allow Lambda to write logs to CloudWatch
resource "aws_iam_policy_attachment" "lambda_cloudwatch_logs" {
  name       = "lambda_cloudwatch_logs"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"
  source_dir  = "kinesis-consumer"
}

# Lambda Function
resource "aws_lambda_function" "kinesis_consumer_lambda" {
  function_name    = "kinesis-consumer-lambda"
  filename         = "lambda.zip"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"

  environment {
    variables = {
      STREAM_NAME = aws_kinesis_stream.apps_for_bharat_stream.name
    }
  }
}

# Permission for Lambda to read from Kinesis stream
resource "aws_lambda_permission" "kinesis_consumer_permission" {
  statement_id  = "AllowExecutionFromKinesis"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.kinesis_consumer_lambda.arn
  principal     = "kinesis.amazonaws.com"

  source_arn = aws_kinesis_stream.apps_for_bharat_stream.arn
}

# Event source mapping between Kinesis stream and Lambda
resource "aws_lambda_event_source_mapping" "kinesis_event_mapping" {
  event_source_arn                   = aws_kinesis_stream.apps_for_bharat_stream.arn
  function_name                      = aws_lambda_function.kinesis_consumer_lambda.arn
  starting_position                  = "TRIM_HORIZON"
  maximum_batching_window_in_seconds = 30
  batch_size                         = 20
}
