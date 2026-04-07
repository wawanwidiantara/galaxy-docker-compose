# Galaxy Deployment Configuration

This repository provides a streamlined configuration and orchestration for running a production-ready Galaxy instance using Docker Compose. It is designed for easy deployment on Linux VMs within restricted network environments.

## 🏁 Quick Start
To get your Galaxy setup running in few minutes, follow our **[Step Guide](docs/PRODUCTION_SETUP.md)**.

## 🛠 Included Features
- **Reference Data**: CVMFS integration for on-demand access to curated genomes.
- **Advanced Tools**: Pre-configured support for Interactive Tools (Jupyter/RStudio) and BioContainers.
- **Persistence**: Structured volumes for databases and logs for reliable backups.
- **Uninstallation**: Simple cleanup steps to wipe the environment and data.

## 📚 Documentation
- **[Step Guide](docs/PRODUCTION_SETUP.md)**: Standard deployment in 5 steps.
- **[Configuration (CONFIG.md)](docs/CONFIG.md)**: Detailed environment variable reference.
- **[Advanced Documentation](docs/DOCUMENTATION.md)**: Original technical specifications and Galaxy features.

---

## 🤝 Credits & Tribute

This deployment configuration is a wrapper for the excellent work of the **Galaxy Project** and the **Galaxy Docker** community. 

- **Original Image**: [bgruening/docker-galaxy-stable](https://github.com/bgruening/docker-galaxy)
- **Base Project**: [Galaxy Project Official Site](https://galaxyproject.org/)

We give full credit to the original authors for building the powerful software and Docker images that make this streamlined deployment possible.
