output "kubeconfig" {
  description = "Kubeconfig for the Talos Kubernetes cluster"
  value       = talos_cluster_kubeconfig.talos.kubeconfig_raw
  sensitive   = true
}

output "talosconfig" {
  description = "Talos client configuration"
  value       = data.talos_client_configuration.talos.talos_config
  sensitive   = true
}

# output "valkey_password" {
#   value     = random_password.valkey.result
#   sensitive = true
# }

# output "grafana_admin_password" {
#   value     = random_password.grafana_admin.result
#   sensitive = true
# }

# output "gitea_admin_password" {
#   value     = random_password.gitea_admin.result
#   sensitive = true
# }