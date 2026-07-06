# versions.tf — Terraform settings block, alone in its own file by convention.
#
# IDE tip: the gutter icon next to the terraform {} block below runs `terraform init`.

terraform {
  # "~> 1.15.0" is the PESSIMISTIC version constraint: any 1.15.x, never 1.16.
  # We pin to the binary we actually run (../tools/terraform = 1.15.7).
  required_version = "~> 1.15.0"

  # Note what is MISSING here: no required_providers, no credentials.
  # Variables, locals, and outputs are pure language features — Terraform can
  # calculate without creating anything, so `init` is instant and works
  # offline. Providers (hashicorp/local, hashicorp/random) arrive in Stage 4,
  # and IntelliJ will prompt to re-run init when they do.
}
