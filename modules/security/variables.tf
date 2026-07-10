variable "environment" { type = string }
variable "vpc_id" { type = string }
variable "enable_guardduty" { type = bool }
variable "enable_config" { type = bool }
variable "enable_cloudtrail" { type = bool }
variable "alarm_sns_topic_arn" { type = string }
variable "log_retention_days" { type = number }
