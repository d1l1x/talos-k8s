resource "proxmox_virtual_environment_vm" "this" {
  name        = var.name
  description = var.description
  tags        = var.tags
  node_name   = var.node_name
  vm_id       = var.vm_id

  started         = var.started
  on_boot         = true
  stop_on_destroy = true

  agent {
    enabled = true
    wait_for_ip {
      ipv4 = true
    }
  }


  cpu {
    cores = var.cpu_cores
    type  = var.cpu_type
  }

  memory {
    dedicated = var.memory_mb
  }

  disk {
    datastore_id = var.datastore_id
    interface    = var.disk_interface
    size         = var.disk_size_gb
    file_format  = "raw"
    iothread     = true
    discard      = "on"
  }

  cdrom {
    file_id   = var.iso_file_id
    interface = var.cdrom_interface
  }

  boot_order = [var.cdrom_interface, var.disk_interface]

  network_device {
    bridge      = var.bridge
    model       = "virtio"
    mac_address = var.mac_address
    vlan_id     = var.vlan_id
  }

  operating_system {
    type = "l26"
  }

  serial_device {
    device = "socket"
  }
}

locals {
  vm_ipv4_address = one([
    for ip in flatten(proxmox_virtual_environment_vm.this.ipv4_addresses) : ip
    if can(regex("^10\\.10\\.40\\.", ip))
  ])
}