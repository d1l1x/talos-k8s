locals {
  #   Some custom manifests Helm can't generate
  talos_interface_name = "eth0"
  # # Convert to YAML for inlineManifests
  # cilium_external_lb_manifest = join("---\n", [for d in local.cilium_manifest_objects : yamlencode(d)])
  kube_prism_port = 7445
  common_machine_configs = [
    {
      machine = {
        # NB the install section changes are only applied after a talos upgrade
        #    (which we do not do). instead, its preferred to create a custom
        #    talos image, which is created in the installed state.
        #install = {}
        features = {
          # see https://docs.siderolabs.com/kubernetes-guides/advanced-guides/kubeprism
          # see talosctl -n $c0 read /etc/kubernetes/kubeconfig-kubelet | yq .clusters[].cluster.server
          # NB if you use a non-default CNI, you must configure it to use the
          #    https://localhost:7445 kube-apiserver endpoint.
          kubePrism = {
            enabled = true
            port    = local.kube_prism_port
          }
          # see https://docs.siderolabs.com/talos/v1.13/networking/host-dns
          hostDNS = {
            enabled              = true
            forwardKubeDNSToHost = true
          }
        }
        registries = {
          config = {
            # Gitea is served with the cluster's private cert-manager CA.
            "git.lab" = {
              tls = {
                insecureSkipVerify = true
              }
            }
          }
        }
        kubelet = {
          extraConfig = {
            # Reserve headroom for Talos/kubelet/containerd so pod scheduling
            # can't starve the node itself. ~10% of 32Gi as a starting point —
            # tune against actual `talosctl containers`/`top` usage once you
            # have real data.
            systemReserved = {
              cpu    = "250m"
              memory = "512Mi"
            }
            kubeReserved = {
              cpu    = "250m"
              memory = "512Mi"
            }
          }
        }
        # kernel = {
        #   modules = [
        #     // piraeus dependencies.
        #     {
        #       name = "drbd"
        #       parameters = [
        #         "usermode_helper=disabled",
        #       ]
        #     },
        #     {
        #       name = "drbd_transport_tcp"
        #     },
        #   ]
        # }
      }
      cluster = {
        # disable kubernetes discovery as its no longer compatible with k8s 1.32+.
        # NB we actually disable the discovery altogether, at the other discovery
        #    mechanism, service discovery, requires the public discovery service
        #    from https://discovery.talos.dev/ (or a custom and paid one running
        #    locally in your network).
        # NB without this, talosctl get members, always returns an empty set.
        # see https://docs.siderolabs.com/talos/v1.13/configure-your-talos-cluster/system-configuration/discovery
        # see https://docs.siderolabs.com/talos/v1.13/reference/configuration/v1alpha1/config#discovery
        # see https://github.com/siderolabs/talos/issues/9980
        # see https://github.com/siderolabs/talos/commit/c12b52491456d1e52204eb290d0686a317358c7c
        discovery = {
          enabled = false
          registries = {
            kubernetes = {
              disabled = true
            }
            service = {
              disabled = true
            }
          }
        }
        network = {
          cni = {
            name = "none"
          }
        }
        proxy = {
          disabled = true
        }
      }
    },
  ]
}

resource "talos_machine_secrets" "this" {
  talos_version = var.talos_version
}

