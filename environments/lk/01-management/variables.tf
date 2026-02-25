variable "rancher_url" {
  type        = string
  description = "URL of the Rancher server"
}

variable "bootstrap_password" {
  type        = string
  description = "Temporary bootstrap password for Rancher"
  sensitive   = true
}

variable "admin_password" {
  type        = string
  description = "Permanent admin password for Rancher"
  sensitive   = true
}

variable "harvester_kubeconfig_path" {
  type        = string
  description = "Path to the Harvester kubeconfig file"
  default     = "../00-bootstrap/harvester.kubeconfig"
}

variable "harvester_cluster_name" {
  type        = string
  description = "Name for the Harvester cluster in Rancher"
  default     = "harvester-hci"
}
