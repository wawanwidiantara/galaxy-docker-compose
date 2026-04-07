# ⚙️ Galaxy Environment Configuration (CONFIG.md)

This document provides a detailed breakdown of every environment variable supported in your **`.env`** file. These variables control everything from security to how many CPUs Galaxy uses.

---

## 🔐 1. Security & Authentication (CRITICAL)
These must be changed for every new deployment to prevent unauthorized access.

| Variable | Description | Security |
| :--- | :--- | :--- |
| `GALAXY_ADMIN_USERS` | A comma-separated list of emails (e.g., `admin@org.com`). These users get the "Admin" menu. | **High** |
| `GALAXY_BOOTSTRAP_ADMIN_API_KEY` | A 32+ character secret key. Used for automated API access to the admin account. | **High** |
| `GALAXY_ID_SECRET` | A unique hex string used to encode database IDs in the URL. If compromised, an attacker can guess object IDs. | **High** |

---

## 🧬 2. Core Identity & Branding
| Variable | Description | Default |
| :--- | :--- | :--- |
| `GALAXY_BRAND` | The text shown in the top-left corner of the website and in the page title. | `Galaxy Enterprise` |
| `GALAXY_DOMAIN` | The IP or Domain Name through which users access Galaxy (e.g., `192.168.1.50`). | `localhost` |
| `GALAXY_PORT` | The port exposed on your host machine to access the web UI. | `8080` |

---

## ⚡ 3. Performance & Scaling
| Variable | Description | Rule of Thumb |
| :--- | :--- | :--- |
| `GUNICORN_WORKERS` | Number of web server processes. Handles user clicks/navigation. | `2 * CPUs + 1` |
| `CELERY_WORKERS` | Number of background workers for internal maintenance tasks. | `2` |
| `GALAXY_HANDLER_NUMPROCS` | Number of dedicated "Job Handlers" that manage scientific tool runs. | `2 to 4` |

---

## 🐳 4. Docker & Platform Integration
| Variable | Description | Status |
| :--- | :--- | :--- |
| `GALAXY_DOCKER_ENABLED` | Allows Galaxy to start tools inside Docker containers (BioContainers). | `True` |
| `DOCKER_PARENT` | Connects Galaxy to your laptop/VM's Docker engine for native performance. | `True` |
| `GALAXY_DESTINATIONS_DEFAULT` | The internal Galaxy "Job Destination". Tells Galaxy to use the Slurm/Docker cluster. | `slurm_cluster` |

---

## 🛠 5. Service Control (Toggling)
Use the **`NONUSE`** variable to disable specific services you don't need to save RAM.
- **Example**: `NONUSE=reports,flower,proftp` (Separate with commas).

Common values: `reports`, `flower`, `proftp`, `slurmd`, `slurmctld`, `nodejs`.

---

## 🌐 6. Networking & HTTPS
| Variable | Description |
| :--- | :--- |
| `USE_HTTPS` | Whether to force HTTPS. Set to `True` if you have SSL certificates. |
| `USE_HTTPS_LETSENCRYPT` | Enables automatic Let's Encrypt certificate generation. |
| `PROXY_PREFIX` | Used if you are running Galaxy behind a subfolder (e.g., `your-domain.com/galaxy`). |

---

## 🧪 7. Advanced & Debugging
| Variable | Description |
| :--- | :--- |
| `GALAXY_LOGGING` | Set to `full` to record everything to file. Set to `none` to save disk space. |
| `GALAXY_AUTO_UPDATE_DB` | If `True`, Galaxy will automatically upgrade the database schema on startup. |
| `BARE` | If `True`, starts a minimal Galaxy with no pre-installed dependencies. |
| `ENABLE_TTS_INSTALL` | Allows tool installation from the Galaxy Tool Shed. |

---

## 🧼 8. Data Management
| Variable | Description |
| :--- | :--- |
| `GALAXY_EXPORT_MARKER` | A unique string to identify this specific data export. Helpful for migrations. |
