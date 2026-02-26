terraform {
  required_providers {
    rancher2 = {
      source  = "rancher/rancher2"
      version = "~> 8.0.0"
    }
    harvester = {
      source  = "harvester/harvester"
      version = "~> 0.6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
    }
  }
}
