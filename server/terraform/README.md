# Terraform — GCP VM + Cloud DNS

Infrastructure-as-Code to provision on Google Cloud:

1. **Compute VM** — `e2-medium` = **2 vCPU / 4 GB memory**, Ubuntu 22.04 LTS.
2. **Firewall** — allows SSH (22), HTTP (80), HTTPS (443), and K3s API (6443).
3. **Cloud DNS** — a managed zone plus an `A` record pointing a hostname at the VM's public IP.

This pairs with the [`../ansible`](../ansible) playbooks, which install Docker + K3s on the provisioned VM.

## Structure

```
terraform/
├── versions.tf              # Provider + required versions
├── variables.tf             # Input variables
├── main.tf                  # VM, firewall, DNS zone + record
├── outputs.tf               # VM IP, DNS name servers, FQDN
├── terraform.tfvars.example # Sample values — copy to terraform.tfvars
└── .gitignore               # Ignores state and tfvars
```

## Requirements

- Terraform >= 1.3
- A GCP project with billing enabled and the **Compute Engine** and **Cloud DNS** APIs enabled.
- Authentication, either:
  - `gcloud auth application-default login`, or
  - a service account key via `export GOOGLE_APPLICATION_CREDENTIALS=/path/key.json`

## Usage

```bash
cd server/terraform

# 1. Provide your values
cp terraform.tfvars.example terraform.tfvars
#   then edit terraform.tfvars (project_id, dns_domain, etc.)

# 2. Initialise providers
terraform init

# 3. Preview the plan
terraform plan

# 4. Apply
terraform apply
```

## Key variables

| Variable          | Default                          | Notes                                            |
| ----------------- | -------------------------------- | ------------------------------------------------ |
| `project_id`      | — (required)                     | Your GCP project ID                              |
| `machine_type`    | `e2-medium`                      | **2 vCPU / 4 GB** — the requested spec           |
| `region` / `zone` | `asia-southeast2` / `-a`         | Jakarta region; change as needed                 |
| `dns_domain`      | — (required)                     | Zone domain, **must end with a dot** (`example.com.`) |
| `dns_record_name` | `app`                            | Subdomain → `app.example.com`                    |

## Outputs

After `apply`:

- `vm_external_ip` — connect via `ssh ubuntu@<ip>`
- `dns_fqdn` — the hostname mapped to the VM
- `dns_zone_name_servers` — set these NS records at your domain registrar so the zone resolves publicly

## Clean up

```bash
terraform destroy
```
