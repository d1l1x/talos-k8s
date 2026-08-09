variable "talos_image_factory_id" {
  description = "ID of the image to download from Siderolabs image factory"
  type = string
  default = "376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4ba"
  nullable = false
}

variable "talos_version" {
  description = "Version of Talos to deploy"
  type = string
  default = "1.13.8"
  nullable = false 
}

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

variable "cluster_name" {
  description = "Logical Kubernetes / Talos cluster name"
  type        = string
  default     = "talos-k8s"
}

variable "kubernetes_api_dns" {
  description = "Stable DNS name for the Kubernetes API"
  type        = string
  default     = "k8s-api.k8s.internal"
}

variable "kubernetes_api_vip" {
  description = "Talos Layer-2 VIP for the Kubernetes API"
  type        = string
  default     = "10.10.40.2"
}

variable "gateway" {
  description = "IPv4 default gateway for cluster nodes"
  type        = string
  default     = "10.10.40.1"
}

variable "dns_server" {
  description = "IPv4 default DNS servers for cluster nodes"
  type        = string
  default     = "10.0.0.1"
}

variable "network_cidr_prefix" {
  description = "CIDR prefix length for node IPs"
  type        = number
  default     = 27
}

variable "bridge" {
  description = "Proxmox network bridge"
  type        = string
  default     = "vmbr1"
}

variable "vlan" {
  description = "Proxmox network bridge VLAN to tag with"
  type        = number
  default     = 40
}

variable "datastore_id" {
  description = "Datastore for VM system disks"
  type        = string
  default     = "proxmox-share-lvm"
}

variable "iso_file_id" {
  description = "Talos metal ISO already uploaded to Proxmox"
  type        = string
  default     = "local:iso/metal-amd64.iso"
}

variable "mac_prefix" {
  description = "First three octets of deterministic MACs (locally administered)"
  type        = string
  default     = "BC:24:11"
}

variable "control_plane_cpu_cores" {
  type    = number
  default = 2
}

variable "control_plane_memory_mb" {
  type    = number
  default = 4096
}

variable "control_plane_disk_gb" {
  type    = number
  default = 40
}

variable "worker_cpu_cores" {
  type    = number
  default = 2
}

variable "worker_memory_mb" {
  type    = number
  default = 4096
}

variable "worker_disk_gb" {
  type    = number
  default = 40
}

variable "control_planes" {
  description = "Control-plane VM definitions keyed by name"
  type = map(object({
    node_name = string
    vm_id     = number
    ip        = string
    gateway        = string
    mac_host  = string
  }))
  default = {
    "k8s-cp-01" = {
      node_name = "pve01"
      vm_id     = 210
      ip        = "10.10.40.10/27"
      gateway   = "10.10.40.1"
      mac_host  = "00:11:01"
    }
    "k8s-cp-02" = {
      node_name = "pve02"
      vm_id     = 211
      ip        = "10.10.40.11/27"
      gateway   = "10.10.40.1"
      mac_host  = "00:11:02"
    }
    "k8s-cp-03" = {
      node_name = "pve03"
      vm_id     = 212
      ip        = "10.10.40.12/27"
      gateway   = "10.10.40.1"
      mac_host  = "00:11:03"
    }
  }
}

variable "workers" {
  description = "Worker VM definitions keyed by name"
  type = map(object({
    node_name = string
    vm_id     = number
    ip        = string
    gateway   = string
    mac_host  = string
  }))
  default = {
    "k8s-worker-01" = {
      node_name = "pve01"
      vm_id     = 220
      ip        = "10.10.40.20/27"
      gateway   = "10.10.40.1"
      mac_host  = "00:11:04"
    }
    "k8s-worker-02" = {
      node_name = "pve02"
      vm_id     = 221
      ip        = "10.10.40.21/27"
      gateway   = "10.10.40.1"
      mac_host  = "00:11:05"
    }
    "k8s-worker-03" = {
      node_name = "pve03"
      vm_id     = 222
      ip        = "10.10.40.22/27"
      gateway   = "10.10.40.1"
      mac_host  = "00:11:06"
    }
  }
}
