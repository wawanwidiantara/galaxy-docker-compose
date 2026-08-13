# 🚀 Galaxy Production: Baby Step Guide

This is the simplest possible guide to getting your Galaxy factory running. Just follow the steps in order.

---

### Step 1: Prepare the Ground
Open your terminal and create the folders where Galaxy will store its data.
```bash
mkdir -p export logs config
```

---

### Step 2: Fix the "Keys" (Permissions)
Galaxy needs special permission to write to those folders. Run these two commands exactly:
```bash
# Give Galaxy internal user (1450) access
sudo chown -R 1450:1450 ./export ./logs

# Give the Database (1550) access
sudo chown -R 1550:1550 ./export/postgresql
```

---

### Step 3: Setup your Secret Identity
Copy the example configuration to create your real one:
```bash
cp .env.example .env
```
Now, open the **`.env`** file and change **`admin@your-org.com`** to your real email.

> [!TIP]
> **Stability Fix**: Ensure you add `HOME=/home/galaxy` to your environment (already included in the provided `compose.yaml`) to prevent "Permission Denied" errors related to Python's internal cache files.

> [!TIP]
> **Pin your version**: Set `GALAXY_IMAGE_TAG` in `.env` to a specific release (e.g. `26.0`) instead of leaving it at the default. Never run production against `:latest` — upgrades then happen silently on every `docker compose pull`, with no way to know what changed or roll back.

---

### Step 3.5: Set Management Passwords
Galaxy has several management tools (Reports, Flower, Supervisor) that are protected by a shared password file. 
Open **`config/common_htpasswd`** and replace the existing password for the `admin` user with your own.

To generate a secure MD5 hash using your terminal, run:
```bash
# Replace 'your_password' with a real one
openssl passwd -apr1 your_password
```

**Final step**: Copy the output hash and paste it into **`config/common_htpasswd`** in this format:
```text
admin:YOUR_GENERATED_HASH_HERE
```

---

### Step 4: Blast Off 🚀
Start the engines:
```bash
docker compose up -d
```
*Wait about 5-10 minutes while it builds the database for the first time.*

---

