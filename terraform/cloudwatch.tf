resource "aws_cloudwatch_log_group" "firehose_log_group" {
  name = "/aws/kinesisfirehose/${var.kinesis_stream_name}-delivery"
}

resource "aws_cloudwatch_log_stream" "firehose_log_stream" {
  name           = "/aws/kinesisfirehose/${var.kinesis_stream_name}-stream"
  log_group_name = aws_cloudwatch_log_group.firehose_log_group.name
}
