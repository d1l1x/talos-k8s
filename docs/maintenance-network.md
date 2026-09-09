# Maintenance-mode networking (Proxmox + Talos ISO)

## Symptom

After `terraform apply`, a Talos VM boots the metal ISO into **maintenance mode** with an **empty network config**. `talosctl apply-config` cannot reach the node (`10.0.0.111`, etc.) until you open the Proxmox console and:

1. Press **F3** (network)
2. Select **ens18**
3. Select **DHCP**
4. Save

Then the node gets an address (ideally your DHCP reservation) and bootstrap can continue.

This is a **pre-apply** problem: machine config is not loaded yet, so Terraform/Talos YAML static IPs do not help until the node is reachable.

## Why it happens

On Proxmox VirtIO, the NIC is typically `ens18`. Stock Talos ISO tries DHCP on interfaces automatically, but in some lab setups (timing, bridge, firewall, interface naming) maintenance mode never binds an address until the dashboard explicitly enables DHCP on `ens18`.

Official Talos Proxmox docs cover the same class of issue with GRUB `ip=` kernel parameters when DHCP does not appear.

## Preferred fix: Image Factory ISO with `ip=ens18:dhcp`

Bake early DHCP into the ISO kernel cmdline so F3 is unnecessary.

```bash
# Register schematic + print download URL
./scripts/fetch-talos-iso.sh

# Or also download locally:
DOWNLOAD=1 ./scripts/fetch-talos-iso.sh
```

Then:

1. Upload the ISO to Proxmox `local` storage (e.g. `metal-amd64-ens18-dhcp.iso`).
2. Set in `terraform/terraform.tfvars`:
   ```hcl
   iso_file_id = "local:iso/metal-amd64-ens18-dhcp.iso"
   ```
3. Recreate or update VMs so they boot that ISO (`terraform apply`).
4. Confirm DHCP reservations for the Terraform MAC → planned IPs (`10.0.0.111`–`116`).
5. Run `./talos/generate.sh` and `./talos/apply-and-bootstrap.sh`.

Schematic source: [`talos/schematic.yaml`](../talos/schematic.yaml).

After install, day-2 networking comes from **machine config** (static IP + VIP on control planes), not from the ISO kernel args.

## Manual alternatives (no custom ISO)

### Dashboard (what you already do)

F3 → `ens18` → DHCP → save.

### GRUB one-shot

At the ISO boot menu press `e`, append to the linux line:

```text
ip=ens18:dhcp
```

or static (example for cp-01):

```text
ip=10.0.0.111::10.0.0.1:255.255.255.0::ens18:off
```

Then Ctrl-x / F10.

## After apply

Machine configs use **static** addressing on `ens18` (`dhcp: false`) plus OPNsense as nameserver (`10.0.0.1`). Control planes also carry VIP `10.0.0.100`.

## Checklist

- [ ] OPNsense DHCP pool / reservations cover the VM MACs
- [ ] Proxmox bridge `vmbr0` is up; VM firewall allows DHCP (UDP 67/68) if enabled
- [ ] Serial console enabled (already in Terraform module) for early boot logs
- [ ] Custom ISO with `ip=ens18:dhcp` **or** F3/GRUB workaround once per node before apply
