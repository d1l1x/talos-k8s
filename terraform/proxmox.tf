resource "proxmox_virtual_environment_file" "talos" {
  for_each     = toset(["pve01", "pve02", "pve03"])
  node_name    = each.value
  datastore_id = "local"
  content_type = "iso"
  source_file {
    path      = "images/talos/talos-${var.talos_version}.qcow2"
    file_name = "talos-${var.talos_version}.img"
  }
}

resource "proxmox_virtual_environment_vm" "this" {
  for_each = merge(var.control_planes, var.workers)

  name        = each.key
  description = each.value.description
  tags        = each.value.tags
  node_name   = each.value.node_name
  vm_id       = each.value.vm_id

  started         = true
  on_boot         = true
  stop_on_destroy = true
  bios            = "ovmf"
  machine         = "q35"
  scsi_hardware   = "virtio-scsi-single"

  agent {
    enabled = true
    trim    = true
    wait_for_ip {
      ipv4 = true
    }
  }


  cpu {
    cores = each.value.cpus
    type  = var.cpu_type
  }

  memory {
    dedicated = each.value.memory
  }

  disk {
    datastore_id = var.datastore_id
    interface    = "scsi0"
    iothread     = true
    ssd          = true
    discard      = "on"
    size         = each.value.disk
    file_format  = "raw"
    file_id      = proxmox_virtual_environment_file.talos[each.value.node_name].id
  }

  boot_order = [var.disk_interface]

  network_device {
    bridge = var.bridge
    # Remember to deactivate offloading: ethtool -K vmbr1 tx off tso off gso off gro off
    model       = "virtio"
    mac_address = upper("${var.mac_prefix}:${each.value.mac_host}")
    vlan_id     = each.value.vlan_id
  }

  initialization {
    datastore_id = var.datastore_id
    ip_config {
      ipv4 {
        address = "${cidrhost(var.talos_kubernetes_cidr, each.value.hostnum)}/${var.talos_kubernetes_subnet_prefix}"
        gateway = each.value.gateway
      }
    }
  }

  efi_disk {
    datastore_id = var.datastore_id
    file_format  = "raw"
    type         = "4m"
  }

  operating_system {
    type = "l26"
  }

  serial_device {
    device = "socket"
  }
}