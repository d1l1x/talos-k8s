
# resource "random_password" "grafana_admin" {
#   length  = 24
#   special = false
# }

# NB: needs privileged PSA — node-exporter runs hostNetwork/hostPID with
# hostPath mounts on /proc and /sys, and Alloy needs hostPath access to
# /var/log/pods to tail container logs. Same requirement as local-path-storage
# and longhorn-system earlier.
resource "kubernetes_namespace" "observability" {
  depends_on = [data.talos_cluster_health.this]
  metadata {
    name = "observability"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

// see https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
resource "helm_release" "kube_prometheus_stack" {
  provider   = helm.cluster
  depends_on = [kubernetes_namespace.observability]

  name       = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.observability.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = var.kube_prometheus_stack_version

  timeout = 600
  wait    = true

  values = [
    templatefile("${path.module}/helm/kube-prometheus-stack-values.yaml", {
      storage_class    = var.monitoring_storage_class
      grafana_hostname = var.grafana_hostname
    }),
  ]

  set_sensitive = [
    {
      name  = "grafana.adminPassword"
      value = var.grafana_admin_password
    }
  ]
}

// see https://github.com/grafana/helm-charts/tree/main/charts/loki
// Depends on kube-prometheus-stack for the ServiceMonitor CRD, since
// loki's values below enable monitoring.serviceMonitor.enabled.
resource "helm_release" "loki" {
  provider   = helm.cluster
  depends_on = [helm_release.kube_prometheus_stack]

  name       = "loki"
  namespace  = kubernetes_namespace.observability.metadata[0].name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = var.loki_version

  timeout = 600
  wait    = true

  values = [
    templatefile("${path.module}/helm/loki-values.yaml", {
      storage_class = var.monitoring_storage_class
    }),
  ]
}

// see https://github.com/grafana/alloy/tree/main/operations/helm/charts/alloy
resource "helm_release" "alloy" {
  provider   = helm.cluster
  depends_on = [helm_release.loki]

  name       = "alloy"
  namespace  = kubernetes_namespace.observability.metadata[0].name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "alloy"
  version    = var.alloy_version

  timeout = 600
  wait    = true

  values = [file("${path.module}/helm/alloy-values.yaml")]
}

