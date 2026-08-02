variable "project_id" {
  description = "The dedicated GCP project for this lab (e.g. gke-lab-xxxxx). Deleting that project is the ultimate teardown."
  type        = string
}

variable "region" {
  description = "Region for the cluster, registry, and Vertex AI calls."
  type        = string
  default     = "us-central1"
}

variable "image_tag" {
  description = "Tag of the agent image to deploy (built and pushed by the runbook)."
  type        = string
  default     = "v1"
}

variable "vertex_location" {
  description = "Vertex AI location for Gemini calls. 'global' is where the Gemini-3 family is served; regional pins can 404."
  type        = string
  default     = "global"
}
