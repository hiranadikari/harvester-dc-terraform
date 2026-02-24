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
