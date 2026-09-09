variable "proxmox_endpoint" {
  description = "Proxmox API endpoint (e.g. https://10.0.0.5:8006/). Falls back to PROXMOX_VE_ENDPOINT."
  type        = string
  default     = null
  nullable    = true
}

variable "proxmox_api_token" {
  description = "Proxmox API token user@realm!tokenid=secret. Falls back to PROXMOX_VE_API_TOKEN."
  type        = string
  default     = null
  sensitive   = true
  nullable    = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification for the Proxmox API (lab use)."
  type        = bool
  default     = true
}

variable "ssh_private_key_path" {
  description = "Path to private SSH key"
  type        = string
  sensitive   = true
}

variable "proxmox_pve_node_names" {
  type    = list(string)
  default = ["pve01", "pve02", "pve03"]
}

variable "pve_domain" {
  description = "The DNS domaine of the pve"
  type        = string
  default     = "proxmox.internal"
}



# variable "name" {
#   description = "VM name"
#   type        = string
# }

# variable "vm_id" {
#   description = "Proxmox VM ID"
#   type        = number
# }

# variable "node_name" {
#   description = "Proxmox node to place the VM on"
#   type        = string
# }

# variable "description" {
#   description = "VM description"
#   type        = string
#   default     = "Managed by Terraform"
# }

# variable "tags" {
#   description = "Proxmox tags"
#   type        = list(string)
#   default     = ["talos", "k8s"]
# }

# variable "cpu_cores" {
#   description = "Number of CPU cores"
#   type        = number
#   default     = 2
# }

variable "cpu_type" {
  description = "CPU type passed to QEMU"
  type        = string
  default     = "host"
}

# variable "memory_mb" {
#   description = "Dedicated memory in MiB"
#   type        = number
#   default     = 4096
# }

# variable "disk_size_gb" {
#   description = "System disk size in GiB"
#   type        = number
#   default     = 40
# }

variable "datastore_id" {
  description = "Datastore for the system disk"
  type        = string
}

variable "disk_interface" {
  description = "Primary disk interface"
  type        = string
  default     = "scsi0"
}

variable "bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "mac_prefix" {
  description = "First three octets of deterministic MACs (locally administered)"
  type        = string
  default     = "BC:24:11"
}

variable "talos_version" {
  description = "Version of Talos to deploy"
  type        = string
  default     = "1.13.9"
  nullable    = false
}

variable "talos_cluster_name" {
  description = "Logical Kubernetes / Talos cluster name"
  type        = string
  default     = "talos-k8s"
}

variable "talos_kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.36.0"
}

variable "talos_kubernetes_api_vip" {
  description = "Talos Layer-2 VIP for the Kubernetes API"
  type        = string
  default     = "10.10.40.2"
}

variable "talos_kubernetes_subnet_prefix" {
  description = "Prefix of the Kubernetes subnet"
  type        = string
  default     = "27"
}

variable "talos_kubernetes_cidr" {
  description = "CIDR of the controlplane subnet"
  type        = string
  default     = "10.10.40.0/27"

}

variable "ingress_domain" {
  description = "The DNS domain of the ingress resources"
  type        = string
  default     = "k8s.internal"
}
# ============
# valkey
variable "valkey_version" {
  type    = string
  default = "6.2.12" # bitnami/valkey chart version — check for latest
}

variable "valkey_storage_class" {
  type    = string
  default = "local-path" # swap for your actual StorageClass (Longhorn, etc.)
}

variable "valkey_admin_password" {
  type        = string
  sensitive   = true
  description = "Password of valkeys's admin user"
  default     = "foobar"
}

# ====================
# storage class
variable "local_path_provisioner_version" {
  type    = string
  default = "0.0.38" # check https://artifacthub.io/packages/helm/containeroo/local-path-provisioner for latest
}

# ====================
# observability
variable "kube_prometheus_stack_version" {
  type    = string
  default = "88.5.3" # check https://github.com/prometheus-community/helm-charts/releases for latest
}

variable "grafana_hostname" {
  type    = string
  default = "grafana.lab" # pick an internal domain that's actually yours to resolve
}

variable "loki_version" {
  type    = string
  default = "7.3.0" # check https://github.com/grafana/helm-charts/releases for latest
}

variable "alloy_version" {
  type    = string
  default = "1.11.1" # check https://github.com/grafana/alloy/releases for latest
}

variable "monitoring_storage_class" {
  type    = string
  default = "local-path" # swap for Longhorn once it's live
}

variable "grafana_admin_password" {
  type        = string
  sensitive   = true
  description = "Password of grafana's admin user"
  default     = "foobar"
}



variable "gitea_chart_version" {
  type    = string
  default = "12.7.0" # check https://gitea.com/gitea/helm-chart for latest
}

variable "gitea_hostname" {
  type    = string
  default = "git.lab"
}

