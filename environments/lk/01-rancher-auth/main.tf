provider "rancher2" {
  api_url   = var.rancher_url
  bootstrap = true
  insecure  = true
}

resource "rancher2_bootstrap" "admin" {
  initial_password = var.bootstrap_password
  password         = var.admin_password
}
