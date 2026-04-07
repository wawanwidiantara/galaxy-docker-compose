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
