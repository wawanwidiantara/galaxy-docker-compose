# Day-2 Runbook

## Check health
```sh
systemctl status galaxy.service postgresql.service nginx.service galaxy-backup.timer galaxy-healthcheck.timer
curl -fsS http://127.0.0.1/api/version
journalctl -u galaxy.service -n 200 --no-pager
```

## Restart safely
Web + handlers + celery (all managed as one Gravity-controlled unit):
```sh
systemctl restart galaxy.service
```
To restart just the web tier or just handlers without touching the other,
use Galaxy's own process-group control through Gravity (`galaxyctl`) rather
than the blunt systemd restart above — check `galaxyctl --help` on the box
for the process-group names your pinned Gravity config exposes.

Postgres:
```sh
systemctl restart postgresql.service   # brief connection drop for all Galaxy processes
```

## Run a backup manually (outside the daily timer)
```sh
systemctl start galaxy-backup.service
journalctl -u galaxy-backup.service -f
```

## Restore from backup
```sh
export RESTIC_REPOSITORY=<from group_vars/all.yml restic_repository>
export RESTIC_PASSWORD=<from group_vars/all.yml restic_password>
restic snapshots                          # find the snapshot ID you want
restic restore <snapshot-id> --target /tmp/restore

# Postgres: restore the base backup, then replay WAL up to the point you want
# (point-in-time recovery) — see PostgreSQL's own PITR documentation for the
# recovery.signal / restore_command steps; the base backup + WAL archive
# from roles/backup + group_vars/dbservers.yml give you the raw material,
# actually performing PITR is a manual, careful procedure — do not automate
# blindly. Practice this on a throwaway VM before you need it for real.
```

## Full VM loss — rebuild from scratch
1. Provision a new VM, point `inventory/hosts.ini` at it.
2. `ansible-playbook -i inventory/hosts.ini playbook.yml --ask-vault-pass`
3. Restore Postgres from the latest restic snapshot (see above).
4. Re-mount the NAS (`roles/nas_mount` handles this automatically as part
   of the playbook) — dataset files themselves live on the NAS and survive
   VM loss entirely, only the DB and config need restoring.
5. Verify with the health check: `curl -fsS http://127.0.0.1/api/version`.

## Upgrading Galaxy
1. Take a backup first: `systemctl start galaxy-backup.service`, wait for
   it to finish.
2. Bump `galaxy_commit_id` in `group_vars/galaxyservers.yml` to the new
   release tag.
3. Re-run the playbook (idempotent — safe to run against an existing VM):
   `ansible-playbook -i inventory/hosts.ini playbook.yml --ask-vault-pass`
4. Watch `journalctl -u galaxy.service -f` through the restart — Galaxy
   runs its own DB migrations on startup as part of the standard install
   flow; don't skip step 1.

## Alerting
`roles/watchdog`'s health check posts to `alert_webhook_url` (set it in
`group_vars/galaxyservers.yml`) on failure — wire that to whatever your
team actually watches (Slack webhook, PagerDuty, etc.). The Prometheus
exporters (`roles/monitoring`) are scrape targets, not alerters by
themselves — you need an actual Prometheus + Alertmanager (ideally NOT on
this VM, so it can still page someone when this VM is the thing that's
down) pointed at `:9100` and `:9187` to get real alerting out of them.
