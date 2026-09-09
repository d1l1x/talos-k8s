resource "kubernetes_namespace" "local_path_storage" {
  depends_on = [data.talos_cluster_health.this]
  metadata {
    name = "local-path-storage"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

resource "helm_release" "local_path_provisioner" {
  provider   = helm.cluster
  depends_on = [kubernetes_namespace.local_path_storage]

  name       = "local-path-provisioner"
  namespace  = kubernetes_namespace.local_path_storage.metadata[0].name
  repository = "https://charts.containeroo.ch"
  chart      = "local-path-provisioner"
  version    = var.local_path_provisioner_version

  timeout = 600 # seconds — default is 300s, which is what's timing out here
  wait    = true

  values = [file("${path.module}/helm/local-path-provisioner.yaml")]
}