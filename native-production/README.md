# native-production — Ansible-based Galaxy, single VM + NAS

**Scaffold, not wired to run.** Placeholders (`CHANGE_ME_*`), unpinned
`version: main/master` refs, and unverified variable names are flagged
inline — read those comments before ever pointing this at a real VM.

👉 **Ready to actually deploy it? Follow [docs/BABY_STEPS.md](docs/BABY_STEPS.md) in order.**

## Why native instead of Docker

Chosen over the Docker Compose setup in the repo root because the goals
were performance/efficiency + real "enterprise standard" + openness to
official tooling. Native wins on exactly the things Docker couldn't
cleanly deliver:
- No container overhead, no Docker-in-Docker for BioContainers.
- Real web/job-handler/workflow-scheduler process separation via Galaxy's
  own Gravity process manager ("Gunicorn + Webless" pattern) — each is an
  independent systemd unit, not processes bundled inside one supervisord
  container.
- Direct systemd cgroup control and OS-level tuning, no container
  abstraction tax.
- proftpd can bind the host network directly — no Docker bridge-network
  passive-FTP problem.

## Grounded in real sources, not invented

- [Galaxy Project's official Ansible tutorial](https://training.galaxyproject.org/training-material/topics/admin/tutorials/ansible-galaxy/tutorial.html) — the two-play (dbservers/galaxyservers) structure, the core role set (`galaxyproject.galaxy`, `.postgresql`, `.postgresql_objects`, `.nginx`, `.miniconda`), and the Gunicorn+Webless Gravity pattern all come from here.
- [`usegalaxy-eu/infrastructure-playbook`](https://github.com/usegalaxy-eu/infrastructure-playbook) `requirements.yaml` — the actual Ansible inventory running Galaxy Europe's production instance. `requirements.yml` here is a trimmed subset (dropped everything institution-specific: Tailscale, Dokku, PHP/Apache, HTCondor cluster glue, TFTP, DNBD3, UCSC mirror, beacon/telegraf/WallE).

Where I could not verify an exact config key against a specific pinned
Galaxy version (Gravity's YAML schema, `postgresql_objects` variable
names), the file has an inline `CONFIDENCE NOTE` comment saying so —
check it against the actual role version you pin before trusting it.

## Your 6 requirements, mapped to what's here

1. **Clean VM** → `inventory/hosts.ini` targets one host, both `dbservers`
   and `galaxyservers` groups pointed at it (kept as two groups so the day
   you split Postgres onto its own box, the inventory barely changes).
2. **NAS attached** → `roles/nas_mount` — bulk datasets + job working dir
   go there (`group_vars/galaxyservers.yml`). **Postgres data directory
   never does** (`group_vars/dbservers.yml`) — NFS/CIFS under a live
   database risks silent corruption on a network hiccup.
3. **Performance/efficiency** → native (no container tax), Postgres
   tuning starting points, `local` unix-socket DB auth (no TCP/TLS
   overhead for same-host DB traffic), Gravity process separation so job
   load doesn't contend with web-request handling in the same process
   pool.
4. **Enterprise standard** → `dev-sec.os-hardening` + `dev-sec.ssh-hardening`
   (widely used, actively maintained), ufw firewall, restic-based
   encrypted backups with a retention policy, Postgres WAL archiving for
   point-in-time recovery, Prometheus exporters for monitoring.
5. **Official over Docker, if enterprise-ready** → this is Galaxy
   Project's own documented production path, and the same role set an
   actual large-scale public Galaxy instance runs.
6. **Minimize "fully down"** → see the honest limitation below first,
   then: `roles/watchdog` (systemd auto-restart + resource ceilings so one
   component can't starve another + an application-level health check
   that catches "process alive but hung," not just crashes), `roles/backup`
   (WAL-archived PITR + restic to a **separate** target from the primary
   NAS), firewall + hardening to reduce the odds of *needing* recovery at
   all.

## The one thing this can't fix

**This is one VM. One kernel panic, one disk failure, one hypervisor
issue takes everything down regardless of any software here.** True
zero-downtime requires a second independent node with automated failover
— out of scope per your own call on this (documented in conversation, not
repeated here). What this scaffold optimizes for instead: minimize the
odds of a *self-inflicted* outage (hardening, resource isolation, restart
policy), and minimize recovery time when the VM itself has a bad day (WAL
archiving + restic backups to a separate target + this whole playbook
being idempotent, so a fresh VM can be re-provisioned and restored from
backup in the time it takes to run `ansible-playbook` + a `restic restore`,
not rebuilt by hand).

## Before this ever touches a real VM

1. Pin every `version:` in `requirements.yml` to a real current release —
   several are placeholder `main`/`master`.
2. Verify `group_vars/galaxyservers.yml`'s `galaxy_config.gravity` block
   against the gravity schema shipped with your pinned `galaxy_commit_id`.
3. Verify `group_vars/dbservers.yml`'s `postgresql_objects_*` variable
   names against the pinned `galaxyproject.postgresql_objects` version.
4. Move all `CHANGE_ME_*` values into Ansible Vault
   (`ansible-vault create group_vars/galaxyservers/vault.yml`), don't leave
   secrets in plaintext group_vars.
5. Confirm your NAS export actually supports `hard` NFS mounts with the
   options in `group_vars/all.yml` — ask your NAS admin, don't assume.
6. Decide on and provision the restic backup target — it must NOT be the
   same NAS as primary storage (see comment in `group_vars/all.yml`).
7. Read `docs/RUNBOOK.md` before going live — restart/restore/upgrade
   procedures, not just install.
