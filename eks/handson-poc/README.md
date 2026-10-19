# EKS Hands-on POC

Hands-on build of an Amazon EKS cluster from scratch (private-only API endpoint, managed node group on AL2023, custom launch template), then installing ArgoCD. Provisioned by hand first to understand each piece, then captured in Terraform.

## Contents
- [docs/build-log.md](docs/build-log.md): the clean build as an ordered runbook (VPC, IAM, cluster, add-ons, nodes, bastion, teardown) with verify commands
- [docs/issues.md](docs/issues.md): every error hit across two builds, each with symptom, cause, how it was found, fix and prevention
- [docs/decisions.md](docs/decisions.md): choices made and why, including alternatives rejected

## How to use these notes
Read `build-log.md` top to bottom to rebuild. When something fails, search `issues.md` for the symptom in the words you would google. The "Found by" line in each issue is the diagnostic skill worth keeping.

## Environment
- Region: us-east-1
- Kubernetes: 1.36
- Nodes: AL2023 (nodeadm), Graviton (c6g/c7g)
- API endpoint: private only, reached through a bastion in the VPC

## Before publishing: sanitize
Replace with placeholders before pushing anywhere public:
- AWS account ID -> `<ACCOUNT_ID>`
- Cluster endpoint hostname, CA data, role/instance/SG/subnet IDs
- Public IPs, bastion address, internal profile and SSO role names
- Company tag values
