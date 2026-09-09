terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.111"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~>0.11.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~>3.2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
  }
}

# Auth: set PROXMOX_VE_ENDPOINT and PROXMOX_VE_API_TOKEN in the environment
# (see ../.env.example). Optional overrides via variables / tfvars.
provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = var.proxmox_insecure
  ssh {
    agent       = true
    username    = "root"
    private_key = file("${var.ssh_private_key_path}")
    dynamic "node" {
      for_each = var.proxmox_pve_node_names
      content {
        name    = node.value
        address = "${node.value}.${var.pve_domain}"
      }
    }
  }
}

provider "kubernetes" {
  host                   = "https://${var.talos_kubernetes_api_vip}:6443"
  cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.talos.kubernetes_client_configuration.ca_certificate)
  client_certificate     = base64decode(talos_cluster_kubeconfig.talos.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(talos_cluster_kubeconfig.talos.kubernetes_client_configuration.client_key)
}

# Used only by helm_template data sources — renders charts locally,
# never talks to a live cluster, so it has no dependency on kubeconfig.
provider "helm" {
}

provider "helm" {
  alias = "cluster"
  kubernetes = {
    host                   = "https://${var.talos_kubernetes_api_vip}:6443"
    cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.talos.kubernetes_client_configuration.ca_certificate)
    client_certificate     = base64decode(talos_cluster_kubeconfig.talos.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(talos_cluster_kubeconfig.talos.kubernetes_client_configuration.client_key)
  }
}