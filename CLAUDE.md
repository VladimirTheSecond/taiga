# CLAUDE.md

Self-hosted [Taiga](https://www.taiga.io/) Kanban on AWS, built with Terraform and Ansible. A pet project that shows hands-on cloud and IaC skills for DevOps job interviews.

## Working rules
- **Language:** English only, in chat, code comments, docs and commit messages.
- **Claude writes code, the owner runs it.** Never run `terraform apply/destroy/import`, `ansible-playbook` (except `--syntax-check`), `make up/down`, or any AWS CLI command that changes resources. Read-only checks are fine: `terraform fmt`, `terraform init -backend=false` + `terraform validate`, `ansible-lint`, `ansible-playbook --syntax-check`.
- **Secrets never go into git:** `*.tfstate`, `*.tfvars`, `ansible/inventory/hosts.ini`, vault password files. Secrets live in Ansible Vault (`group_vars/taiga/vault.yml`, encrypted).
- **Explain the "why"** for every non-obvious choice (in the PR description or commit message). The owner uses these decisions for STAR interview answers.
- Commit messages: lowercase, imperative, describe what and why. Small commits.

## Operating model
- The infrastructure is **destroyed after every session** and rebuilt from scratch at the start of the next one. Low cost, and it proves the deploy is reproducible. Every change must keep `up` from an empty account working.
- AWS budget: **20 EUR/month** (~23 USD; AWS Budgets works in USD).
- Region: `eu-central-1`.
- **Let's Encrypt limit:** 5 identical certificates per week. Use the staging CA for test runs, the production CA only for the final run.

## Architecture
- Two Terraform stacks:
  - `terraform/bootstrap/` (persistent, local state, applied once): S3 state bucket `taiga-tfstate-941791592956`, Route 53 zone (imported), AWS Budget. `prevent_destroy` on bucket and zone.
  - `terraform/` (ephemeral, state in S3 with `use_lockfile`): VPC `10.0.0.0/16`, public subnet, IGW, route table, security group (22 from the detected operator `/32`, 80, 443), EC2 `t3.medium` (Ubuntu 26.04, encrypted gp3 30 GB), Elastic IP, `A` record, generated `ansible/inventory/hosts.ini`.
- `ansible/`: playbook `playbooks/site.yml` (waits for SSH and cloud-init), roles `common` → `docker` → `taiga`. Taiga 6.9.0 in Docker Compose (`/opt/taiga`), Nginx on the host as reverse proxy instead of `taiga-gateway`, certbot `certonly --webroot` (staging CA unless `letsencrypt_staging=false`).
- Media and static: bind mounts `/opt/taiga/media` and `/opt/taiga/static`; Nginx serves static directly, media through `taiga-protected` + `X-Accel-Redirect` to an internal `/_protected/` location.
- Inside Docker the DB host is `taiga-db` (the Compose service name), not `localhost`.
- `Makefile`: `up`, `timed-up`, `configure`, `check`, `down`, `deps`; `STAGING=false` for a production certificate. Must stay compatible with GNU Make 3.81 (macOS default): no `.ONESHELL`.

## DNS
- Domain `vladimirulasovets.de`, registered at INWX (Route 53 Domains registration kept failing).
- DNS is hosted in Route 53: zone `Z05298261IAJVNBKNGXS5`, delegated at the registry (check: `dig NS vladimirulasovets.de @a.nic.de +norec`).
- The zone was created manually with the AWS CLI and must be brought under Terraform with an `import` block. It must **never** be destroyed: new name servers would break the delegation.
- Taiga hostname: `taiga.vladimirulasovets.de`.

## Known issues
- No backups: every `make down` wipes the database and uploads (roadmap step 2).
- Bootstrap stack state is local (optional: migrate into the bucket).
- `taiga-events` logs JWT access tokens (upstream default).
- A Compose file change restarts the Taiga containers twice (`state: present` + `Restart taiga` handler).
- RabbitMQ reuses the DB password instead of its own vault secret.
- `ansible-lint`: 11 style findings (role variable prefixes, `become_user` without `become`); the Homebrew `ansible-lint` does not see the installed collections (2 `unknown-module`).
- `ansible-playbook --syntax-check` does not load files from `include_tasks`; parse YAML files separately when checking.

## Plans
Last session plan: [`docs/plans/2026-10-10-session.md`](docs/plans/2026-10-10-session.md) (milestone 1, done). Next session plan (draft): [`docs/plans/milestone-2-backups.md`](docs/plans/milestone-2-backups.md).

Roadmap:
1. ~~One-command deploy with HTTPS on the real domain, S3 state, budget alert.~~ Done 2026-10-10.
2. Data persistence: `pg_dump` + media → S3 before `down`, restore after `up`, plus a daily backup while the instance runs.
3. CI: GitHub Actions with `terraform fmt/validate`, `tflint`, `ansible-lint`.
4. Monitoring: Prometheus + Grafana + `node_exporter` + `postgres_exporter`.
5. Migration from Docker Compose to k3s.

Backlog:
- Backup testing: integrity check after every backup, automated restore into a throwaway Postgres container, full restore drill with RTO measurement, alert when daily backups stop.

## Interview notes
The owner keeps the decision log, metrics and STAR drafts in a separate Obsidian vault (`/Users/vladimirulasovets/obsidian/DevOps/Taiga/Taiga.md`). At the end of a session, when that directory is available, add new decisions (decision, alternatives, why) and measured metrics there. That vault has its own language rules: write `DevOps/Taiga/` notes in English.
