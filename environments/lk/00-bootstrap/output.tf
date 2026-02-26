output "rancher_hostname" {
  value = module.rancher_bootstrap.rancher_hostname
}

output "rancher_url" {
  value = "https://${module.rancher_bootstrap.rancher_hostname}"
}

output "rancher_lb_ip" {
  value = module.rancher_bootstrap.rancher_lb_ip
}
