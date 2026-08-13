# galaxy-docker-compose

[![Docker](https://img.shields.io/badge/Docker-%230db7ed.svg?style=flat-square&logo=docker&logoColor=white)](https://www.docker.com/)
[![Galaxy](https://img.shields.io/badge/Galaxy-%2371b1eb.svg?style=flat-square&logo=galaxy&logoColor=white)](https://galaxyproject.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](https://opensource.org/licenses/MIT)

A clean, production-ready Docker Compose configuration for the [Galaxy Project](https://galaxyproject.org/). This repository is a wrapper around the scientific images provided by the [Galaxy Docker](https://github.com/bgruening/docker-galaxy) community, optimized for private cloud and office VM deployments.

## 🏁 Directions
To set up your instance, follow the step-by-step guide:
👉 **[Step Guide (Setup)](docs/PRODUCTION_SETUP.md)**

## ⚙️ Configuration
A complete reference for all environment variables (`.env`):
👉 **[Config Reference (CONFIG.md)](docs/CONFIG.md)**

## 🛠 Features Included
- **Reference Data**: CVMFS integration for on-demand genome access (opt-in, see below).
- **Interactive Tools**: Built-in proxy for Jupyter and RStudio notebooks.
- **Platform Integration**: Docker-in-Docker support for BioContainers (opt-in, see below).
- **Scaling**: Configurable Gunicorn workers, Job Handlers, and container resource limits for multi-user workloads.

## 🔒 Hardened by default
`compose.yaml` pins the image version and ships with `--privileged` and the
Docker socket mount removed, since both grant the container root-equivalent
control of the host. BioContainers-in-Docker, on-demand CVMFS via autofs,
and active FTP all need one of those — they're opt-in via
`compose.override.yml.example`:

```sh
cp compose.override.yml.example compose.override.yml
docker compose -f compose.yaml -f compose.override.yml up -d
```

Read the warning at the top of that file before using it. Full rationale in
[docs/PRODUCTION_SETUP.md](docs/PRODUCTION_SETUP.md).

## 🧹 Maintenance
- **Updates**: bump `GALAXY_IMAGE_TAG` in `.env` to a specific release, then `docker compose pull && docker compose up -d`. Don't track `latest` in production.
- **Backups**: `./scripts/backup.sh` dumps the Postgres DB + config (schedule via cron); dataset files need filesystem-level snapshotting separately.
- **Log rotation**: install `config/logrotate-galaxy.conf` on the host — Galaxy's own logs bypass Docker's log limits.
- **Clean Uninstall**: See the **Uninstall** section in the [Step Guide](docs/PRODUCTION_SETUP.md).

---

## 🤝 Credits
This configuration relies entirely on the work of the **Galaxy Project** and the contributors to the **Galaxy Docker Stable** images.

- **Main Image**: [bgruening/docker-galaxy-stable](https://github.com/bgruening/docker-galaxy)
- **CVMFS**: [Galaxy Project Reference Data](https://galaxyproject.org/admin/reference-data-repo/)

---
