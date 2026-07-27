# terraform.tfvars — the calculator's input panel: the file you edit between
# runs. It is auto-loaded by exactly this name (also *.auto.tfvars; any other
# name needs -var-file=...).
#
# Precedence, highest wins:
#   -var flag  >  *.auto.tfvars  >  this file  >  variable defaults
#
# IDE trick: on a blank line, type a few letters and IntelliJ completes
# variable names straight from variables.tf (Ctrl+Space to force it).

a         = 15
b         = 5
operation = "divide" # add | subtract | multiply | divide

# Numbers stay UNQUOTED: b = "4" would be a string Terraform quietly
# converts — keep types honest.
#
# Expected after Apply:   result = 3,   equation = "12 divide 4 = 3"
#
# Try operation = "modulo", or b = 0 with "divide", then Plan — your own
# validation messages from variables.tf appear in the Run window.
#
# This file IS committed to git: the repo .gitignore ignores *.tfvars by
# default (they often hold secrets), but this repo negates that with
# "!Project */**/*.tfvars" — a calculator has nothing to hide.
