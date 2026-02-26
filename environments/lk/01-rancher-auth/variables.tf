variable "rancher_url" {
  type        = string
  description = "URL of the Rancher server"
}

variable "bootstrap_password" {
  type        = string
  description = "Temporary bootstrap password for Rancher (set by Helm chart)"
  sensitive   = true
}

variable "admin_password" {
  type        = string
  description = "Permanent admin password to set for Rancher"
  sensitive   = true
}
