resource "aws_kinesis_firehose_delivery_stream" "firehose_processing_stream" {
  name        = "kinesis-firehose-processor-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn       = aws_iam_role.firehose_role.arn
    bucket_arn     = aws_s3_bucket.output_bucket.arn
    file_extension = ".jsonl"

    prefix              = "data/day=!{timestamp:yyyy-MM-dd}/"
    error_output_prefix = "errors/day=!{timestamp:yyyy-MM-dd}/!{firehose:error-output-type}/"

    cloudwatch_logging_options {
      enabled         = "true"
      log_group_name  = aws_cloudwatch_log_group.firehose_log_group.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_log_stream.name
    }

    processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.lambda_processor.arn}:$LATEST"
        }

        parameters {
          parameter_name  = "BufferSizeInMBs"
          parameter_value = "1"
        }

        parameters {
          parameter_name  = "BufferIntervalInSeconds"
          parameter_value = "120"
        }
      }
    }
  }

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.apps_for_bharat_stream.arn
    role_arn           = aws_iam_role.firehose_role.arn
  }

}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "firehose-processor-user"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"
  source_dir  = "../kinesis-consumer"
}

# Attach policy to allow Lambda to write logs to CloudWatch
resource "aws_iam_policy_attachment" "lambda_cloudwatch_logs" {
  name       = "lambda_cloudwatch_logs"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lambda_processor" {
  function_name    = "firehose-lambda-processor"
  role             = aws_iam_role.lambda_role.arn
  filename         = "lambda.zip"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
}

resource "aws_s3_bucket" "output_bucket" {
  bucket = "appsforbharat-assignment-shrey"
}
