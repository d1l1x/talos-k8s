# talos-k8s

Highly available Kubernetes on a three-node Proxmox cluster using **Talos Linux**, provisioned with **Terraform** ([bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest)).

| Layer | Owns |
|-------|------|
| Proxmox + Terraform | VM lifecycle, CPU, memory, disks, NICs, placement |
| Talos | OS config, node roles, etcd/Kubernetes membership, upgrades |
| Kubernetes | Workloads, services, ingress, applications |


## Cluster layout

| Role | Name | Proxmox node | IP |
|------|------|--------------|-----|
| API VIP / DNS | `k8s-api.k8s.internal` | — | `10.0.0.100:6443` |
| Control plane | `k8s-cp-01` | `pve01` | `10.0.0.111` |
| Control plane | `k8s-cp-02` | `pve02` | `10.0.0.112` |
| Control plane | `k8s-cp-03` | `pve03` | `10.0.0.113` |
| Worker | `k8s-worker-01` | `pve01` | `10.0.0.114` |
| Worker | `k8s-worker-02` | `pve02` | `10.0.0.115` |
| Worker | `k8s-worker-03` | `pve03` | `10.0.0.116` |

VM IDs default to `111`–`116`. All values are overridable in `terraform/terraform.tfvars`.

Kubernetes API endpoint design: [docs/api-endpoint.md](docs/api-endpoint.md).

## Repository layout

```
├── docs/api-endpoint.md          # VIP / DNS documentation (phase 2)
├── terraform/                    # Proxmox VM provisioning (phase 3)
│   ├── modules/proxmox-vm/       # reusable bpg VM module
│   ├── control-planes.tf
│   ├── workers.tf
│   └── terraform.tfvars.example
├── talos/                        # machine config + bootstrap (phase 4)
│   ├── patches/                  # common / controlplane / worker
│   ├── generate.sh
│   └── apply-and-bootstrap.sh
└── scripts/bootstrap-cluster.sh  # optional end-to-end wrapper
```

## Prerequisites

1. **Tools:** Terraform >= 1.5 (or OpenTofu >= 1.6), [`talosctl`](https://www.talos.dev/latest/talos-guides/install/talosctl/), `kubectl`
2. **Proxmox:** three-node cluster (`pve01`–`pve03`), bridge `vmbr0`, datastore `proxmox-share-lvm`
3. **API token:** create a token and export (see `.env.example`):
   ```bash
   export PROXMOX_VE_ENDPOINT='https://10.0.0.5:8006/'
   export PROXMOX_VE_API_TOKEN='user@pam!tokenid=uuid-secret'
   export PROXMOX_VE_INSECURE=true
   ```
4. **Talos ISO:** upload a metal ISO to Proxmox `local` storage. Prefer the Image Factory ISO with `ip=ens18:dhcp` so maintenance mode gets networking without F3 — see [docs/maintenance-network.md](docs/maintenance-network.md) and `./scripts/fetch-talos-iso.sh`
5. **DNS / hosts:** `k8s-api.k8s.internal` → `10.0.0.100` (see [docs/api-endpoint.md](docs/api-endpoint.md)). **Do not use `.local`** — macOS treats it as mDNS.
6. **DHCP reservations (recommended):** map each Terraform MAC output to the planned IP so maintenance-mode nodes are reachable before `apply-config`

## Phase 2 — API endpoint

No separate load-balancer VMs. The stable endpoint is a **Talos Layer-2 VIP**:

- DNS: `k8s-api.k8s.internal`
- VIP: `10.0.0.100:6443`
- Backends: `k8s-cp-01` … `k8s-cp-03` (VIP holder elected via etcd)

Reserve the VIP and publish DNS **before** bootstrap. Use **node IPs** for all `talosctl` operations — never the VIP in `talosconfig`.

## Phase 3 — Provision VMs

```bash
cp .env.example .env   # fill PROXMOX_VE_*
set -a && source .env && set +a

cp terraform/terraform.tfvars.example terraform/terraform.tfvars
cd terraform
terraform init
terraform validate
terraform plan
terraform apply
```

Expected result: six VMs booted from the Talos ISO (maintenance mode). Terraform outputs include names, VM IDs, planned IPs, MACs, Proxmox nodes, and `kubernetes_api_endpoint`.

Create DHCP reservations from the MAC output before continuing, unless the nodes already have the planned addresses.

## Phase 4 — Talos config and bootstrap

```bash
# From repo root
./talos/generate.sh
# Creates (gitignored): secrets.yaml, controlplane.yaml, worker.yaml,
# talosconfig, rendered/k8s-*.yaml

./talos/apply-and-bootstrap.sh
# apply-config to all six nodes → bootstrap once on k8s-cp-01 →
# wait for health → write ./kubeconfig
```

Optional one-shot (generate + terraform apply + bootstrap):

```bash
./scripts/bootstrap-cluster.sh
```

### What the patches do

| File | Purpose |
|------|---------|
| `talos/patches/common.yaml` | Install disk, cluster endpoint `https://k8s-api.k8s.internal:6443` |
| `talos/patches/controlplane.yaml` | VIP `10.0.0.100` on control planes |
| `talos/patches/worker.yaml` | Worker network defaults |
| Per-node render | Static IP/gateway (+ VIP on CPs) and `HostnameConfig` (`auto: off`, hostname = node name). Do not use legacy `machine.network.hostname` (conflicts on Talos ≥1.12). |

### Verify

```bash
export KUBECONFIG=$PWD/kubeconfig
export TALOSCONFIG=$PWD/talos/talosconfig

kubectl get nodes -o wide
kubectl get pods -A
talosctl -n 10.0.0.111 health
talosctl -n 10.0.0.111,10.0.0.112,10.0.0.113 get members
```

Expected nodes (all `Ready`):

- `k8s-cp-01`, `k8s-cp-02`, `k8s-cp-03`
- `k8s-worker-01`, `k8s-worker-02`, `k8s-worker-03`


## Notes

- Interface name defaults to `ens18` (Proxmox VirtIO) and install disk to `/dev/sda`. Adjust patches if your guests differ (`talosctl get links` / `talosctl get disks` in maintenance mode).
- Bootstrap must run **exactly once** on `k8s-cp-01`. Re-running `apply-and-bootstrap.sh` treats a failed second bootstrap as already done and continues.
- The VIP becomes live after etcd is healthy. Bootstrap rewrites kubeconfig to `https://10.0.0.100:6443` so macOS clients are not blocked by `.local` mDNS.