data "talos_machine_configuration" "controller" {
  cluster_name       = var.talos_cluster_name
  cluster_endpoint   = "https://${var.talos_kubernetes_api_vip}:6443"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  machine_type       = "controlplane"
  talos_version      = var.talos_version
  kubernetes_version = var.talos_kubernetes_version
  config_patches = concat(
    [for c in local.common_machine_configs : yamlencode(c)],
    [
      // see https://docs.siderolabs.com/talos/v1.13/networking/advanced/vip
      // see https://docs.siderolabs.com/talos/v1.13/reference/configuration/network/layer2vipconfig
      yamlencode({
        apiVersion = "v1alpha1"
        kind       = "Layer2VIPConfig"
        link       = "${local.talos_interface_name}"
        name       = var.talos_kubernetes_api_vip
      }),
      yamlencode({
        cluster = {
          inlineManifests = [
            # {
            #   name     = "spin"
            #   contents = <<-EOF
            #     apiVersion: node.k8s.io/v1
            #     kind: RuntimeClass
            #     metadata:
            #       name: wasmtime-spin-v2
            #     handler: spin
            #     EOF
            # },
            {
              name = "cilium"
              contents = join("---\n", [
                data.helm_template.cilium.manifest,
                local.cilium_external_lb_manifest,
              ])
            },
            {
              name = "cert-manager"
              contents = join("---\n", [
                yamlencode({
                  apiVersion = "v1"
                  kind       = "Namespace"
                  metadata = {
                    name = "cert-manager"
                  }
                }),
                data.helm_template.cert_manager.manifest,
                "# Source cert-manager.tf\n${local.cert_manager_ingress_ca_manifest}",
              ])
            },
            {
              name     = "trust-manager"
              contents = data.helm_template.trust_manager.manifest
            },
            {
              name = "flux"
              contents = join("---\n", [
                yamlencode({
                  apiVersion = "v1"
                  kind       = "Namespace"
                  metadata = {
                    name = "flux-system"
                  }
                }),
                data.helm_template.flux.manifest,
              ])
            },
            # {
            #   name     = "reloader"
            #   contents = data.helm_template.reloader.manifest
            # },
            # {
            #   name     = "gitea"
            #   contents = local.gitea_manifest
            # },
            # {
            #   name = "argocd"
            #   contents = join("---\n", [
            #     yamlencode({
            #       apiVersion = "v1"
            #       kind       = "Namespace"
            #       metadata = {
            #         name = local.argocd_namespace
            #       }
            #     }),
            #     data.helm_template.argocd.manifest,
            #     "# Source argocd.tf\n${local.argocd_manifest}",
            #   ])
            # },
          ],
        },
    })],
  )
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.11.0/docs/data-sources/machine_configuration
data "talos_machine_configuration" "worker" {
  cluster_name       = var.talos_cluster_name
  cluster_endpoint   = "https://${var.talos_kubernetes_api_vip}:6443"
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  machine_type       = "worker"
  talos_version      = var.talos_version
  kubernetes_version = var.talos_kubernetes_version
  examples           = false
  docs               = false
  config_patches     = [for c in local.common_machine_configs : yamlencode(c)]
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.11.0/docs/data-sources/client_configuration
data "talos_client_configuration" "talos" {
  cluster_name         = var.talos_cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoints            = [for node in var.control_planes : cidrhost(var.talos_kubernetes_cidr, node.hostnum)]
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.11.0/docs/resources/machine_configuration_apply
resource "talos_machine_configuration_apply" "controller" {
  depends_on = [
    proxmox_virtual_environment_vm.this,
    data.talos_client_configuration.talos
  ]
  for_each                    = var.control_planes
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controller.machine_configuration
  endpoint                    = cidrhost(var.talos_kubernetes_cidr, each.value.hostnum)
  node                        = cidrhost(var.talos_kubernetes_cidr, each.value.hostnum)
  config_patches = [
    # see https://docs.siderolabs.com/talos/v1.13/reference/configuration/network/hostnameconfig
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "HostnameConfig"
      auto       = "off"
      hostname   = each.key
    }),
  ]
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.11.0/docs/resources/machine_configuration_apply
resource "talos_machine_configuration_apply" "worker" {
  depends_on = [
    proxmox_virtual_environment_vm.this,
    data.talos_client_configuration.talos
  ]
  for_each                    = var.workers
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  endpoint                    = cidrhost(var.talos_kubernetes_cidr, each.value.hostnum)
  node                        = cidrhost(var.talos_kubernetes_cidr, each.value.hostnum)
  config_patches = [
    # see https://docs.siderolabs.com/talos/v1.13/reference/configuration/network/hostnameconfig
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "HostnameConfig"
      auto       = "off"
      hostname   = each.key
    }),
  ]
}


// see https://registry.terraform.io/providers/siderolabs/talos/0.11.0/docs/resources/machine_bootstrap
resource "talos_machine_bootstrap" "talos" {
  depends_on = [
    talos_machine_configuration_apply.controller,
  ]
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = cidrhost(var.talos_kubernetes_cidr, var.control_planes[keys(var.control_planes)[0]].hostnum)
  node                 = cidrhost(var.talos_kubernetes_cidr, var.control_planes[keys(var.control_planes)[0]].hostnum)
}

// see https://registry.terraform.io/providers/siderolabs/talos/0.11.0/docs/resources/cluster_kubeconfig
resource "talos_cluster_kubeconfig" "talos" {
  depends_on = [
    talos_machine_bootstrap.talos,
  ]
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = cidrhost(var.talos_kubernetes_cidr, var.control_planes[keys(var.control_planes)[0]].hostnum)
  node                 = cidrhost(var.talos_kubernetes_cidr, var.control_planes[keys(var.control_planes)[0]].hostnum)
}

data "talos_cluster_health" "this" {
  depends_on           = [talos_cluster_kubeconfig.talos]
  client_configuration = talos_machine_secrets.this.client_configuration
  #   control_plane_nodes    = [var.talos_kubernetes_api_vip]
  #   endpoints              = [var.talos_kubernetes_api_vip]

  control_plane_nodes    = ["10.10.40.10", "10.10.40.11", "10.10.40.12"]
  endpoints              = ["10.10.40.10"]
  skip_kubernetes_checks = true # true if no CNI yet — Kubernetes-level checks (nodes Ready) will never pass without CNI
}
