# Quick Installation Guide

## 🚀 The Fastest Way (Recommended)

### One Command to Rule Them All

The absolute fastest way to bootstrap a project on a clean Linux server:

```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/bootstrap/main/quick-install.sh | sudo bash -s PROJECT_NAME [OPTIONS]
```

### Examples

**Bootstrap DYNAMOSS in production:**
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/bootstrap/main/quick-install.sh | \
  sudo bash -s dynamoss --env=prod --vault="dynamoss-prod"
```

**Bootstrap any GitHub project:**
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/bootstrap/main/quick-install.sh | \
  sudo bash -s user/repo --env=dev
```

**Just install the bootstrapper (no project bootstrap):**
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/bootstrap/main/quick-install.sh | \
  sudo bash
```

### What This Does

When you run the one-liner, it:

1. ✅ Installs prerequisites (curl, git, jq)
2. ✅ Downloads the Universal Bootstrapper from GitHub
3. ✅ Installs it system-wide (`/usr/local/bin/bootstrap`)
4. ✅ Optionally bootstraps your project immediately
5. ✅ Sets up everything including:
   - Dependencies (Docker, Java, Node, etc.)
   - Secrets (from 1Password or interactively)
   - Shell aliases
   - Deployment

### URL Customization

To use your own repository, replace `YOUR_USERNAME` with your GitHub username:

```bash
# Example with your GitHub username
curl -sSL https://raw.githubusercontent.com/ihabfallahy2/bootstrap/main/quick-install.sh | \
  sudo bash -s dynamoss --env=prod
```

Or host the script on your own domain:

```bash
curl -sSL https://bootstrap.yourdomain.com/install | \
  sudo bash -s dynamoss --env=prod
```

---

## 📦 Alternative Installation Methods

### Method 1: GitHub Release (if you create releases)

```bash
curl -sSL https://github.com/YOUR_USERNAME/bootstrap/releases/latest/download/install.sh | sudo bash
```

### Method 2: Manual Download

```bash
# Download the repository
git clone https://github.com/YOUR_USERNAME/bootstrap.git
cd bootstrap

# Install
sudo bash install.sh
```

### Method 3: SCP Transfer

```bash
# From your local machine
scp -r bootstrap/ user@server:/tmp/

# On the server
cd /tmp/bootstrap
sudo bash install.sh
```

---

## 🔒 Security Note

**Always review scripts before piping to bash!**

You can review the quick-install.sh script here:
https://github.com/YOUR_USERNAME/bootstrap/blob/main/quick-install.sh

Or download and inspect first:

```bash
# Download
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/bootstrap/main/quick-install.sh > install.sh

# Review
cat install.sh

# Execute
sudo bash install.sh dynamoss --env=prod
```

---

## 💡 Pro Tips

### Combine with Environment Variables

```bash
# Set 1Password token before running
export OP_SERVICE_ACCOUNT_TOKEN="ops_xxx..."

curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/bootstrap/main/quick-install.sh | \
  sudo -E bash -s dynamoss --env=prod --vault="dynamoss-prod"
```

The `-E` flag preserves environment variables when using sudo.

### Non-Interactive Mode for CI/CD

```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/bootstrap/main/quick-install.sh | \
  sudo bash -s dynamoss --env=staging --non-interactive
```

### Verbose Mode for Debugging

```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/bootstrap/main/quick-install.sh | \
  sudo bash -s dynamoss --env=dev --verbose
```

---

## 📝 After Installation

Once installed, you can use the `bootstrap` command from anywhere:

```bash
# Bootstrap another project
bootstrap my-other-project --env=prod

# Update the bootstrapper
sudo /usr/local/share/bootstrap/update.sh

# Uninstall
sudo /usr/local/share/bootstrap/uninstall.sh
```

---

## 🎯 Complete Example

Here's a complete example from a fresh Ubuntu server to a running application:

```bash
# 1. SSH to your server
ssh user@your-server

# 2. Run the one-liner (installs bootstrapper + bootstraps DYNAMOSS)
curl -sSL https://raw.githubusercontent.com/ihabfallahy2/bootstrap/main/quick-install.sh | \
  sudo bash -s dynamoss --env=prod --vault="dynamoss-prod"

# 3. Wait 2-5 minutes...

# 4. Use the aliases
source ~/.bashrc
logs    # View logs
status  # Check status

# 5. Your app is running! 🎉
```

That's it! From zero to deployed in one command! 🚀
