# Enable GuardDuty in the member account
resource "aws_guardduty_detector" "member" {
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

# Enable S3 Protection feature
resource "aws_guardduty_detector_feature" "s3_protection" {
  detector_id = aws_guardduty_detector.member.id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
}

# Enable Malware Protection feature
resource "aws_guardduty_detector_feature" "malware_protection" {
  detector_id = aws_guardduty_detector.member.id
  name        = "EBS_MALWARE_PROTECTION"
  status      = "ENABLED"
}

# Define the S3 buckets to protect
locals {
  protected_buckets = ["jane", "jack", "ellie"]
}

# Enable malware protection for specific S3 buckets
resource "aws_guardduty_filter" "s3_malware_protection" {
  name        = "s3-malware-protection-filter"
  action      = "ARCHIVE"
  detector_id = aws_guardduty_detector.member.id
  rank        = 1

  finding_criteria {
    criterion {
      field  = "resource.resourceType"
      equals = ["S3Bucket"]
    }
    criterion {
      field  = "service.featureName"
      equals = ["MalwareProtection"]
    }
    criterion {
      field  = "resource.resourceName"
      equals = local.protected_buckets
    }
  }
}

# Optional: Create a KMS key for encrypting GuardDuty findings
resource "aws_kms_key" "guardduty_key" {
  description             = "KMS key for GuardDuty findings"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# Optional: Configure GuardDuty to publish findings to an S3 bucket
resource "aws_guardduty_publishing_destination" "s3_destination" {
  detector_id     = aws_guardduty_detector.member.id
  destination_arn = aws_s3_bucket.guardduty_findings.arn
  destination_type = "S3"
  kms_key_arn     = aws_kms_key.guardduty_key.arn
}

# Optional: S3 bucket for GuardDuty findings
resource "aws_s3_bucket" "guardduty_findings" {
  bucket = "your-guardduty-findings-bucket-name"
}

# Optional: S3 bucket policy to allow GuardDuty to write findings
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
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.guardduty_findings.arn}/*"
      }
    ]
  })
}
