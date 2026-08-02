# Terraform Project 2 — GKE AI Lab
# Deploys the ai-lab agent backend (github.com/jdoan5/Angular/tree/main/ai-lab)
# to a GKE Autopilot cluster with KEYLESS Vertex AI auth via Workload Identity.
#
# Auth for Terraform itself: export GOOGLE_APPLICATION_CREDENTIALS=<path to the
# terraform-admin service-account key JSON> (kept OUTSIDE any git repo).

terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# The kubernetes provider talks straight to the Autopilot cluster using the
# same Google credentials — no gcloud, no kubeconfig, no kubectl.
data "google_client_config" "current" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.ai_lab.endpoint}"
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.ai_lab.master_auth[0].cluster_ca_certificate)
}
