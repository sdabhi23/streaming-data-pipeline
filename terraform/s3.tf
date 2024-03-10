resource "aws_s3_bucket" "output_bucket" {
  bucket = "data-staging-bucket"
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.output_bucket.id
  acl    = "private"
}
