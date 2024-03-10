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
  name        = var.kinesis_stream_name
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
