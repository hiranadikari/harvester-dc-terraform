# We retrieve the Harvester integration variables from Phase 1 output
# if needed, or pass them directly as variables.

module "tenant_k8s_cluster" {
  source = "../../modules/tenants/k8s-cluster"

  cluster_name        = "tenant-cluster-1"
  kubernetes_version  = "v1.28.11+rke2r1"
  cloud_credential_id = var.harvester_cloud_credential_id

  # Replace with the actual namespace/name of the Harvester OS image and Network
  harvester_namespace  = "default"
  harvester_image_id   = "default/image-xxxxx"
  harvester_network_id = "default/vlan-xxxxx"

  # Sizing
  control_plane_count = 1
  worker_count        = 2
  cpu_count           = 2
  memory_size         = "4Gi"
  disk_size           = "40Gi"

  admin_password = var.admin_password
}
