output "registry_repo" {
  description = "Push target for the agent image."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ai_lab.repository_id}"
}

output "image_url" {
  description = "The exact image reference the deployment runs."
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.ai_lab.repository_id}/agent:${var.image_tag}"
}

output "cluster_name" {
  value = google_container_cluster.ai_lab.name
}

output "load_balancer_ip" {
  description = "Public IP of the agent service (may take ~1 min to populate after apply)."
  value       = try(kubernetes_service_v1.agent.status[0].load_balancer[0].ingress[0].ip, "(pending — re-run: terraform refresh)")
}
