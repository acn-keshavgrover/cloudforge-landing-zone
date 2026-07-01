# ──────────────────────────────────────────────
# IAM Module - Guardrails, roles, password policy
# ──────────────────────────────────────────────

# ──── Password Policy ────

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = var.password_policy.minimum_length
  require_lowercase_characters   = var.password_policy.require_lowercase
  require_uppercase_characters   = var.password_policy.require_uppercase
  require_numbers                = var.password_policy.require_numbers
  require_symbols                = var.password_policy.require_symbols
  max_password_age               = var.password_policy.max_age_days
  password_reuse_prevention      = var.password_policy.password_reuse_count
  allow_users_to_change_password = true
}

# ──── MFA Enforcement Policy ────

data "aws_iam_policy_document" "mfa_enforcement" {
  count = var.enable_mfa_enforcement ? 1 : 0

  statement {
    sid    = "AllowViewAccountInfo"
    effect = "Allow"
    actions = [
      "iam:GetAccountPasswordPolicy",
      "iam:ListVirtualMFADevices",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowManageOwnMFA"
    effect = "Allow"
    actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:ResyncMFADevice",
      "iam:ListMFADevices",
    ]
    resources = [
      "arn:aws:iam::*:mfa/$${aws:username}",
      "arn:aws:iam::*:user/$${aws:username}",
    ]
  }

  statement {
    sid    = "DenyAllExceptListedIfNoMFA"
    effect = "Deny"
    not_actions = [
      "iam:CreateVirtualMFADevice",
      "iam:EnableMFADevice",
      "iam:GetUser",
      "iam:ListMFADevices",
      "iam:ListVirtualMFADevices",
      "iam:ResyncMFADevice",
      "sts:GetSessionToken",
    ]
    resources = ["*"]
    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["false"]
    }
  }
}

resource "aws_iam_policy" "mfa_enforcement" {
  count  = var.enable_mfa_enforcement ? 1 : 0
  name   = "enforce-mfa-${var.environment}"
  policy = data.aws_iam_policy_document.mfa_enforcement[0].json
}

# ──── Cross-Account Admin Role ────

data "aws_iam_policy_document" "admin_assume_role" {
  count = length(var.admin_role_trusted_accounts) > 0 ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [for acct in var.admin_role_trusted_accounts : "arn:aws:iam::${acct}:root"]
    }
    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role" "admin" {
  count                = length(var.admin_role_trusted_accounts) > 0 ? 1 : 0
  name                 = "role-admin-${var.environment}"
  assume_role_policy   = data.aws_iam_policy_document.admin_assume_role[0].json
  max_session_duration = var.max_session_duration

  tags = {
    Name = "role-admin-${var.environment}"
  }
}

resource "aws_iam_role_policy_attachment" "admin" {
  count      = length(var.admin_role_trusted_accounts) > 0 ? 1 : 0
  role       = aws_iam_role.admin[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ──── Read-Only Role ────

data "aws_iam_policy_document" "readonly_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "readonly" {
  name                 = "role-readonly-${var.environment}"
  assume_role_policy   = data.aws_iam_policy_document.readonly_assume_role.json
  max_session_duration = var.max_session_duration
}

resource "aws_iam_role_policy_attachment" "readonly" {
  role       = aws_iam_role.readonly.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# ──── CI/CD Deployment Role ────

data "aws_iam_policy_document" "deploy_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com", "codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "deploy" {
  name                 = "role-deploy-${var.environment}"
  assume_role_policy   = data.aws_iam_policy_document.deploy_assume_role.json
  max_session_duration = var.max_session_duration
}

resource "aws_iam_role_policy_attachment" "deploy_ecr" {
  role       = aws_iam_role.deploy.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "deploy_ecs" {
  role       = aws_iam_role.deploy.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}

resource "aws_iam_role_policy_attachment" "deploy_s3" {
  role       = aws_iam_role.deploy.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
