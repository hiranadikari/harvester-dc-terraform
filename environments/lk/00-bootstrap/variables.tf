variable "vm_memory" {
  type        = string
  description = "Memory for the Rancher VM"
  default     = "8Gi"
}

variable "harvester_kubeconfig" {
  type        = string
  description = "Path to the Harvester kubeconfig file"
}

variable "vm_password" {
  type        = string
  description = "Password for the VM default user"
  sensitive   = true
}

variable "rancher_admin_password" {
  type        = string
  description = "Bootstrap password for Rancher Admin user"
  sensitive   = true
}

variable "image_url" {
  type        = string
  description = "URL of the Ubuntu 22.04 LTS image"
  default     = "https://cloud-images.ubuntu.com/jammy/20260219/jammy-server-cloudimg-amd64.img"
}
