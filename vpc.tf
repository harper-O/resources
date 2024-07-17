# Define a variable to control whether to create a new CloudTrail bucket or use an existing one
variable "create_cloudtrail_bucket" {
  description = "Flag to control whether to create a new CloudTrail bucket or use an existing one"
  type        = bool
  default     = false
}

# Data block to fetch the existing CloudTrail bucket (if available)
data "aws_s3_bucket" "existing_cloudtrail_bucket" {
  count  = var.create_cloudtrail_bucket ? 0 : 1
  bucket = "your-existing-cloudtrail-bucket-name"
}

# Resource block to create a new CloudTrail bucket (if needed)
resource "aws_s3_bucket" "new_cloudtrail_bucket" {
  count  = var.create_cloudtrail_bucket ? 1 : 0
  bucket = "your-new-cloudtrail-bucket-name"
  # Add other bucket configuration options as needed
}

# Resource block to create the VPC Flow Logs
resource "aws_flow_log" "vpc_flow_logs" {
  vpc_id = aws_vpc.your_vpc.id

  log_destination = var.create_cloudtrail_bucket ? aws_s3_bucket.new_cloudtrail_bucket[0].arn : data.aws_s3_bucket.existing_cloudtrail_bucket[0].arn
  # Add other VPC Flow Logs configuration options as needed
}
