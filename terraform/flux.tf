# Install Flux during Talos bootstrap so GitOps sources can be added after the
# cluster is available. The chart includes the Flux CRDs and image controllers.
data "helm_template" "flux" {
  namespace  = "flux-system"
  name       = "flux"
  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2"
  # renovate: datasource=helm depName=flux2 registryUrl=https://fluxcd-community.github.io/helm-charts
  version      = "2.19.0"
  kube_version = var.talos_kubernetes_version
  api_versions = []
  values       = [file("${path.module}/helm/flux-values.yaml")]
}
