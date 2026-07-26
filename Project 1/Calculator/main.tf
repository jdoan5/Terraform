# main.tf — the calculator's brain. By convention main.tf holds the core
# logic (real resources will join it in Stage 4).
#
# locals are NAMED INTERMEDIATE VALUES: var.* is what the user typed,
# local.* is what we computed from it.

locals {
  # Compute all four answers in a map, then pick one by key — cleaner and
  # easier to extend than a nested ?: chain.
  #
  # GOTCHA worth learning on day one (EAGER EVALUATION): every value in this
  # map is computed, even entries never selected. Without the guard below,
  # operation="add" with b=0 would STILL crash on the divide entry with
  # 'Error: Division by zero'. The conditional (cond ? a : b) is the one
  # construct that only evaluates the branch it takes — that laziness is
  # what makes the entry safe. The validation in variables.tf separately
  # guarantees anyone ASKING for "divide" never has b=0, so local.result is
  # never null in practice.
  results = {
    add      = var.a + var.b
    subtract = var.a - var.b
    multiply = var.a * var.b
    divide   = var.b == 0 ? null : var.a / var.b
  }

  # Map lookup: square brackets pick one entry — the calculator's entire
  # 'switch statement'. The operation validation guarantees the key exists.
  result = local.results[var.operation]
}

# Division here is REAL division: 12 / 4 = 3, but 5 / 2 = 2.5 — there is no
# integer division operator (floor(a / b) arrives in Stage 2).
#
# Poke at this file interactively:  cd "Project 1/Calculator" && ../../tools/terraform console
# then try:  local.results        local.results["multiply"]        var.a + var.b
