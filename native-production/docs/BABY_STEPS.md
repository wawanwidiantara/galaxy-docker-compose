# 🚀 Native Production: Baby Step Guide

Follow these in order. Each step assumes the previous one worked. Don't
skip the verification lines — they catch mistakes before the next step
builds on top of them.

---

### Step 0: What you need before starting
- A clean VM (Ubuntu 22.04/24.04 or RHEL/Rocky 9 — matches what the pinned
  roles below support), reachable over SSH with a sudo-capable user.
- The NAS export already exists and is reachable from the VM's network
  (ask your NAS admin for the export path/credentials — don't guess).
- A second location for backups, separate from the NAS (S3-compatible
  storage, a different NAS, or an off-site SFTP target).
- A real domain name pointed at the VM's IP (needed for step 6, TLS).
- A control machine (your laptop, or a bastion host) with network access
  to the VM — this is where you run `ansible-playbook` from. It does not
  need to be the VM itself.

---

### Step 1: Prep the control machine
```sh
python3 -m venv ~/.venvs/galaxy-ansible
source ~/.venvs/galaxy-ansible/bin/activate
pip install ansible
```
Verify:
```sh
ansible --version
```

---

### Step 2: Pull in the roles this playbook depends on
```sh
cd native-production
```
Open `requirements.yml` first — several entries pin `version: main` or
`version: master` as placeholders. Replace each with a real release tag:
check `https://galaxy.ansible.com/<namespace>/<name>` for
`galaxyproject.*` roles, and the linked GitHub repo's releases/tags page
for the ones installed via `src: https://github.com/...`.

Then install them:
```sh
ansible-galaxy install -r requirements.yml -p roles/external
```
Verify: `ls roles/external` should show a folder per role/collection with
no errors printed above.

---

### Step 3: Point the inventory at your VM
Edit `inventory/hosts.ini`, replace both `CHANGE_ME_VM_IP` and
`CHANGE_ME_SSH_USER` with real values (same VM listed twice — it wears
both roles).

Verify you can reach it:
```sh
ansible -i inventory/hosts.ini galaxyservers -m ping
```
Expect `SUCCESS` back. If this fails, nothing past this point will work —
fix SSH access first.

---

### Step 4: Fill in the real settings
Edit these three files — every `CHANGE_ME_*` needs a real value:
- `group_vars/all.yml` — domain, admin email, NAS export path/mount
  options, backup target (**must not** be the same NAS as primary
  storage — re-read the comment above `restic_repository` if unsure why).
- `group_vars/dbservers.yml` — review the tuning numbers against your
  VM's actual RAM (rule of thumb is in the file's comments).
- `group_vars/galaxyservers.yml` — pin `galaxy_commit_id` to a real
  release tag (e.g. `release_25.1`), review the `gravity` block against
  that exact version's schema (see the `CONFIDENCE NOTE` comment at the
  top of the file for where to check).

---

### Step 5: Move secrets into Vault (don't leave them in plaintext)
```sh
mkdir -p group_vars/galaxyservers
ansible-vault create group_vars/galaxyservers/vault.yml
```
Inside, set (this file gets encrypted on save):
```yaml
vault_galaxy_id_secret: <32+ random chars>
vault_galaxy_bootstrap_api_key: <32+ random chars>
```
Generate random values with:
```sh
openssl rand -hex 32
```
Also move `restic_password` out of `group_vars/all.yml` into a vault file
the same way, rather than leaving it in plaintext.

---

### Step 6: Dry run before touching the real VM
```sh
ansible-playbook -i inventory/hosts.ini playbook.yml --ask-vault-pass --check --diff
```
Read the output. `--check` simulates without changing anything — use this
to catch typos/missing variables before step 7 actually runs. Expect some
"skipped" tasks that only report real state on a live run — that's normal
for `--check` mode, not a bug.

---

### Step 7: Run it for real
```sh
ansible-playbook -i inventory/hosts.ini playbook.yml --ask-vault-pass
```
This takes a while the first time (cloning Galaxy, building the client,
installing Postgres, mounting the NAS, setting up TLS). Let it finish —
don't Ctrl-C mid-run; every task here is idempotent, so if it does fail
partway, fix the reported error and re-run the same command rather than
starting over.

---

### Step 8: Verify it's actually up
```sh
ansible -i inventory/hosts.ini galaxyservers -m shell -a "curl -fsS http://127.0.0.1/api/version"
```
Then from your own machine:
1. Go to `https://<your-domain>`.
2. Confirm the cert is valid (padlock, no warning) — if not, check
   `journalctl -u certbot` on the VM.
3. Register/log in with the admin email from `group_vars/all.yml`.
4. Confirm you land in the Admin panel (top menu, since your email is
   listed in `admin_users`).

---

### Step 9: Confirm the resilience pieces actually got installed
```sh
ansible -i inventory/hosts.ini galaxyservers -m shell -a \
  "systemctl is-active galaxy.service postgresql.service nginx.service galaxy-backup.timer galaxy-healthcheck.timer node_exporter postgres_exporter"
```
All should say `active`. If `galaxy-backup.timer` is active but you want
to confirm the backup script itself actually works end-to-end (don't wait
for 2am to find out it's broken):
```sh
ansible -i inventory/hosts.ini galaxyservers -m shell -a "systemctl start galaxy-backup.service && journalctl -u galaxy-backup.service -n 50 --no-pager"
```

---

### Step 10: You're live — what to read next
- `docs/RUNBOOK.md` — restart, backup, restore, upgrade, alerting
  procedures. Read this before you need it, not during an incident.
- Wire `alert_webhook_url` (in `group_vars/galaxyservers.yml`) to
  somewhere your team actually watches — the health check is silent
  without it.
- Point an external Prometheus (not on this VM) at `:9100`/`:9187` if you
  want real alerting rather than just metrics sitting unread.

---

## 🧹 Rolling back / starting over

If step 7 goes badly wrong and you'd rather start clean:
```sh
# From a snapshot taken before you started (you did take one, right?):
# restore the VM snapshot via your hosting provider's console/CLI.

# Or, to just wipe Galaxy/Postgres and re-run from Step 7 on the same VM:
ansible -i inventory/hosts.ini galaxyservers -m shell -a "systemctl stop galaxy.service" --become
ansible -i inventory/hosts.ini dbservers -m shell -a "systemctl stop postgresql.service" --become
# Then manually remove /srv/galaxy and the Postgres data directory before
# re-running the playbook — double-check group_vars for the exact paths
# first, this is destructive and not something to script blindly.
```

Take a VM snapshot before Step 7 every time you run this against a
previously-working instance — that's your real rollback path, not
reversing individual Ansible tasks by hand.
