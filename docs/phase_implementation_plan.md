# Harvester Terraform Framework - Phase 1 Implementation

## Goal Description
Establish a modular, multi-region Terraform framework for managing Harvester HCI.
The objective is to provide a "vended" experience for product teams, allowing them to spin up K8s clusters and workloads with minimal variable inputs.

## Technical Implementation (Phase 1: Management Tier)

### 1. Rancher Environment Bootstrap
- **Feature Flags**: Enabled `harvester` and `harvester-baremetal-container-workload` (Experimental) via `rancher2_setting`.
- **UI Extension**: Automated the installation of the Harvester UI Extension (Version `1.7.1`) in the `cattle-ui-plugin-system` namespace.
- **Cloud Credentials**: Created `rancher2_cloud_credential` for Harvester import targeting the `local` cluster.

### 2. Harvester Cluster Integration (Norman/v1 API)
> [!IMPORTANT]
> The implementation was reverted from `rancher2_cluster_v2` to the legacy `rancher2_cluster` (Norman/v1 API). 
> This is critical because Harvester's "Virtualization Management" integration expects the legacy object to properly link Harvester nodes to the Rancher management plane without attempting to provision them as RKE2 nodes.

- **Resource**: `rancher2_cluster.harvester_hci`
- **Labels**: Applied `provider.cattle.io = harvester` for discovery.

### 3. Dynamic DNS & Registration Automation
To resolve the "Pending" status caused by nodes being unable to reach `rancher.lk.internal`:

- **Remote State**: used `terraform_remote_state` to pull the Rancher LoadBalancer IP and Hostname from the Phase 0 (Bootstrap) tier.
- **CoreDNS Patch**: Used `kubernetes_config_map_v1_data` to directly patch the `rke2-coredns-rke2-coredns` ConfigMap on the Harvester cluster. This prepends the Rancher host entry to the Corefile, ensuring the `cattle-cluster-agent` can resolve and download its registration manifest.
- **Harvester Settings**:
    - **`cluster-registration-url`**: Automated point-back to Rancher's manifest URL.
    - **`rancher-cluster`**: Automated setting with correct JSON encoding (`clusterId` and `clusterName`) to satisfy Harvester's admission webhook.

### 4. Lifecycle Management
- **RAM Parameterization**: Parameterized VM memory (defaulted to `8Gi`).
- **Destroy-Time Cleanup**: Added a `local-exec` provisioner to the registration `null_resource` using `when = destroy`. This explicitly deletes the `cattle-cluster-agent` deployment and secrets from the Harvester cluster during a `terraform destroy`, ensuring a clean state for rapid re-provisioning.

## Verification
- **DNS**: Verified `cluster-registration-url` status in Harvester settings is `True`.
- **Connectivity**: Verified `cattle-cluster-agent` is connected and cluster status in Rancher is `Active`.
- **Idempotency**: Verified `terraform apply` is safe to run on an already-registered cluster.

## Phase 2 Plan (Workload Tier)
The objective of Phase 2 is to build "vended" modules that Product Teams can consume to self-serve infrastructure on Harvester, fully managed via Rancher.

### Proposed Modules (`modules/tenants/`)
1. **`k8s-cluster`**: A module to deploy a downstream Guest Kubernetes cluster on Harvester VMs.
   - **Mechanism**: Utilizes the `rancher2_cluster_v2` resource configured with the Harvester Node Driver (`machine_pools` referencing Harvester VM templates).
   - **Inputs**: Cluster name, Kubernetes version, Node count (control plane vs worker), CPU/Memory sizing, and Harvester network details.
   - **Outputs**: Kubeconfig for the new cluster, Rancher UI URL.

2. **`postgres-ha`**: A module to deploy a highly available PostgreSQL cluster directly on Harvester VMs.
   - **Mechanism**: Uses `harvester_virtualmachine` resources with Cloud-Init (`user_data`) to bootstrap PostgreSQL in a primary-replica configuration.
   - **Inputs**: VM sizing, storage capacities, network attachment, and DB credentials.
   - **Outputs**: Database connection endpoints.

### Immediate Next Steps for Phase 2:
1. Initialize the `02-tenants` environment directory.
2. Develop the `k8s-cluster` module.
    - Requires setting up a Harvester Cloud Credential for the Node Driver.
    - Requires defining node templates/machine config for Harvester VMs.
3. Test instantiation of the module to verify a guest RKE2 cluster provisions successfully.
