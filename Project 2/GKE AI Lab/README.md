# Terraform Project 2 — GKE AI Lab

Deploys the [ai-lab agent backend](https://github.com/jdoan5/Angular/tree/main/ai-lab)
to **GKE Autopilot** with **keyless Vertex AI auth (Workload Identity)** —
the same agents that run on Vercel, redeployed the way an enterprise would:

```
Pod  →  KSA "agent"  →  GSA "ai-lab-runtime"  →  roles/aiplatform.user  →  Gemini
        (Kubernetes)     (Workload Identity)       (no API key anywhere)
```

Everything is Terraform (`google` + `kubernetes` providers). No gcloud, no
kubectl — the only CLI tools are `terraform` (repo-local, in `../../tools/`)
and `docker`.

> **Cost model:** this is a build → demo → screenshot → **destroy same day**
> environment. Running cost ≈ $2–5/day (Autopilot pod + L4 load balancer).
> The teardown section is not optional.

## 0. One-time bootstrap (console UI, ~5 minutes)

1. Create a **new project** (e.g. `gke-lab`) — console → project picker → New project.
2. **Link billing** to it (Billing → Account management → link project).
3. Create the Terraform identity: IAM & Admin → Service Accounts →
   **Create service account** `terraform-admin` → grant roles **Editor**,
   **Service Account Admin**, and **Project IAM Admin** → Done →
   Keys tab → **Add key → JSON** → the file downloads.
4. Move the key **outside every git repo**, e.g. `~/keys/gke-lab-terraform.json`.

## 1. Build & push the image (from `Angular/ai-lab`)

```bash
cd ~/Documents/GitHub/Angular/ai-lab
export PROJECT_ID=<your-gke-lab-project-id>
export REGION=us-central1

# GKE nodes are amd64; Apple Silicon builds arm64 by default — target explicitly:
docker build --platform linux/amd64 -t $REGION-docker.pkg.dev/$PROJECT_ID/ai-lab/agent:v1 .

# Registry must exist first (created by Terraform):
cd "$HOME/Documents/GitHub/Terraform/Project 2/GKE AI Lab"
export GOOGLE_APPLICATION_CREDENTIALS=~/keys/gke-lab-terraform.json
../../tools/terraform init
../../tools/terraform apply -target=google_artifact_registry_repository.ai_lab -var project_id=$PROJECT_ID

# Docker auth to Artifact Registry using the same key (no gcloud):
cat $GOOGLE_APPLICATION_CREDENTIALS | docker login -u _json_key --password-stdin https://$REGION-docker.pkg.dev
docker push $REGION-docker.pkg.dev/$PROJECT_ID/ai-lab/agent:v1
```

## 2. Deploy everything

```bash
../../tools/terraform apply -var project_id=$PROJECT_ID
# cluster ~5-8 min; then:
../../tools/terraform output load_balancer_ip
```

## 3. Verify (the screenshot moment)

```bash
IP=$(../../tools/terraform output -raw load_balancer_ip)
curl http://$IP/healthz
curl http://$IP/api/agent          # expect {"ok":true,"hasKey":true,"auth":"adc"}
curl -N -X POST http://$IP/api/agent -H 'content-type: application/json' \
  -d '{"agent":"reviews","message":"How many apps do I have?"}'
```

IAM propagation can take up to ~1 minute after apply — if the first agent call
403s, wait and retry.

`"auth":"adc"` is the proof of the whole exercise: Gemini answering with **no
API key in the container, the manifests, or the Terraform**.

Console screenshots worth taking: GKE → Workloads (the running pod), the
Service with its external IP, IAM → the `ai-lab-runtime` SA, Artifact Registry.

## 4. TEARDOWN — same day, not optional

```bash
../../tools/terraform destroy -var project_id=$PROJECT_ID

# The docker login in step 1 stored the ENTIRE key JSON as the registry
# password — clean both the credential store and the key itself:
docker logout https://$REGION-docker.pkg.dev
rm ~/keys/gke-lab-terraform.json
unset GOOGLE_APPLICATION_CREDENTIALS
```

Then belt-and-suspenders: console → IAM & Admin → Settings → **Shut down
project** (deletes anything a destroy could have missed, including the
`terraform-admin` key's power — the billing meter for this project ends here).

> **If the project/cluster was deleted before `terraform destroy`** (e.g. you
> shut the project down first), a later plan/destroy will hang refreshing the
> four `kubernetes_*` resources against the dead endpoint. Recover with:
> `terraform state rm $(terraform state list | grep kubernetes_)`

## Files

| File | What it builds |
|---|---|
| `versions.tf` | providers; kubernetes provider auths via the google provider (no kubeconfig) |
| `variables.tf` | `project_id` (required), `region`, `image_tag` |
| `main.tf` | APIs, Artifact Registry, Autopilot cluster, GSA + Workload Identity binding |
| `k8s.tf` | namespace, annotated KSA, deployment (ADC env, probes, limits), LoadBalancer |
| `outputs.tf` | registry/image URLs, cluster name, external IP |
