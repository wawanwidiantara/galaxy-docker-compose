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
- **Reference Data**: CVMFS integration for on-demand genome access.
- **Interactive Tools**: Built-in proxy for Jupyter and RStudio notebooks.
- **Platform Integration**: Native Docker-in-Docker support for BioContainers.
- **Scaling**: Configurable Gunicorn workers and Job Handlers for multi-user workloads.

## 🧹 Maintenance
- **Updates**: `docker compose pull && docker compose up -d`
- **Clean Uninstall**: See the **Uninstall** section in the [Step Guide](docs/PRODUCTION_SETUP.md).

---

## 🤝 Credits
This configuration relies entirely on the work of the **Galaxy Project** and the contributors to the **Galaxy Docker Stable** images.

- **Main Image**: [bgruening/docker-galaxy-stable](https://github.com/bgruening/docker-galaxy)
- **CVMFS**: [Galaxy Project Reference Data](https://galaxyproject.org/admin/reference-data-repo/)

---
