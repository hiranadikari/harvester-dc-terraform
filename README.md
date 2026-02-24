# Harvester Datacenter (DC) Framework

Modular Terraform framework for architecting and managing Harvester HCI environments with integrated Rancher management.

## Project Structure

```text
dc/
├── environments/
│   ├── lk/
│   │   ├── 00-bootstrap/     # Phase 0: Provisions Rancher on Harvester
│   │   ├── 01-management/    # Phase 1: Rancher/Harvester Configuration (Coming Soon)
│   │   └── 02-tenants/       # Phase 2: Tenant Clusters (Coming Soon)
├── modules/
│   ├── bootstrap/            # RKE2 + Rancher via Cloud-init
│   ├── management/           # Networking, Storage, RBAC modules
│   └── tenants/              # K8s-as-a-Service templates
└── brain/                    # Implementation plans and task tracking
```

## Getting Started

### Prerequisites

1.  **Harvester HCI** cluster up and running.
2.  **Terraform** installed locally.
3.  **kubectl** installed locally.

### Phase 0: Bootstrap

1.  Navigate to the environment directory:
    ```bash
    cd environments/lk/00-bootstrap
    ```
2.  Configure your credentials in `secrets.secret.tfvars`.
3.  Initialize and apply:
    ```bash
    terraform init
    terraform apply -var-file="secrets.secret.tfvars"
    ```
4.  **Important:** Map the Load Balancer IP to `rancher.lk.internal` in your `/etc/hosts`.

## Development

This project was developed using a local build of the `terraform-provider-harvester` to address specific LB provisioning bugs. See `brain/implementation_plan.md` for technical deep-dives.
