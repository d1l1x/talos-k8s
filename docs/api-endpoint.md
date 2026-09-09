# Kubernetes API endpoint

This cluster exposes the Kubernetes API through a **Talos built-in Layer-2 VIP**, not a separate load-balancer VM.

## Endpoint

| Item | Value |
|------|-------|
| DNS name | `k8s-api.k8s.internal` |
| Virtual IP | `10.0.0.100` |
| Port | `6443/tcp` |
| Cluster endpoint URL | `https://k8s-api.k8s.internal:6443` |
| kubeconfig (lab default) | `https://10.0.0.100:6443` (VIP IP — avoids client DNS issues) |

Clients should use this DNS name **or** the VIP. Never point the primary Kubernetes API endpoint at a single control-plane node IP (`10.0.0.111`–`113`).

## How traffic reaches the control plane

Talos runs a VIP on the control-plane nodes (`k8s-cp-01` … `k8s-cp-03`). Exactly one healthy control-plane node owns `10.0.0.100` at a time (etcd-backed election + gratuitous ARP). Traffic to `:6443` on the VIP is handled by the kube-apiserver on the VIP holder.

```
Client / worker
      |
      v
k8s-api.k8s.internal  -->  10.0.0.100:6443  (VIP)
      |
      +--> k8s-cp-01 (10.0.0.111)  \  one holder
      +--> k8s-cp-02 (10.0.0.112)  |  at a time
      +--> k8s-cp-03 (10.0.0.113)  /
```

## Prerequisites (before bootstrap)

1. **Reserve** `10.0.0.100` — do not assign it to any other host, DHCP pool, or VIP.
2. **DNS (e.g. OPNsense Unbound host override)** — create an A record:
   ```
   Host:   k8s-api
   Domain: k8s.internal
   IP:     10.0.0.100
   ```
   Equivalent zone form:
   ```
   k8s-api.k8s.internal.  IN  A  10.0.0.100
   ```
   Verify with both:
   ```bash
   dig +short k8s-api.k8s.internal @10.0.0.1
   dig +short k8s-api.k8s.internal          # must work via your default resolver too
   ```
3. **Layer 2** — all three control-plane VMs must share the same broadcast domain (`vmbr0` / `10.0.0.0/24`). Talos VIP does not work across routed subnets.
4. **Talos config** — control-plane machine configs set:
   - `cluster.controlPlane.endpoint: https://k8s-api.k8s.internal:6443`
   - VIP `10.0.0.100` on the primary NIC (Proxmox VirtIO is typically `ens18`)

## Operator access (Talos API)

Use **individual node IPs** for `talosctl` (`apply-config`, `bootstrap`, recovery):

- `10.0.0.111` (`k8s-cp-01`)
- `10.0.0.112` (`k8s-cp-02`)
- `10.0.0.113` (`k8s-cp-03`)

Do **not** put the VIP in `talosconfig` endpoints. The VIP depends on etcd; if etcd is unhealthy you would lose Talos API access when you need it most.

## Availability relative to bootstrap

- The VIP address and DNS name are reserved and configured as the cluster endpoint **before** bootstrap.
- The VIP becomes **live** after etcd is up (post-bootstrap on `k8s-cp-01`). Until then, `no route to host` to `10.0.0.100` is expected.
- `./talos/apply-and-bootstrap.sh` rewrites kubeconfig to `https://10.0.0.100:6443` so operator machines do not depend on DNS for `kubectl`.
