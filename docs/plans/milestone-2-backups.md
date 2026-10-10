# Milestone 2: backups and restore

Status: planned for the next session (draft written 2026-10-10). Timebox: 4 h.

## Goal
> Taiga data survives `make down` / `make up`, and while the instance runs for a longer time, a database backup lands in S3 **once a day** without manual action.

## Requirements
1. **Backup before `down`:** `make down` takes a final backup (database + media) before `terraform destroy`.
2. **Restore after `up`:** `make up` restores the latest backup into a fresh instance.
3. **Daily backup:** when the instance runs longer than one session, a database backup is written to S3 every day.
4. **Backlog: backup testing.** Prove that backups can actually be restored, not just that files exist (see [Backlog](#backlog-backup-testing)).

## Definition of Done
- [ ] Persistent backup bucket in `terraform/bootstrap/` (versioning, SSE, public access block, `prevent_destroy`, lifecycle with retention).
- [ ] EC2 instance has an IAM role with least privilege on the backup bucket only (no access to the state bucket).
- [ ] Backup script on the host: `pg_dump` (custom format) + `/opt/taiga/media` archive → S3, with a timestamp in the key.
- [ ] Daily schedule on the host (systemd timer), visible in `systemctl list-timers`, logs in the journal.
- [ ] `make backup` runs the backup on demand; `make down` calls it first and **stops if the backup fails**.
- [ ] `make up` restores the latest backup only into an empty database (never overwrites existing data); first run with no backup still works.
- [ ] Proof: create a project with an attachment → `make down` → `make up` → project and attachment are back.
- [ ] Timed `make up` with restore; compare with the 5 min 53 s baseline.
- [ ] Decision log and metrics in the interview notes.

**Out of scope:** CI, monitoring, k3s. Automated restore tests (backlog below).

## Design ideas (to decide in the session)

### Storage
- **Separate bucket**, not the state bucket:
  - Different retention: state keeps 10 old versions for 90 days; backups follow their own rules.
  - Least privilege: the instance can write backups but must never read the Terraform state, which can contain secrets.
- Key layout: `daily/YYYY-MM-DD/` and `pre-down/YYYY-MM-DDTHHMM/`, each with `taiga.dump` and `media.tar.gz`.
- Lifecycle rules: expire `daily/` after ~14 days, keep `pre-down/` longer (~90 days). Lifecycle rules work by prefix, so the layout drives retention.
- Encryption: SSE-S3 as for state. The dump contains personal data and password hashes, so SSE-KMS could also be considered; decide in the session.
- Cost: a few MB per backup → cents per month.

### Access
- IAM role + instance profile in the main (ephemeral) stack. Policy:
  - `s3:PutObject` on `daily/*` and `pre-down/*`
  - `s3:GetObject` and `s3:ListBucket` for restore
  - **no `s3:DeleteObject`**: a compromised instance cannot wipe the backups; retention is done by lifecycle rules only.
- No static access keys on the server.
- Open question: on Ubuntu 26.04, install the AWS CLI with snap, with the official installer, or run it from the `amazon/aws-cli` container?

### Daily schedule: systemd timer vs cron
- Systemd timer (preferred):
  - `Persistent=true` catches up a run missed while the instance was stopped.
  - `RandomizedDelaySec` spreads the start time.
  - Output goes to the journal, and status is visible in `systemctl list-timers`.
- Cron is simpler but runs silently, and a missed run is lost.

### Backup flow
1. `docker compose exec -T taiga-db pg_dump -Fc` → stream to S3, so no large temp file on the disk.
2. `tar czf` of `/opt/taiga/media` → S3.
3. Exit code ≠ 0 on any failure; `set -euo pipefail` so a broken `pg_dump` in a pipe is not reported as success.

### Restore flow (in `make up`, Ansible)
- Find the latest backup: the newest `pre-down/` or `daily/` object.
- Restore only if the database has no projects yet. That keeps the playbook safe to re-run.
- Order: start `taiga-db` → `pg_restore --clean --if-exists` → restore media → start the rest. Migrations then run on top, which also covers a newer Taiga version.
- Flag to skip restore: `make up RESTORE=false`.

### Risks
- **Restoring over live data:** guarded by the empty-database check.
- **`make down` without a backup** when the instance is broken: let `make down FORCE=true` skip the backup on purpose, but never silently.
- **Version skew:** a dump from Postgres 14 must restore into the same major version; pin `postgres:14` (already pinned).

## Backlog: backup testing
A backup that has never been restored is not a backup. Ideas, from simple to complete:
1. **Integrity check after every backup:** run `pg_restore --list` on the dump and check `tar tzf` on the media archive. This catches truncated or corrupted files.
2. **Restore test into a throwaway container:** download the latest dump, restore it into a temporary `postgres:14` container, and check sanity queries (number of users, projects, user stories > 0). Could run weekly as a second systemd timer, or in CI (milestone 3).
3. **Full restore drill:** `make down` → `make up` with restore → automated check through the Taiga API (log in, list projects, download an attachment). Measure RTO, the time until data is back.
4. **Alert when backups stop:** if no new object appears in `daily/` for 26 h, send an e-mail (CloudWatch metric/alarm or an S3 event + Lambda). Fits milestone 4 (monitoring).

Metrics for interviews: RPO (max data loss = 24 h with daily backups, 0 for a planned `down`), RTO (restore time, measured with `make timed-up`).
