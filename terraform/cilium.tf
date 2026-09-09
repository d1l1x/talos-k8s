locals {
  cilium_external_lb_manifests = [
    # Load Balancer to expose services on my LAN
    {
      apiVersion = "cilium.io/v2alpha1"
      kind       = "CiliumL2AnnouncementPolicy"
      metadata = {
        name = "external"
      }
      spec = {
        loadBalancerIPs = true
        externalIPs     = true
        interfaces      = [local.talos_interface_name]
        nodeSelector = {
          matchExpressions = [
            {
              key      = "node-role.kubernetes.io/control-plane"
              operator = "DoesNotExist"
            }
          ]
        }
      }
    },
    # IP pool for the load balancer
    {
      apiVersion = "cilium.io/v2alpha1"
      kind       = "CiliumLoadBalancerIPPool"
      metadata = {
        name = "external"
      }
      spec = {
        blocks = [
          {
            start = cidrhost(var.talos_kubernetes_cidr, 5)
            stop  = cidrhost(var.talos_kubernetes_cidr, 9)
          }
        ]
      }
    }
  ]
  cilium_external_lb_manifest = join("---\n", [for d in local.cilium_external_lb_manifests : yamlencode(d)])
}

# The magic: Helm generates the full Cilium manifest
data "helm_template" "cilium" {
  namespace    = "kube-system"
  name         = "cilium"
  repository   = "https://helm.cilium.io"
  chart        = "cilium"
  version      = "1.20.0"
  kube_version = var.talos_kubernetes_version
  api_versions = []
  values       = [file("${path.module}/helm/cilium-values.yaml")]
}

# resource "helm_release" "cilium" {
#   depends_on = [data.talos_cluster_health.this]
#   namespace  = "kube-system"
#   name       = "cilium"
#   repository = "https://helm.cilium.io"
#   chart      = "cilium"
#   version    = "1.20.0"
#   values     = [file("${path.module}/helm/cilium-values.yaml")]
#   timeout    = 300
#   wait       = false
# }

# // see https://docs.siderolabs.com/kubernetes-guides/cni/deploying-cilium#method-4%3A-helm-manifests-inline-install
# // see https://docs.cilium.io/en/stable/network/servicemesh/ingress/
# // see https://docs.cilium.io/en/stable/gettingstarted/hubble_setup/
# // see https://docs.cilium.io/en/stable/gettingstarted/hubble/
# // see https://docs.cilium.io/en/stable/helm-reference/#helm-reference
# // see https://github.com/cilium/cilium/releases
# // see https://github.com/cilium/cilium/tree/v1.19.4/install/kubernetes/cilium
# // see https://registry.terraform.io/providers/hashicorp/helm/latest/docs/data-sources/template
# data "helm_template" "cilium" {
#   namespace  = "kube-system"
#   name       = "cilium"
#   repository = "https://helm.cilium.io"
#   chart      = "cilium"
#   # renovate: datasource=helm depName=cilium registryUrl=https://helm.cilium.io
#   version      = "1.19.4"
#   kube_version = var.talos_kubernetes_version
#   api_versions = []
#   set = [
#     {
#       name  = "ipam.mode"
#       value = "kubernetes"
#     },
#     {
#       name  = "securityContext.capabilities.ciliumAgent"
#       value = "{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}"
#     },
#     {
#       name  = "securityContext.capabilities.cleanCiliumState"
#       value = "{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}"
#     },
#     {
#       name  = "cgroup.autoMount.enabled"
#       value = "false"
#     },
#     {
#       name  = "cgroup.hostRoot"
#       value = "/sys/fs/cgroup"
#     },
#     {
#       name  = "k8sServiceHost"
#       value = "localhost"
#     },
#     {
#       name  = "k8sServicePort"
#       value = local.kube_prism_port
#     },
#     {
#       name  = "kubeProxyReplacement"
#       value = "true"
#     },
#     {
#       name  = "l2announcements.enabled"
#       value = "true"
#     },
#     {
#       name  = "devices"
#       value = "${local.talos_interface_name}"
#     },
#     {
#       name  = "ingressController.enabled"
#       value = "true"
#     },
#     {
#       name  = "ingressController.default"
#       value = "true"
#     },
#     {
#       name  = "ingressController.loadbalancerMode"
#       value = "shared"
#     },
#     {
#       name  = "ingressController.enforceHttps"
#       value = "false"
#     },
#     {
#       name  = "envoy.enabled"
#       value = "true"
#     },
#     {
#       name  = "hubble.relay.enabled"
#       value = "true"
#     },
#     {
#       name  = "hubble.ui.enabled"
#       value = "true"
#     }
#   ]
# }