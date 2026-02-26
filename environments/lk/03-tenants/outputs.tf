output "tenant_cluster_id" {
  value       = module.tenant_k8s_cluster.cluster_id
  description = "The v1 Rancher ID for the downstream cluster"
}

output "tenant_cluster_name" {
  value       = module.tenant_k8s_cluster.cluster_name
  description = "The name of the provisioned downstream cluster"
}

output "tenant_kubeconfig" {
  value       = module.tenant_k8s_cluster.kubeconfig
  description = "The Kubeconfig for the downstream cluster"
  sensitive   = true
}
