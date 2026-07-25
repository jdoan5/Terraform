# outputs.tf — the calculator's display. Outputs print in green at the
# bottom of the Run window after Apply: that's this calculator's screen.
#
# Outputs are stored in STATE at apply time — editing tfvars alone changes
# nothing until the next Apply (Plan shows the pending change under
# "Changes to Outputs").

output "result" {
  description = "The numeric answer"
  value       = local.result # bare expression — stays a number
}

output "equation" {
  description = "The whole calculation as a sentence"
  # ${...} interpolation stitches expressions into a string: 12 divide 4 = 3
  value = "${var.a} ${var.operation} ${var.b} = ${local.result}"
}

# Anti-pattern to recognize: value = "${local.result}" — quotes around a lone
# interpolation — is legacy 0.11 style that silently converts the number to a
# string. terraform fmt rewrites it and the IDE flags it. Interpolate only
# when genuinely building a string, as in equation above.
# (A pretty "12 / 4 = 3.00" via a symbol map + format() is a Stage 2 upgrade.)
