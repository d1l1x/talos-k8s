output "name" {
  description = "VM name"
  value       = proxmox_virtual_environment_vm.this.name
}

output "vm_id" {
  description = "Proxmox VM ID"
  value       = proxmox_virtual_environment_vm.this.vm_id
}

output "node_name" {
  description = "Proxmox node"
  value       = proxmox_virtual_environment_vm.this.node_name
}

output "mac_address" {
  description = "Primary NIC MAC address"
  value       = var.mac_address
}

output "ipv4_address" {
  value = local.vm_ipv4_address
}