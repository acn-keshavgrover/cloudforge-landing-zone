# ──────────────────────────────────────────────
# Security Module - CloudTrail, Config, GuardDuty, Logging
# ──────────────────────────────────────────────

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ──── Centralized Logging Bucket ────

resource "aws_s3_bucket" "logs" {
  bucket = "cloudforge-logs-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name = "cloudforge-logs-${var.environment}"
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "archive-old-logs"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 365
      storage_class = "GLACIER"
    }
    expiration {
      days = 730
    }
  }
}

# ──── CloudTrail ────

resource "aws_cloudtrail" "main" {
  count = var.enable_cloudtrail ? 1 : 0

  name                       = "cloudforge-trail-${var.environment}"
  s3_bucket_name             = aws_s3_bucket.logs.id
  s3_key_prefix              = "cloudtrail"
  include_global_service_events = true
  is_multi_region_trail      = true
  enable_log_file_validation = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cw[0].arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = {
    Name = "cloudforge-trail-${var.environment}"
  }

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  count             = var.enable_cloudtrail ? 1 : 0
  name              = "/cloudforge/cloudtrail/${var.environment}"
  retention_in_days = var.log_retention_days
}

resource "aws_iam_role" "cloudtrail_cw" {
  count = var.enable_cloudtrail ? 1 : 0
  name  = "cloudforge-cloudtrail-cw-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cw" {
  count = var.enable_cloudtrail ? 1 : 0
  name  = "cloudtrail-cloudwatch-policy"
  role  = aws_iam_role.cloudtrail_cw[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Effect   = "Allow"
      Resource = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
    }]
  })
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/cloudtrail/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

# ──── GuardDuty ────

resource "aws_guardduty_detector" "main" {
  count  = var.enable_guardduty ? 1 : 0
  enable = true

  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

# ──── AWS Config ────

resource "aws_config_configuration_recorder" "main" {
  count = var.enable_config ? 1 : 0
  name  = "cloudforge-config-${var.environment}"

  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  count          = var.enable_config ? 1 : 0
  name           = "cloudforge-config-channel-${var.environment}"
  s3_bucket_name = aws_s3_bucket.logs.id
  s3_key_prefix  = "config"

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  count      = var.enable_config ? 1 : 0
  name       = aws_config_configuration_recorder.main[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

resource "aws_iam_role" "config" {
  count = var.enable_config ? 1 : 0
  name  = "cloudforge-config-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "config.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config" {
  count      = var.enable_config ? 1 : 0
  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# ──── CloudWatch Alarms (Security) ────

resource "aws_cloudwatch_metric_alarm" "root_login" {
  count               = var.alarm_sns_topic_arn != "" ? 1 : 0
  alarm_name          = "cloudforge-root-login-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "RootAccountUsage"
  namespace           = "CloudForge/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alert: Root account login detected"
  alarm_actions       = [var.alarm_sns_topic_arn]
}

resource "aws_cloudwatch_metric_alarm" "unauthorized_api" {
  count               = var.alarm_sns_topic_arn != "" ? 1 : 0
  alarm_name          = "cloudforge-unauthorized-api-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "UnauthorizedAPICalls"
  namespace           = "CloudForge/Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alert: Multiple unauthorized API calls detected"
  alarm_actions       = [var.alarm_sns_topic_arn]
}
