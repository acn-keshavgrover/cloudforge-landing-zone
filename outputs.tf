# ──────────────────────────────────────────────
# VPC Outputs
# ──────────────────────────────────────────────

output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ips" {
  description = "Elastic IPs of NAT Gateways"
  value       = module.vpc.nat_gateway_ips
}

# ──────────────────────────────────────────────
# IAM Outputs
# ──────────────────────────────────────────────

output "admin_role_arn" {
  description = "ARN of the admin cross-account role"
  value       = module.iam.admin_role_arn
}

output "readonly_role_arn" {
  description = "ARN of the read-only role"
  value       = module.iam.readonly_role_arn
}

output "deploy_role_arn" {
  description = "ARN of the CI/CD deployment role"
  value       = module.iam.deploy_role_arn
}

# ──────────────────────────────────────────────
# Security Outputs
# ──────────────────────────────────────────────

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = module.security.cloudtrail_arn
}

output "config_recorder_id" {
  description = "ID of the AWS Config recorder"
  value       = module.security.config_recorder_id
}

output "log_bucket_arn" {
  description = "ARN of the centralized logging S3 bucket"
  value       = module.security.log_bucket_arn
}
