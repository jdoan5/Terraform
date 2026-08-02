# ---------- APIs ----------
# disable_on_destroy = false: destroying the stack shouldn't churn project
# services (the real teardown is deleting the project anyway).

resource "google_project_service" "apis" {
  for_each = toset([
    "container.googleapis.com",        # GKE
    "artifactregistry.googleapis.com", # image registry
    "aiplatform.googleapis.com",       # Vertex AI (Gemini)
    "iam.googleapis.com",
  ])
  service            = each.key
  disable_on_destroy = false
}

# ---------- Artifact Registry (the image home) ----------

resource "google_artifact_registry_repository" "ai_lab" {
  repository_id = "ai-lab"
  location      = var.region
  format        = "DOCKER"
  description   = "ai-lab agent backend images"
  depends_on    = [google_project_service.apis]
}

# ---------- GKE Autopilot cluster ----------
# Autopilot: no node pools to manage, per-pod billing, Workload Identity on by
# default. deletion_protection=false keeps `terraform destroy` a one-command
# teardown — this is a demo environment, not production.

resource "google_container_cluster" "ai_lab" {
  name                = "ai-lab"
  location            = var.region
  enable_autopilot    = true
  deletion_protection = false
  depends_on          = [google_project_service.apis]
}

# ---------- Workload Identity: the keyless auth chain ----------
# Pod → Kubernetes SA "agent" → Google SA "ai-lab-runtime" → roles/aiplatform.user
# No API key exists anywhere in this deployment.

resource "google_service_account" "runtime" {
  account_id   = "ai-lab-runtime"
  display_name = "ai-lab agent runtime (Vertex AI via Workload Identity)"
  depends_on   = [google_project_service.apis]
}

resource "google_project_iam_member" "runtime_vertex" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.runtime.email}"
}

resource "google_service_account_iam_member" "workload_identity" {
  service_account_id = google_service_account.runtime.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[ai-lab/agent]"

  # The PROJECT.svc.id.goog identity pool only exists once the first
  # WI-enabled cluster is created — without this, a fresh-project apply
  # fails with "Identity Pool does not exist".
  depends_on = [google_container_cluster.ai_lab]
}
