# kubernetes

Notes, manifests and cheatsheets from hands-on Kubernetes work: building clusters, running workloads, debugging them. Each topic lives in its own folder with a README, and anything that failed is written up with its cause and fix.

## What is here

| Folder | What it holds |
|---|---|
| [eks/handson-poc](eks/handson-poc) | Building an EKS 1.36 cluster from scratch: ordered runbook, every error hit and how it was found, and the decisions behind it |
| [kafka](kafka) | Kafka command cheatsheet and a client Pod manifest for talking to a Kafka cluster from inside Kubernetes |

## Related repositories

| Repo | Purpose |
|---|---|
| [Automated-Infra-Via-Terraform](https://github.com/msaxena14/Automated-Infra-Via-Terraform) | Terraform for the infrastructure these notes build on (VPC and more) |
| [ArgoCD](https://github.com/msaxena14/ArgoCD) | Argo CD setup and the applications it manages |
| [msaxena14.github.io](https://github.com/msaxena14/msaxena14.github.io) | Published site, including write-ups of debugging investigations |

## How this repo is organised

```
kubernetes/
├── README.md                this index
├── <topic>/                 one folder per tool or platform (eks, kafka, ...)
│   ├── README.md            what the topic covers, how to use it
│   ├── <project>/           a hands-on build, when there is one
│   │   ├── README.md        overview, contents, environment
│   │   └── docs/
│   │       ├── build-log.md ordered runbook with verify commands
│   │       ├── issues.md    symptom, cause, found by, fix, prevent
│   │       └── decisions.md choices made and why
│   ├── manifests/           reusable YAML for the topic
│   └── cheatsheets/         short command references
```

## Adding something new

1. **New topic** (a tool or platform): create `<topic>/` with a `README.md`, then add a row to the table above.
2. **New hands-on project**: copy the project layout above. Write `build-log.md` as you go, one numbered step each, with the command and how you verified it.
3. **A new error**: add an entry to that project's `issues.md` in the five-line format (symptom, cause, found by, fix, prevent). "Found by" is the part worth keeping.
4. **Reusable YAML**: put it under `<topic>/manifests/` with comments saying which values to replace.

Naming: lowercase, hyphen-separated, topic first.

## Rules for everything committed here

- Never commit credentials, tokens, kubeconfigs, `.pem` keys, Terraform state, or real `*.tfvars` files.
- Replace real identifiers with placeholders before publishing: account IDs, ARNs, resource IDs (`vpc-...`, `sg-...`, `i-...`), IP addresses, cluster endpoints, CA data, internal hostnames.
- Prefer a sentence over a value when describing a setting: `<the ID of the VPC the database lives in>`.
- Use the GitHub noreply address for commits made here.
