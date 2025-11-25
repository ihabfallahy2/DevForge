# Deployment Guide for Testing

This guide will help you deploy the Universal Bootstrapper to your Linux server for testing.

## Prerequisites

- Linux server (Ubuntu 22.04, Debian 12, or similar)
- SSH access to the server
- sudo privileges

## 🚀 Option 1: Professional One-Liner (Recommended)

**The most professional approach** - Install and bootstrap in a single command:

### Step 1: Push to GitHub (if not already done)

```bash
cd c:\dev\dev\DevForge\bootstrap
git init
git add .
git commit -m "Universal Project Bootstrapper"
git remote add origin https://github.com/YOUR_USERNAME/bootstrap.git
git branch -M main
git push -u origin main
```

### Step 2: Execute the One-Liner on Your Server

```bash
# SSH to your server
ssh user@your-server

# Run the professional one-liner
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/bootstrap/main/quick-install.sh | \
  sudo bash -s dynamoss --env=prod --vault="dynamoss-prod"
```

**That's it!** ✨ This single command will:
- ✅ Install prerequisites (curl, git, jq)
- ✅ Download the bootstrapper from GitHub
- ✅ Install it system-wide
- ✅ Bootstrap your DYNAMOSS project
- ✅ Install all dependencies (Docker, Java, etc.)
- ✅ Configure secrets from 1Password
- ✅ Deploy the application

### Alternative: Install First, Bootstrap Later

```bash
# Just install the bootstrapper
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/bootstrap/main/quick-install.sh | sudo bash

# Then bootstrap projects as needed
bootstrap dynamoss --env=prod
bootstrap my-other-app --env=dev
```

---

## Option 2: Deploy from Local Files

### Step 1: Package the Bootstrapper

On your local machine (Windows):

```bash
# Navigate to the bootstrap directory
cd c:\dev\dev\DevForge\bootstrap

# Create a tarball (if you have tar on Windows, or use WSL)
# Or just zip the directory
```

### Step 2: Upload to Server

```bash
# Using SCP (replace with your server details)
scp -r bootstrap/ user@your-server:/tmp/bootstrap

# Or using rsync
rsync -avz bootstrap/ user@your-server:/tmp/bootstrap/
```

### Step 3: Install on Server

SSH into your server and run:

```bash
ssh user@your-server

cd /tmp/bootstrap
sudo bash install.sh
```

## Option 2: Deploy from Git Repository

### Step 1: Push to GitHub

```bash
cd c:\dev\dev\DevForge\bootstrap

# Initialize git if not already
git init
git add .
git commit -m "Initial commit of Universal Bootstrapper"

# Push to your GitHub
git remote add origin https://github.com/YOUR_USERNAME/bootstrap.git
git push -u origin main
```

### Step 2: Install on Server

```bash
ssh user@your-server

# Clone and install
git clone https://github.com/YOUR_USERNAME/bootstrap.git /tmp/bootstrap
cd /tmp/bootstrap
sudo bash install.sh
```

## Testing the Installation

### 1. Verify Installation

```bash
# Check if bootstrap command is available
which bootstrap

# Test help
bootstrap --help
```

### 2. Test with a Simple Project

For initial testing, use a known public project:

```bash
# Test with Spring PetClinic (Spring Boot example)
bootstrap https://github.com/spring-projects/spring-petclinic \
  --dir=/opt/test-project \
  --skip-deploy \
  --verbose

# This will:
# - Clone the repository
# - Detect it as Spring Boot
# - Install dependencies (Docker, Java)
# - NOT deploy (we used --skip-deploy)
```

### 3. Test with DYNAMOSS

```bash
# For your DYNAMOSS project, you'll need 1Password setup first
# Make sure you have:
# - 1Password CLI installed (bootstrap can install it)
# - Service account token or interactive login

# Option A: With 1Password
export OP_SERVICE_ACCOUNT_TOKEN="your-token-here"
bootstrap dynamoss \
  --env=prod \
  --vault="dynamoss-prod" \
  --dir=/opt/dynamoss

# Option B: Without 1Password (interactive secrets)
bootstrap dynamoss \
  --dir=/opt/dynamoss \
  --skip-deploy

# Then manually configure secrets:
cd /opt/dynamoss
# Edit .env file
# Then deploy:
./deploy.sh
```

## Troubleshooting

### Permission Issues

```bash
# If you get permission errors
sudo usermod -aG docker $USER
newgrp docker
```

### Missing Dependencies

```bash
# The bootstrapper will install most things, but ensure basics:
sudo apt-get update
sudo apt-get install -y curl git
```

### Verbose Mode

Always use `--verbose` flag when testing to see detailed logs:

```bash
bootstrap PROJECT --verbose
```

## Next Steps

Once basic testing works:

1. **Setup 1Password** for automated secret management
2. **Configure Discord webhooks** for notifications  
3. **Test webhook server** for auto-deploy
4. **Setup your projects** with `project.bootstrap.json`

## Cleanup

To remove the bootstrapper:

```bash
sudo /usr/local/share/bootstrap/uninstall.sh
```

To remove test projects:

```bash
sudo rm -rf /opt/test-project
```

## Support

If you encounter issues:
1. Check logs (run with `--verbose`)
2. Review `docs/TROUBLESHOOTING.md`
3. Check file permissions
4. Verify network connectivity
