terraform {
  required_providers {
    harvester = {
      source  = "harvester/harvester"
      version = "~> 0.6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

resource "random_password" "pg_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "harvester_virtualmachine" "pg_nodes" {
  count                = 2
  name                 = "${var.cluster_name}-node-${count.index}"
  namespace            = var.harvester_namespace
  restart_after_update = true

  cpu    = var.cpu
  memory = var.memory

  run_strategy = "RerunOnFailure"
  machine_type = "q35"
  
  ssh_keys = [var.ssh_key_name]

  network_interface {
    name           = "nic-1"
    wait_for_lease = true
    network_name   = var.network_name
  }

  disk {
    name       = "rootdisk"
    type       = "disk"
    size       = var.disk_size
    bus        = "virtio"
    boot_order = 1
    image       = var.image_name
    auto_delete = true
  }

  cloudinit {
    user_data = templatefile("${path.module}/templates/pg-init.yaml.tpl", {
      pg_password = random_password.pg_password.result,
      is_primary  = count.index == 0 ? true : false,
      primary_ip  = count.index == 0 ? "127.0.0.1" : "\${primary_floating_ip_here}" # Example logic for replication
    })
    network_data = ""
  }
}
