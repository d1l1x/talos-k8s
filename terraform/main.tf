resource "talos_machine_secrets" "this" {}

module "control_plane" {
  depends_on = [ talos_machine_secrets.this ]
  source   = "./modules/proxmox-vm"
  for_each = local.control_planes

  name         = each.key
  vm_id        = each.value.vm_id
  node_name    = each.value.node_name
  description  = "Talos control plane — ${each.key}"
  tags         = ["talos", "k8s", "controlplane"]
  cpu_cores    = var.control_plane_cpu_cores
  memory_mb    = var.control_plane_memory_mb
  disk_size_gb = var.control_plane_disk_gb
  datastore_id = var.datastore_id
  bridge       = var.bridge
  vlan_id      = var.vlan
  ipv4         = each.value.ip
  ipv4_gateway = each.value.gateway
  mac_address  = each.value.mac_address
  iso_file_id  = var.iso_file_id
  talos_machine_type = each.value.role
  talos_secrets = {
    machine_secrets = talos_machine_secrets.this.machine_secrets
    client_configuration = talos_machine_secrets.this.client_configuration
  }
}

module "worker" {
  depends_on = [ talos_machine_secrets.this ]
  source   = "./modules/proxmox-vm"
  for_each = local.workers

  name         = each.key
  vm_id        = each.value.vm_id
  node_name    = each.value.node_name
  description  = "Talos worker — ${each.key}"
  tags         = ["talos", "k8s", "worker"]
  cpu_cores    = var.worker_cpu_cores
  memory_mb    = var.worker_memory_mb
  disk_size_gb = var.worker_disk_gb
  datastore_id = var.datastore_id
  bridge       = var.bridge
  vlan_id      = var.vlan
  ipv4         = each.value.ip
  ipv4_gateway = each.value.gateway
  mac_address  = each.value.mac_address
  iso_file_id  = var.iso_file_id
  talos_machine_type = each.value.role
  talos_secrets = {
    machine_secrets = talos_machine_secrets.this.machine_secrets
  }
}

# locals {
#   # All Talos nodes: control planes + workers
#   talos_nodes = concat(
#     [
#       for vm in values(module.control_plane) : vm.ipv4_address
#     ],
#     [
#       for vm in values(module.worker) : vm.ipv4_address
#     ]
#   )
#   # Only control planes — used as Talos API endpoints
#   talos_endpoints = [
#     for vm in values(module.control_plane) : vm.ipv4_address
#   ]
# }
# --------------------------------------------------------------------------
# Talos machine configurations
# --------------------------------------------------------------------------
data "talos_machine_configuration" "control_plane" {
  for_each = local.control_planes
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  cluster_name     = "talos-testcluster"
  cluster_endpoint = "https://${var.kubernetes_api_dns}:6443"
  machine_type = "controlplane"
  config_patches = [
    yamlencode({
      machine = {
        network = {
          interfaces = [
            {
              interface = "ens18"
              dhcp = false
              addresses = [
                each.value.ip
              ]
              routes = [
                {
                  network = "0.0.0.0/0"
                  gateway = each.value.gateway
                }
              ]
              vip = {
                ip = var.kubernetes_api_vip
              }
            }
          ]
          nameservers = [ var.dns_server ]
        }
      }
    })
  ]
}

data "talos_machine_configuration" "worker" {
  for_each = local.workers
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  cluster_name     = "talos-testcluster"
  cluster_endpoint = "https://${var.kubernetes_api_dns}:6443"
  machine_type = "worker"
  config_patches = [
    yamlencode({
      machine = {
        network = {
          interfaces = [
            {
              interface = "ens18"
              dhcp = false
              addresses = [
                each.value.ip
              ]
              routes = [
                {
                  network = "0.0.0.0/0"
                  gateway = each.value.gateway
                }
              ]
            }
          ]
          nameservers = [ var.dns_server ]
        }
      }
    })
  ]
}

locals {
  talos_machine_configs = merge(
    {
      for name, vm in module.control_plane :
      name => {
        config = data.talos_machine_configuration.control_plane[name].machine_configuration
        ip     = vm.ipv4_address
      }
    },
    {
      for name, vm in module.worker :
      name => {
        config = data.talos_machine_configuration.worker[name].machine_configuration
        ip     = vm.ipv4_address
      }
    }
  )
}


data "talos_client_configuration" "this" {
  depends_on = [
    module.control_plane,
    module.worker,
    data.talos_machine_configuration.control_plane,
    data.talos_machine_configuration.worker,
  ]
  cluster_name         = "talos-testcluster"
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes = local.all_node_ips
  endpoints = local.control_plane_ips
}
# --------------------------------------------------------------------------
# Apply machine configuration
# --------------------------------------------------------------------------
resource "talos_machine_configuration_apply" "this" {
  depends_on = [
    module.control_plane,
    module.worker,
    data.talos_machine_configuration.control_plane,
    data.talos_machine_configuration.worker,
  ]
  for_each = local.talos_machine_configs
  client_configuration        = data.talos_client_configuration.this.client_configuration
  machine_configuration_input = each.value.config
  node                        = each.value.ip
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [
    module.control_plane,
    module.worker,
    data.talos_machine_configuration.control_plane,
    data.talos_machine_configuration.worker,
  ]
  node                 = local.first_control_plane_ip
  client_configuration = talos_machine_secrets.this.client_configuration
}


resource "talos_cluster_kubeconfig" "this" {
  depends_on = [
    module.control_plane,
    data.talos_machine_configuration.control_plane,
    data.talos_machine_configuration.worker,
  ]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = local.first_control_plane_ip
}