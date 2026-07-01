output "admin_role_arn" {
  value = length(aws_iam_role.admin) > 0 ? aws_iam_role.admin[0].arn : null
}

output "readonly_role_arn" {
  value = aws_iam_role.readonly.arn
}

output "deploy_role_arn" {
  value = aws_iam_role.deploy.arn
}

output "mfa_policy_arn" {
  value = length(aws_iam_policy.mfa_enforcement) > 0 ? aws_iam_policy.mfa_enforcement[0].arn : null
}
