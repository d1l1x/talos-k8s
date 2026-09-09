data "talos_cluster_health" "kubernetes" {
  depends_on           = [talos_machine_configuration_apply.controller, talos_machine_configuration_apply.worker]
  client_configuration = talos_machine_secrets.this.client_configuration
  # control_plane_nodes    = ["10.10.40.10", "10.10.40.11", "10.10.40.12"]
  # worker_nodes            = ["10.10.40.20", "10.10.40.21", "10.10.40.22"]
  control_plane_nodes    = [for node in var.control_planes : cidrhost(var.talos_kubernetes_cidr, node.hostnum)]
  worker_nodes           = [for node in var.workers : cidrhost(var.talos_kubernetes_cidr, node.hostnum)]
  endpoints              = ["10.10.40.10"]
  skip_kubernetes_checks = false # now wait for real node/pod readiness
}



resource "kubernetes_namespace" "democratic_csi" {
  depends_on = [data.talos_cluster_health.kubernetes]
  metadata {
    name = "democratic-csi"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

// see https://github.com/democratic-csi/charts
resource "helm_release" "democratic_csi_iscsi" {
  provider   = helm.cluster
  depends_on = [kubernetes_namespace.democratic_csi]

  name       = "zfs-iscsi"
  namespace  = kubernetes_namespace.democratic_csi.metadata[0].name
  repository = "https://democratic-csi.github.io/charts/"
  chart      = "democratic-csi"
  version    = var.democratic_csi_version

  timeout = 600
  wait    = true

  values = [
    templatefile("${path.module}/helm/democratic-csi-values.yaml", {
      truenas_host           = var.truenas_host
      truenas_iscsi_portal   = var.truenas_iscsi_portal
      truenas_dataset_parent = var.truenas_dataset_parent
    }),
  ]

  set_sensitive = [
    {
      name  = "driver.config.httpConnection.apiKey"
      value = var.truenas_api_key
    }
  ]
}
