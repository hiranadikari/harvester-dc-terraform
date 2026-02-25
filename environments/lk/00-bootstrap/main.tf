terraform {
  required_providers {
    harvester = {
      source  = "harvester/harvester"
      version = "~> 0.6.0"
    }
  }
}

provider "harvester" {
  kubeconfig = var.harvester_kubeconfig
}

module "rancher_bootstrap" {
  source = "../../../modules/bootstrap"

  vm_name              = "rancher-lk"
  harvester_namespace  = "default"
  cluster_network_name = "mgmt"
  cluster_vlan_id      = 100
  ubuntu_image_id      = data.harvester_image.ubuntu20.id
  vm_memory            = var.vm_memory

  vm_password            = var.vm_password
  rancher_hostname       = "rancher.lk.internal"
  rancher_admin_password = var.rancher_admin_password

  ippool_subnet  = "192.168.10.1/24"
  ippool_gateway = "192.168.10.1"
  ippool_start   = "192.168.10.200"
  ippool_end     = "192.168.10.250"
}

output "rancher_hostname" {
  value = module.rancher_bootstrap.rancher_hostname
}

output "rancher_url" {
  value = "https://${module.rancher_bootstrap.rancher_hostname}"
}

output "rancher_lb_ip" {
  value = module.rancher_bootstrap.rancher_lb_ip
}
