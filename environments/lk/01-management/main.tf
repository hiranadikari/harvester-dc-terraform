provider "rancher2" {
  api_url   = var.rancher_url
  bootstrap = true
  insecure  = true
}

# 0. Pull Phase 0 (Bootstrap) state for dynamic resource discovery
data "terraform_remote_state" "bootstrap" {
  backend = "local"

  config = {
    path = "../00-bootstrap/terraform.tfstate"
  }
}

# 1. Bootstrap Rancher (Reset admin password and get API token)
resource "rancher2_bootstrap" "admin" {
  initial_password = var.bootstrap_password
  password         = var.admin_password
}

# 2. Configure a separate provider instance for authenticated calls
provider "rancher2" {
  alias     = "admin"
  api_url   = var.rancher_url
  token_key = rancher2_bootstrap.admin.token
  insecure  = true
}

# 3. Configure Harvester Provider for direct settings automation
provider "harvester" {
  kubeconfig = var.harvester_kubeconfig_path
}

# 4. Configure Kubernetes Provider for Harvester system patching
provider "kubernetes" {
  config_path = var.harvester_kubeconfig_path
}

# 5. Call Harvester Integration module
module "harvester_integration" {
  source = "../../../modules/management/harvester-integration"
  providers = {
    rancher2   = rancher2.admin
    harvester  = harvester
    kubernetes = kubernetes
  }
  harvester_kubeconfig   = file(var.harvester_kubeconfig_path)
  harvester_cluster_name = var.harvester_cluster_name
  rancher_hostname       = data.terraform_remote_state.bootstrap.outputs.rancher_hostname
  rancher_lb_ip          = data.terraform_remote_state.bootstrap.outputs.rancher_lb_ip
}
