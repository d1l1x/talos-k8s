locals {
  # Bootstrap chain:
  #   1. A self-signed ClusterIssuer, used ONLY to mint the root CA cert below.
  #   2. A root CA Certificate, signed by (1), stored as a Secret.
  #   3. A "real" ClusterIssuer (ca-issuer) backed by that Secret, which is
  #      what your Ingress/Certificate resources should actually reference.
  #
  # This gives you a private CA you can later trust-distribute (see
  # trust-manager, still commented out in talos.tf) instead of hitting
  # Let's Encrypt for internal-only hostnames.
  cert_manager_ingress_ca_manifest = join("---\n", [
    yamlencode({
      apiVersion = "cert-manager.io/v1"
      kind       = "ClusterIssuer"
      metadata = {
        name = "selfsigned-bootstrap"
      }
      spec = {
        selfSigned = {}
      }
    }),
    yamlencode({
      apiVersion = "cert-manager.io/v1"
      kind       = "Certificate"
      metadata = {
        name      = "ca-root"
        namespace = "cert-manager"
      }
      spec = {
        isCA       = true
        commonName = "${var.talos_cluster_name}-root-ca"
        secretName = "ca-root-secret"
        duration   = "87600h" # 10y
        privateKey = {
          algorithm = "ECDSA"
          size      = 256
        }
        issuerRef = {
          name  = "selfsigned-bootstrap"
          kind  = "ClusterIssuer"
          group = "cert-manager.io"
        }
      }
    }),
    yamlencode({
      apiVersion = "cert-manager.io/v1"
      kind       = "ClusterIssuer"
      metadata = {
        name = "ca-issuer"
      }
      spec = {
        ca = {
          secretName = "ca-root-secret"
        }
      }
    }),
  ])
}

# NB YOU CANNOT INSTALL MULTIPLE INSTANCES OF CERT-MANAGER IN A CLUSTER.
# see https://artifacthub.io/packages/helm/cert-manager/cert-manager
# see https://github.com/cert-manager/cert-manager/tree/master/deploy/charts/cert-manager
# see https://cert-manager.io/docs/installation/supported-releases/
# see https://cert-manager.io/docs/configuration/selfsigned/#bootstrapping-ca-issuers
# see https://cert-manager.io/docs/usage/ingress/
# see https://registry.terraform.io/providers/hashicorp/helm/latest/docs/data-sources/template
data "helm_template" "cert_manager" {
  namespace  = "cert-manager"
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  # renovate: datasource=helm depName=cert-manager registryUrl=https://charts.jetstack.io
  version      = "1.21.1"
  kube_version = var.talos_kubernetes_version
  api_versions = []
  # NB installCRDs is generally not recommended, BUT since this
  #    is a development cluster we YOLO it.
  set = [
    {
      name  = "installCRDs"
      value = "true"
    }
  ]
}