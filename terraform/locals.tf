locals {
  kubernetes_api_endpoint = "https://${var.kubernetes_api_dns}:6443"

  control_planes = {
    for name, n in var.control_planes : name => merge(n, {
      mac_address = upper("${var.mac_prefix}:${n.mac_host}")
      role        = "controlplane"
    })
  }

  workers = {
    for name, n in var.workers : name => merge(n, {
      mac_address = upper("${var.mac_prefix}:${n.mac_host}")
      role        = "worker"
    })
  }

  all_nodes = merge(local.control_planes, local.workers)

  first_control_plane_ip = split("/",local.control_planes[keys(local.control_planes)[0]].ip)[0]
  # All control-plane IPs, without CIDR prefix
  control_plane_ips = [
    for n in values(local.control_planes) :
    split("/", n.ip)[0]
  ]
  # All node IPs (control planes + workers), without CIDR prefix
  all_node_ips = [
    for n in values(local.all_nodes) :
    split("/", n.ip)[0]
  ]
}