variable "gitea_storage_size" {
  type    = string
  default = "20Gi"
}

variable "democratic_csi_version" {
  type    = string
  default = "0.15.1" # check https://github.com/democratic-csi/charts for latest
}

variable "truenas_host" {
  type        = string
  description = "TrueNAS SCALE management IP or hostname"
  default     = "10.0.0.52" # TODO: set to your actual TrueNAS IP
}

variable "truenas_api_key" {
  type        = string
  sensitive   = true
  description = "TrueNAS API key — Credentials > API Keys in the UI"
}

variable "truenas_iscsi_portal" {
  type        = string
  description = "TrueNAS iSCSI portal IP:port"
  default     = "10.0.0.52:3260" # TODO: match your TrueNAS iSCSI interface
}

variable "truenas_dataset_parent" {
  type        = string
  description = "Parent dataset for CSI-provisioned zvols — create this on TrueNAS first"
  default     = "k8s-storage/gitea" # TODO: match the dataset you created
}

variable "gitea_admin_password" {
  type        = string
  sensitive   = true
  description = "Password of gitea's admin user"
  default     = "foobar"
}

variable "gitea_postgres_password" {
  type        = string
  sensitive   = true
  description = "Password of gitea's postgres database"
  default     = "foobar"
}

variable "cnpg_chart_version" {
  type    = string
  default = "0.29.0" # check https://github.com/cloudnative-pg/charts/releases for latest
}

variable "timescaledb_image" {
  type    = string
  default = "ghcr.io/clevyr/cloudnativepg-timescale:17.5" # check https://github.com/clevyr/docker-cloudnativepg-timescale for latest
}

variable "timescaledb_storage_size" {
  type    = string
  default = "50Gi"
}

variable "control_planes" {
  description = "Control-plane VM definitions keyed by name"
  type = map(object({
    node_name   = string
    vm_id       = number
    hostnum     = number
    gateway     = string
    mac_host    = string
    cpus        = number
    memory      = number
    disk        = number
    role        = string
    vlan_id     = number
    description = string
    tags        = list(string)
  }))
  default = {
    "k8s-cp-01" = {
      node_name   = "pve01"
      vm_id       = 210
      hostnum     = 10
      gateway     = "10.10.40.1"
      mac_host    = "00:11:01"
      cpus        = 2
      memory      = 4096
      disk        = 32
      role        = "controlplane"
      vlan_id     = 40
      description = "Talos control plane"
      tags        = ["talos", "k8s", "controlplane"]
    }
    "k8s-cp-02" = {
      node_name   = "pve02"
      vm_id       = 211
      hostnum     = 11
      gateway     = "10.10.40.1"
      mac_host    = "00:11:02"
      cpus        = 2
      memory      = 4096
      disk        = 32
      role        = "controlplane"
      vlan_id     = 40
      description = "Talos control plane"
      tags        = ["talos", "k8s", "controlplane"]
    }
    "k8s-cp-03" = {
      node_name   = "pve03"
      vm_id       = 212
      hostnum     = 12
      gateway     = "10.10.40.1"
      mac_host    = "00:11:03"
      cpus        = 2
      memory      = 4096
      disk        = 32
      role        = "controlplane"
      vlan_id     = 40
      description = "Talos control plane"
      tags        = ["talos", "k8s", "controlplane"]
    }
  }
}

variable "workers" {
  description = "Worker VM definitions keyed by name"
  type = map(object({
    node_name   = string
    vm_id       = number
    hostnum     = number
    gateway     = string
    mac_host    = string
    cpus        = number
    memory      = number
    disk        = number
    role        = string
    vlan_id     = number
    description = string
    tags        = list(string)
  }))
  default = {
    "k8s-worker-01" = {
      node_name   = "pve01"
      vm_id       = 220
      hostnum     = 20
      gateway     = "10.10.40.1"
      mac_host    = "00:11:04"
      cpus        = 2
      memory      = 4096
      disk        = 32
      role        = "worker"
      vlan_id     = 40
      description = "Talos worker"
      tags        = ["talos", "k8s", "worker"]
    }
    "k8s-worker-02" = {
      node_name   = "pve02"
      vm_id       = 221
      hostnum     = 21
      gateway     = "10.10.40.1"
      mac_host    = "00:11:05"
      cpus        = 2
      memory      = 4096
      disk        = 32
      role        = "worker"
      vlan_id     = 40
      description = "Talos worker"
      tags        = ["talos", "k8s", "worker"]
    }
    "k8s-worker-03" = {
      node_name   = "pve03"
      vm_id       = 222
      hostnum     = 22
      gateway     = "10.10.40.1"
      mac_host    = "00:11:06"
      cpus        = 2
      memory      = 4096
      disk        = 32
      role        = "worker"
      vlan_id     = 40
      description = "Talos worker"
      tags        = ["talos", "k8s", "worker"]
    }
  }
}

