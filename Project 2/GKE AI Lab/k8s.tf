# ---------- Kubernetes objects (applied via the kubernetes provider — no kubectl) ----------

resource "kubernetes_namespace_v1" "ai_lab" {
  metadata {
    name = "ai-lab"
  }
}

# The Kubernetes half of Workload Identity: this SA is annotated with the
# Google SA it impersonates. Pods running as it get Vertex access via the
# metadata server — the SDK's ADC path — with zero mounted secrets.
resource "kubernetes_service_account_v1" "agent" {
  metadata {
    name      = "agent"
    namespace = kubernetes_namespace_v1.ai_lab.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.runtime.email
    }
  }
}

resource "kubernetes_deployment_v1" "agent" {
  metadata {
    name      = "ai-lab-agent"
    namespace = kubernetes_namespace_v1.ai_lab.metadata[0].name
    labels    = { app = "ai-lab-agent" }
  }

  spec {
    replicas = 1
    selector {
      match_labels = { app = "ai-lab-agent" }
    }
    template {
      metadata {
        labels = { app = "ai-lab-agent" }
      }
      spec {
        service_account_name = kubernetes_service_account_v1.agent.metadata[0].name

        container {
          name  = "agent"
          image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ai_lab.repository_id}/agent:${var.image_tag}"

          port {
            container_port = 8080
          }

          # Keyless: ADC via Workload Identity. No GEMINI_API_KEY anywhere.
          env {
            name  = "GEMINI_AUTH"
            value = "adc"
          }
          env {
            name  = "GOOGLE_CLOUD_PROJECT"
            value = var.project_id
          }
          env {
            name  = "GOOGLE_CLOUD_LOCATION"
            value = var.vertex_location
          }

          resources {
            requests = {
              cpu    = "250m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 15
          }
          readiness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
            initial_delay_seconds = 3
            period_seconds        = 10
          }
        }
      }
    }
  }

  depends_on = [google_service_account_iam_member.workload_identity]
}

# Public entrypoint for the demo day: a plain L4 LoadBalancer (no domain, no
# certs — this is a screenshot-and-teardown environment).
resource "kubernetes_service_v1" "agent" {
  metadata {
    name      = "ai-lab-agent"
    namespace = kubernetes_namespace_v1.ai_lab.metadata[0].name
  }
  spec {
    selector = { app = "ai-lab-agent" }
    type     = "LoadBalancer"
    port {
      port        = 80
      target_port = 8080
    }
  }
}
