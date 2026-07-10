output "log_bucket_arn" {
  value = aws_s3_bucket.logs.arn
}

output "cloudtrail_arn" {
  value = var.enable_cloudtrail ? aws_cloudtrail.main[0].arn : null
}

output "config_recorder_id" {
  value = var.enable_config ? aws_config_configuration_recorder.main[0].id : null
}

output "guardduty_detector_id" {
  value = var.enable_guardduty ? aws_guardduty_detector.main[0].id : null
}
