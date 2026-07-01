variable "environment" { type = string }
variable "enable_mfa_enforcement" { type = bool }
variable "max_session_duration" { type = number }
variable "password_policy" {
  type = object({
    minimum_length       = number
    require_lowercase    = bool
    require_uppercase    = bool
    require_numbers      = bool
    require_symbols      = bool
    max_age_days         = number
    password_reuse_count = number
  })
}
variable "admin_role_trusted_accounts" { type = list(string) }
