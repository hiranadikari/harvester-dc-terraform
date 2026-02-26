variable "rancher_url" {
  type        = string
  description = "The URL of the Rancher server"
}

variable "admin_token" {
  type        = string
  description = "Permanent Rancher Bearer Token"
  sensitive   = true
}

variable "harvester_cloud_credential_id" {
  type        = string
  description = "Cloud Credential ID for Harvester in Rancher (from Phase 1)"
}

variable "admin_password" {
  type        = string
  description = "Password for the VM's ubuntu user"
  sensitive   = true
}
