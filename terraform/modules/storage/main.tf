data "aws_region" "current" {}

# ── S3 Assets Bucket ──────────────────────────────────────────────────────────
resource "aws_s3_bucket" "assets" {
  bucket = "bedrock-assets-${var.student_id}"

  tags = {
    Name    = "bedrock-assets-${var.student_id}"
    Project = "karatu-2025-capstone"
  }
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ── Lambda IAM Role ────────────────────────────────────────────────────────────
resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = { Project = "karatu-2025-capstone" }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_s3" {
  name = "${var.project_name}-lambda-s3"
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "${aws_s3_bucket.assets.arn}/*"
      }
    ]
  })
}

# ── Lambda Function ────────────────────────────────────────────────────────────
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "asset_processor" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "bedrock-asset-processor"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda.output_base64sha256

  tags = {
    Name    = "bedrock-asset-processor"
    Project = "karatu-2025-capstone"
  }
}

# ── Lambda CloudWatch Log Group ────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/bedrock-asset-processor"
  retention_in_days = 14
  tags              = { Project = "karatu-2025-capstone" }
}

# ── S3 → Lambda Trigger ────────────────────────────────────────────────────────
resource "aws_lambda_permission" "s3_trigger" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.asset_processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.assets.arn
}

resource "aws_s3_bucket_notification" "asset_upload" {
  bucket = aws_s3_bucket.assets.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.asset_processor.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3_trigger]
}
