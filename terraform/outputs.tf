output "kubernetes_api_endpoint" {
  description = "Stable Kubernetes API endpoint (DNS + VIP; not a single control-plane IP)"
  value       = local.kubernetes_api_endpoint
}

output "kubernetes_api_vip" {
  description = "Talos Layer-2 VIP for the Kubernetes API"
  value       = var.kubernetes_api_vip
}

output "kubernetes_api_dns" {
  description = "DNS name for the Kubernetes API"
  value       = var.kubernetes_api_dns
}

output "control_planes" {
  description = "Control-plane VM inventory"
  value = {
    for name, mod in module.control_plane : name => {
      name        = mod.name
      vm_id       = mod.vm_id
      node_name   = mod.node_name
      ip          = local.control_planes[name].ip
      mac_address = mod.mac_address
    }
  }
}

output "workers" {
  description = "Worker VM inventory"
  value = {
    for name, mod in module.worker : name => {
      name        = mod.name
      vm_id       = mod.vm_id
      node_name   = mod.node_name
      ip          = local.workers[name].ip
      mac_address = mod.mac_address
    }
  }
}

output "vm_names" {
  description = "All VM names"
  value       = keys(local.all_nodes)
}

output "vm_ids" {
  description = "Map of VM name to Proxmox VM ID"
  value = merge(
    { for name, mod in module.control_plane : name => mod.vm_id },
    { for name, mod in module.worker : name => mod.vm_id },
  )
}

output "vm_ips" {
  description = "Planned static IPs (configured by Talos, not Terraform cloud-init)"
  value       = { for name, n in local.all_nodes : name => n.ip }
}

output "vm_nodes" {
  description = "Map of VM name to Proxmox node"
  value       = { for name, n in local.all_nodes : name => n.node_name }
}

output "vm_mac_addresses" {
  description = "Deterministic MACs for DHCP reservations"
  value       = { for name, n in local.all_nodes : name => n.mac_address }
}

output "gateway" {
  description = "Default gateway used in Talos machine configs"
  value       = var.gateway
}

output "network_cidr_prefix" {
  description = "CIDR prefix length for node IPs"
  value       = var.network_cidr_prefix
}

output "cluster_name" {
  description = "Cluster name"
  value       = var.cluster_name
}

output "kubeconfig" {
  description = "Kubeconfig for the Talos Kubernetes cluster"
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

output "talosconfig" {
  description = "Talos client configuration"
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}