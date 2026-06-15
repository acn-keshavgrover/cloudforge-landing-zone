# ──────────────────────────────────────────────
# Global Variables
# ──────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-northeast-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "state_bucket" {
  description = "S3 bucket for Terraform remote state"
  type        = string
}

variable "lock_table" {
  description = "DynamoDB table for state locking"
  type        = string
  default     = "terraform-locks"
}

# ──────────────────────────────────────────────
# VPC Variables
# ──────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to use"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c", "ap-northeast-1d"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway (cost savings for non-prod)"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true
}

# ──────────────────────────────────────────────
# IAM Variables
# ──────────────────────────────────────────────

variable "enable_mfa_enforcement" {
  description = "Enforce MFA for all IAM users"
  type        = bool
  default     = true
}

variable "max_session_duration" {
  description = "Maximum session duration for IAM roles (seconds)"
  type        = number
  default     = 3600
}

variable "password_policy" {
  description = "IAM password policy configuration"
  type = object({
    minimum_length        = number
    require_lowercase     = bool
    require_uppercase     = bool
    require_numbers       = bool
    require_symbols       = bool
    max_age_days          = number
    password_reuse_count  = number
  })
  default = {
    minimum_length       = 14
    require_lowercase    = true
    require_uppercase    = true
    require_numbers      = true
    require_symbols      = true
    max_age_days         = 90
    password_reuse_count = 24
  }
}

variable "admin_role_trusted_accounts" {
  description = "AWS account IDs allowed to assume the admin role"
  type        = list(string)
  default     = []
}

# ──────────────────────────────────────────────
# Security Variables
# ──────────────────────────────────────────────

variable "enable_guardduty" {
  description = "Enable AWS GuardDuty"
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "Enable AWS Config"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Enable AWS CloudTrail"
  type        = bool
  default     = true
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarms"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 90
}

# ──────────────────────────────────────────────
# Networking Variables
# ──────────────────────────────────────────────

variable "allowed_cidrs" {
  description = "CIDR blocks allowed for inbound access"
  type        = list(string)
  default     = []
}
