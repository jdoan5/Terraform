# variables.tf — the calculator's keyboard: every value the user can type in.
#
# variables are INPUTS (var.*). Computed values live in locals (local.*, see
# main.tf). Outputs are the display (outputs.tf).
#
# A note on the two `validation` blocks below: validation rules are plan-time
# checks about RAW INPUTS, attached to the variable at fault. Since Terraform
# 1.9 a validation condition may reference OTHER variables too (see var.b),
# so even cross-input rules belong here. (Preconditions — the other guard
# mechanism — are for DERIVED values, and arrive in Stage 4 where one exists.)

variable "a" {
  description = "First number in the calculation"
  type        = number # Terraform has ONE number type: covers ints and fractions
  default     = 12     # a default makes the variable optional; tfvars overrides it
}

variable "b" {
  description = "Second number in the calculation"
  type        = number
  default     = 4

  validation {
    # CROSS-VARIABLE rule (Terraform 1.9+): this guard lives on the variable
    # at fault (b) and fails at plan time, pinned to this input.
    condition     = !(var.operation == "divide" && var.b == 0)
    error_message = "Cannot divide by zero: operation is \"divide\" but b is 0. Pick a non-zero b or a different operation."
  }
}

variable "operation" {
  description = "What to do: add, subtract, multiply, or divide"
  type        = string
  default     = "add"

  validation {
    # Single-input rule: contains(list, value) returns a bool.
    condition     = contains(["add", "subtract", "multiply", "divide"], var.operation)
    error_message = "operation must be one of: add, subtract, multiply, divide."
  }
}
