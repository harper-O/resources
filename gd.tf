# Enable GuardDuty in your AWS account
resource "aws_guardduty_detector" "main" {
  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }
}

# Create an S3 bucket for GuardDuty findings
resource "aws_s3_bucket" "guardduty_findings" {
  bucket = "your-guardduty-findings-bucket-name"
}

# Enable S3 Protection feature
resource "aws_guardduty_organization_configuration" "s3_protection" {
  detector_id = aws_guardduty_detector.main.id
  auto_enable = true

  datasources {
    s3_logs {
      auto_enable = true
    }
  }
}

# Enable Malware Protection feature
resource "aws_guardduty_organization_configuration_feature" "malware_protection" {
  detector_id = aws_guardduty_detector.main.id
  feature_type = "EBS_MALWARE_PROTECTION"
  auto_enable = "NEW"
}

# Create a GuardDuty publishing destination for S3
resource "aws_guardduty_publishing_destination" "s3_destination" {
  detector_id     = aws_guardduty_detector.main.id
  destination_arn = aws_s3_bucket.guardduty_findings.arn
  destination_type = "S3"

  kms_key_arn     = aws_kms_key.guardduty_key.arn
}

# KMS key for encrypting GuardDuty findings
resource "aws_kms_key" "guardduty_key" {
  description = "KMS key for GuardDuty findings"
  enable_key_rotation = true
}

# S3 bucket policy to allow GuardDuty to write findings
resource "aws_s3_bucket_policy" "guardduty_findings_policy" {
  bucket = aws_s3_bucket.guardduty_findings.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowGuardDutyToPutObjects"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.guardduty_findings.arn}/*"
      }
    ]
  })
}
