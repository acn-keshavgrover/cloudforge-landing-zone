# CloudForge - Terraform Landing Zone
# Reusable multi-account AWS landing zone with modular VPC/IAM guardrails
# Author: Keshav Grover

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = var.state_bucket
    key            = "landing-zone/terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = var.lock_table
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "CloudForge"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "keshav.grover"
    }
  }
}

# --- VPC Module ---
module "vpc" {
  source = "./modules/vpc"

  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway  = var.enable_nat_gateway
  single_nat_gateway  = var.single_nat_gateway
  enable_flow_logs    = var.enable_flow_logs
  flow_log_bucket_arn = module.security.log_bucket_arn
}

# --- IAM Module ---
module "iam" {
  source = "./modules/iam"

  environment              = var.environment
  enable_mfa_enforcement   = var.enable_mfa_enforcement
  max_session_duration     = var.max_session_duration
  password_policy          = var.password_policy
  admin_role_trusted_accounts = var.admin_role_trusted_accounts
}

# --- Security Module ---
module "security" {
  source = "./modules/security"

  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  enable_guardduty   = var.enable_guardduty
  enable_config      = var.enable_config
  enable_cloudtrail  = var.enable_cloudtrail
  alarm_sns_topic_arn = var.alarm_sns_topic_arn
  log_retention_days = var.log_retention_days
}

# --- Networking Module ---
module "networking" {
  source = "./modules/networking"

  environment    = var.environment
  vpc_id         = module.vpc.vpc_id
  vpc_cidr       = var.vpc_cidr
  public_subnets = module.vpc.public_subnet_ids
  private_subnets = module.vpc.private_subnet_ids
  allowed_cidrs  = var.allowed_cidrs
}
