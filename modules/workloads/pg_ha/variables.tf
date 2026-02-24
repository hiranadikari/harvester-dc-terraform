variable "cluster_name" {
  type        = string
  description = "The prefix name for the PostgreSQL DB nodes"
}

variable "harvester_namespace" {
  type        = string
  description = "The Harvester namespace to deploy into"
  default     = "default"
}

variable "ssh_key_name" {
  type        = string
  description = "The existing SSH key name in Harvester to inject"
}

variable "network_name" {
  type        = string
  description = "The VLAN/network name in Harvester"
}

variable "image_name" {
  type        = string
  description = "The Harvester image to boot from (e.g., Ubuntu)"
}

variable "cpu" {
  type    = number
  default = 4
}

variable "memory" {
  type    = string
  default = "8Gi"
}

variable "disk_size" {
  type    = string
  default = "100Gi"
}
