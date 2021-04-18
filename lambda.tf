data "archive_file" "lambda_zip_dir" {
  type        = "zip"
  output_path = "/tmp/lambda_zip_dir.zip"
  source_dir  = "s3-lifecycle-writer"
}

resource "aws_lambda_function" "s3_lifecycle_writer" {
  filename         = data.archive_file.lambda_zip_dir.output_path
  source_code_hash = data.archive_file.lambda_zip_dir.output_base64sha256
  function_name    = "s3-lifecycle-writer"
  role             = "arn:aws:iam::492141138759:role/service-role/s3-lifecycle-rewriter-role-gf0j38fc"
  handler          = "index.handler"

  runtime = "nodejs14.x"

  depends_on = [
    aws_cloudwatch_log_group.example,
  ]

}

resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/s3-lifecycle-writer"
  retention_in_days = 14
}

resource "aws_s3_bucket" "bucket" {
  bucket = "s3-lambda-bucket-test-349fjfj"

  lifecycle_rule {
    id     = "30DayExpiry"
    prefix = "unsafe/"
    tags = {
      "Expire" = "true"
    }
    expiration {
      days = 30
    }
    enabled = true
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.s3_lifecycle_writer.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "unsafe/"

  }
  depends_on = [aws_lambda_permission.allow_bucket]

}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.s3_lifecycle_writer.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}
