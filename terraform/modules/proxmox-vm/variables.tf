variable "name" {
  description = "VM name"
  type        = string
}

variable "vm_id" {
  description = "Proxmox VM ID"
  type        = number
}

variable "node_name" {
  description = "Proxmox node to place the VM on"
  type        = string
}

variable "description" {
  description = "VM description"
  type        = string
  default     = "Managed by Terraform"
}

variable "tags" {
  description = "Proxmox tags"
  type        = list(string)
  default     = ["talos", "k8s"]
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "cpu_type" {
  description = "CPU type passed to QEMU"
  type        = string
  default     = "x86-64-v2-AES"
}

variable "memory_mb" {
  description = "Dedicated memory in MiB"
  type        = number
  default     = 4096
}

variable "disk_size_gb" {
  description = "System disk size in GiB"
  type        = number
  default     = 40
}

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

variable "ipv4" {
  description = "IPv4 address"
  type        = string
  default     = null
}

variable "ipv4_gateway" {
  description = "IPv4 gateway"
  type        = string
  default     = null
}

variable "vlan_id" {
  description = "VLAN tag"
  type        = number
  default     = null
}

variable "mac_address" {
  description = "Deterministic MAC address for DHCP reservations"
  type        = string
}

variable "iso_file_id" {
  description = "Talos ISO file ID, e.g. local:iso/metal-amd64.iso"
  type        = string
}

variable "cdrom_interface" {
  description = "CD-ROM interface for the Talos ISO"
  type        = string
  default     = "ide2"
}

variable "started" {
  description = "Whether the VM should be started after create"
  type        = bool
  default     = true
}

variable "talos_machine_type" {
  description = "Type this talos machine is intended for"
  type = string
  default = null
}

variable "talos_secrets" {
  description = "Generated secrets required by talos cluster"
  type = object({
    machine_secrets = any
  })
  # sensitive = true
}
