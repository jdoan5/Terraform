# Terraform Calculator

Learn the Terraform language (HCL) by building a calculator — **no cloud, no cost, 100% local.**

Same staged-build pattern as the Bookmark API project: each stage adds one cluster of
concepts, every stage is runnable end-to-end, and this table tracks progress.

## Stages

| Stage | Adds | Status |
|-------|------|--------|
| 1 | Working calculator — variables, validation, locals, outputs | ✅ Done |
| 2 | Built-in functions (`pow`, `floor`, `format`), `try`/`can`, console fluency | ⬜ Not started |
| 3 | Batch calculator — collections, `for` expressions, `optional()` | ⬜ Not started |
| 4 | First real resources — `local_file` + `random`, `for_each`, preconditions, destroy | ⬜ Not started |
| 5 | Modules — extract the calculator into a reusable unit | ⬜ Not started |
| 6 | State & workspaces — what Terraform actually remembers | ⬜ Not started |

## One-time IntelliJ setup

Already done on this machine (plugin installed, executable path configured, run
configurations created) — restart IntelliJ once and everything appears. For a fresh
machine, the checklist is:

1. **Open the repo root** — `/Users/jdoan/Documents/GitHub/Terraform` — as the IntelliJ
   project (not `Project 1/Calculator/`). All projects live side by side.
2. Install the **Terraform and HCL** plugin (Settings → Plugins → Marketplace — it is
   *not* bundled with IDEA) and restart the IDE.
3. Point it at the repo-local binary: **Settings → search "terraform" → Tools →
   Terraform and OpenTofu →** set the executable path to
   `/Users/jdoan/Documents/GitHub/Terraform/tools/terraform`
   and confirm it detects **Terraform v1.15.7**.

> **Fresh clone?** `tools/` is gitignored (the binary is ~90 MB). Re-download
> *terraform 1.15.7 darwin_arm64* from `releases.hashicorp.com/terraform/1.15.7`,
> unzip into `tools/`. HashiCorp builds are notarized; if Gatekeeper objects,
> approve it in System Settings → Privacy & Security.

## How to run

**Run configurations (the terminal replacement):**
Ready-made configs are checked in under `.idea/runConfigurations/` — pick
**Calculator Init / Validate / Plan / Apply** from the dropdown next to the Run ▶
button (Destroy joins in Stage 4). To create one by hand:
Run → Edit Configurations → **+** → Terraform.

- **Working directory** = `.../Terraform/Project 1/Calculator` — this is the #1 trap:
  Terraform operates on the working directory. Pointed at the repo root, Plan
  fails with "no configuration files".
- Tick **Store as project file** so hand-made configs land in `.idea/runConfigurations/`.
- Shortcut: the gutter icon next to the `terraform {}` block in `versions.tf` runs init.

**Terminal fallback** (and how `console` runs) — always from `Project 1/Calculator/`:

```
cd "Project 1/Calculator"
../../tools/terraform init
../../tools/terraform apply
```

**The everyday loop:** edit `.tf` / `.tfvars` → reformat with **Opt+Cmd+L** (matches
`terraform fmt`) → **Validate** → **Plan** (read it!) → **Apply**, type `yes` in the Run
console → outputs print in green at the bottom.

Typing `yes` is on purpose — reading the plan before approving is the core Terraform
habit. Add `-auto-approve` to the Apply config's arguments only once that's second nature.

## Try it now

1. Run **Init** — prints `Terraform has been initialized!` instantly and offline
   (Stage 1 uses zero providers — the language alone can calculate).
2. Run **Apply**, type `yes`. The run ends with:

   ```
   equation = "12 divide 4 = 3"
   result   = 3
   ```

3. Edit `terraform.tfvars`, re-Apply, watch the outputs change. The whole loop is
   seconds long.

## See the guards work

Both guards fail **at plan time** with your own error messages. Add these to the Plan
run config's *Program arguments* (or run in the terminal):

| Arguments | Rejected by |
|---|---|
| `-var operation=modulo` | the `contains(...)` validation on `operation` |
| `-var operation=divide -var b=0` | the cross-variable validation on `b` |

## terraform console — the expression playground

```
cd "Project 1/Calculator"
../../tools/terraform console
```

Try: `local.results` · `local.results["multiply"]` · `var.a + var.b` — then `q` to quit.
Console auto-loads `terraform.tfvars` and needs the folder init'ed once.

## Stage 1 exercises

- [ ] Add a `modulo` operation using `%` — you must touch **both** the validation list
      and the results map.
- [ ] Run Apply with `-var operation=multiply` and confirm which value beats tfvars
      (see the precedence comment in `terraform.tfvars`).
- [ ] Upgrade the operation `error_message` to name the bad value by interpolating
      `${var.operation}` into it.

## Git notes

- The stock `.gitignore` ignores `*.tfvars` (they often hold secrets). These projects'
  tfvars are lesson content, so the root `.gitignore` negates it: `!Project */**/*.tfvars`.
- Commit `.terraform.lock.hcl` when Stage 4 creates it.
- Never commit `.terraform/`, `*.tfstate`, or (later) the generated `out/` folder.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `No configuration files` | Run config's working directory points at the repo root, not `Project 1/Calculator/` |
| Outputs look stale after editing tfvars | Outputs live in **state** — run Apply again |
| Apply seems to hang | It's waiting for you to type `yes` in the Run console |
