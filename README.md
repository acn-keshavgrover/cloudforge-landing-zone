# CloudForge — Terraform Landing Zone

Reusable, multi-account AWS landing zone with modular VPC/IAM guardrails and CI-driven plan/apply.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AWS Account                          │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │  VPC     │  │  IAM     │  │ Security │              │
│  │  Module  │  │  Module  │  │  Module  │              │
│  │          │  │          │  │          │              │
│  │ • Subnets│  │ • Roles  │  │ • Trail  │              │
│  │ • NAT GW │  │ • MFA    │  │ • Guard  │              │
│  │ • Routes │  │ • Policy │  │ • Config │              │
│  │ • FlowLog│  │ • Deploy │  │ • Alarms │              │
│  └──────────┘  └──────────┘  └──────────┘              │
│                                                         │
│  ┌──────────────────┐                                   │
│  │   Networking     │                                   │
│  │   Module         │                                   │
│  │ • SGs (bastion,  │                                   │
│  │   ALB, app, DB)  │                                   │
│  │ • NACLs          │                                   │
│  └──────────────────┘                                   │
└─────────────────────────────────────────────────────────┘
```

## Modules

| Module | Purpose |
|--------|---------|
| `vpc` | Multi-AZ VPC with public/private subnets, NAT, flow logs |
| `iam` | Password policy, MFA enforcement, cross-account roles, CI/CD deploy role |
| `security` | CloudTrail, GuardDuty, AWS Config, centralized logging, security alarms |
| `networking` | Baseline security groups (bastion, ALB, app, DB), NACLs |

## Quick Start

```bash
# Initialize with environment-specific backend
terraform init -backend-config="envs/dev/backend.hcl"

# Plan
terraform plan -var-file="envs/dev/terraform.tfvars"

# Apply
terraform apply -var-file="envs/dev/terraform.tfvars"
```

## CI/CD

GitHub Actions workflow runs on every PR:
1. `terraform fmt` check
2. `terraform validate`
3. `terraform plan` (per environment)
4. `tfsec` security scan
5. Auto-apply to `dev` on merge to `main`; staging/prod require manual approval

## Design Decisions

- **Single NAT for dev, per-AZ NAT for prod** — balances cost vs HA
- **Default SG locked down** — deny all on the default security group
- **MFA enforced** — IAM users cannot perform any action without MFA
- **Flow logs to S3** — cost-effective with lifecycle (IA → Glacier → expire)
- **CloudTrail → CloudWatch** — enables real-time alerting on API events