### Step 5: Start Working
1.  Go to **[http://localhost:8080](http://localhost:8080)**.
2.  Click **Login or Register**.
3.  **Register** a new account using the email you put in the `.env` file.
4.  You are now the **Admin** of the entire system!

---

## 🔒 Step 6: Optional Power Features (read the trade-off first)

`compose.yaml` ships hardened: no `--privileged`, no Docker socket mount,
FTP disabled. That's deliberate — each of the following grants the galaxy
container root-equivalent control of the **host**, not just the container:

- **BioContainers-in-Docker** (auto-run tools in their own Docker image)
- **On-demand CVMFS via autofs** (needs the `mount` syscall, i.e. `--privileged`)
- **Active/passive FTP** (needs a mapped passive-port range or `--net=host`
  to work through Docker's bridge network at all — SFTP on port 8022 has
  neither problem and is enabled by default)

If you need any of these, opt in explicitly rather than editing `compose.yaml`:

```sh
cp compose.override.yml.example compose.override.yml
# edit compose.override.yml if you only need some of the three features
docker compose -f compose.yaml -f compose.override.yml up -d
```

`compose.override.yml` is gitignored — it's meant to differ per deployment
and should never be committed.

**CVMFS without `--privileged`**: if you only need on-demand reference
genomes and not the other two features, install a CVMFS client on the
**host** VM (not in the container) and bind-mount it read-only instead of
using the override file:

```yaml
    volumes:
      - /cvmfs:/cvmfs:ro   # uncomment in compose.yaml; requires host-side CVMFS client
```

This avoids granting the container `--privileged` entirely.

---

## 🛡 Step 7: Database Migrations (manual, on purpose)

`GALAXY_AUTO_UPDATE_DB` defaults to `False` — schema migrations no longer
run automatically on every container restart. Automatic migration on
restart is convenient but means a bad restart can leave the DB mid-migration
with no backup taken first. Before upgrading `GALAXY_IMAGE_TAG`:

```sh
./scripts/backup.sh                        # back up first
docker compose stop galaxy
docker compose pull
docker compose up -d
docker exec -it galaxy_production bash
sh manage_db.sh upgrade                    # run the migration explicitly
exit
docker compose restart galaxy
```

---

## 💾 Step 8: Backups

Postgres lives inside the single galaxy container and isn't exposed on the
network, so back it up via `docker exec` rather than a network tool:

```sh
./scripts/backup.sh
```

Schedule it with host cron:

```cron
0 2 * * * cd /path/to/galaxy-docker-compose && ./scripts/backup.sh >> logs/backup.log 2>&1
```

This backs up the database and config — not the (potentially huge) dataset
files under `export/galaxy/database/files/`. Snapshot those separately
(LVM/ZFS snapshot, rsync, or your NAS's own backup — see Step 9 below).

---

## 📜 Step 9: Log Rotation

`GALAXY_LOGGING=full` writes verbose logs into `./logs` directly from
inside the container, bypassing Docker's own log-size limits entirely.
Install the provided logrotate config on the **host**:

```sh
sudo cp config/logrotate-galaxy.conf /etc/logrotate.d/galaxy
# edit the path inside the file to this repo's absolute ./logs path first
sudo logrotate -f /etc/logrotate.d/galaxy   # test it fires without waiting for cron
```

---

## ⚡ Step 10: Sizing the Resource Ceiling

This single container runs Postgres, nginx, Gunicorn, Celery, RabbitMQ,
Redis and (optionally) Slurm together — with no limit, one runaway tool job
can starve the database and take the whole instance down. `compose.yaml`
caps CPU/memory/open-files via `.env`:

```
GALAXY_CPU_LIMIT=4        # leave headroom below the host's total core count
GALAXY_MEM_LIMIT=6g       # leave headroom below the host's total RAM
GALAXY_MEM_RESERVATION=2g
GALAXY_SHM_SIZE=1gb       # Postgres wants more than Docker's 64MB default
GALAXY_NOFILE_LIMIT=65536 # Galaxy/Gunicorn/Postgres all want this raised
```

`GUNICORN_WORKERS` should scale with `GALAXY_CPU_LIMIT` (rule of thumb:
`2 * CPUs + 1`), not the host's full core count if you're capping the
container to fewer cores than the host has.

---

## 🧹 How to Clean Everything (Uninstall)

If you want to completely remove Galaxy and wipe all its data for a "fresh start":

### 1. Stop and Remove Containers
```bash
docker compose down --volumes --remove-orphans
```

### 2. Wipe the Data (Warning: This deletes all your work!)
```bash
sudo rm -rf export/ logs/
```

### 3. Cleanup Docker Images (Optional)
```bash
docker rmi quay.io/bgruening/galaxy:latest
```

---

## 📚 Advanced Documentation
For the full technical details of every feature, please see [DOCUMENTATION.md](./DOCUMENTATION.md).

---

## 💾 9. Advanced: Using NAS Storage

If your Scientific Data is growing too large for your VM's local disk, you can store it on a **NAS (Network Attached Storage)** via NFS or SMB.

### 9.1 The Best Practice: "The Split"
Storing the Database on a NAS is risky and slow. We recommend keeping the **Database on local SSD** and the **massive files on the NAS**.

**Update your `docker-compose.yml` volumes section like this:**

```yaml
volumes:
  # 1. Database stays on local VM SSD (Fast & Reliable)
  - ./export/postgresql:/export/postgresql

  # 2. Scientific Data goes to the NAS mount
  # Replace '/mnt/nas/galaxy_data' with your actual mount path
  - /mnt/nas/galaxy_data/galaxy:/export/galaxy
  - /mnt/nas/galaxy_data/ftp:/export/ftp
  - /mnt/nas/galaxy_data/cvmfs-cache:/export/cvmfs-cache
```

### 9.2 Critical Considerations for NAS
1.  **Mount First**: Your NAS must be mounted on your VM host **before** you start Docker.
2.  **Permissions**: You must run the `chown` commands from **Step 2** on your NAS mount point as well.
    *   **Example**: `sudo chown -R 1450:1450 /mnt/nas/galaxy_data`
3.  **Speed**: Use a **1Gbps** (minimum) or **10Gbps** (recommended) network connection between your VM and your NAS.

> [!WARNING]
> If the network connection to your NAS drops while Galaxy is running, it may cause scientific tools to fail or corrupt your result files. Ensure your NAS mount is stable and has `auto-reconnect` enabled in `/etc/fstab`.
