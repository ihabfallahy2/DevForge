# Troubleshooting Guide

Common issues and solutions for the Universal Project Bootstrapper.

## Installation Issues

### Docker Installation Fails

**Symptom**: Error when installing Docker.

**Solution**:
```bash
# Check system compatibility
uname -a

# Manual installation
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

### Permission Denied

**Symptom**: "Permission denied" errors when running commands.

**Solution**:
```bash
# Make bootstrap.sh executable
chmod +x bootstrap.sh

# If Docker permission issues
sudo usermod -aG docker $USER
# Log out and back in
```

## Git Issues

### Repository Clone Fails

**Symptom**: "Repository not found" or authentication errors.

**Solution**:
```bash
# For private repos, ensure SSH key is configured
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub
# Add the public key to GitHub/GitLab

# Or use HTTPS with token
git clone https://username:token@github.com/user/repo.git
```

### Git Hook Errors

**Symptom**: Hooks not executing.

**Solution**:
```bash
# Ensure hooks are executable
chmod +x .git/hooks/*

# Check hook script syntax
bash -n .git/hooks/post-merge
```

## 1Password Issues

### Authentication Fails

**Symptom**: "Not signed in" or "Authentication required".

**Solution**:
```bash
# Sign in manually
op signin

# Or use service account
export OP_SERVICE_ACCOUNT_TOKEN="your-token"

# Verify authentication
op account list
```

### Secrets Not Found

**Symptom**: "Secret X not found in vault Y".

**Solution**:
- Verify vault name matches exactly
- Check item title matches environment variable name
- Ensure you have access to the vault
- Verify field is named "password", "credential", "text", or "value"

```bash
# List vaults
op vault list

# List items in vault
op item list --vault="vault-name"

# Get specific item
op item get "ITEM_NAME" --vault="vault-name"
```

## Deployment Issues

### Health Check Fails

**Symptom**: "Health check failed" after deployment.

**Solution**:
```bash
# Check Docker logs
docker-compose logs app

# Check if port is in use
netstat -tulpn | grep :8080

# Manually test health endpoint
curl http://localhost:8080/health
curl http://localhost:8080/actuator/health
```

### Docker Compose Errors

**Symptom**: "docker-compose: command not found" or service fails to start.

**Solution**:
```bash
# Check Docker Compose version
docker-compose --version

# Use Docker Compose V2 if V1 not available
docker compose up -d

# Check docker-compose.yml syntax
docker-compose config
```

### Build Fails

**Symptom**: Maven/Gradle/npm build fails.

**Solution**:
```bash
# Check for missing dependencies
cat .env

# Clean and rebuild
./mvnw clean package  # Java
npm ci && npm run build  # Node.js
pip install -r requirements.txt  # Python

# Check logs
docker-compose logs --tail=100
```

## Alias Issues

### Aliases Not Working

**Symptom**: "Command not found" when using aliases.

**Solution**:
```bash
# Reload shell configuration
source ~/.bashrc  # or ~/.zshrc

# Check if aliases were added
grep "BOOTSTRAP-ALIASES" ~/.bashrc

# Manually add if missing
bootstrap my-project --skip-deploy
```

## Discord Notification Issues

### Notifications Not Sent

**Symptom**: No Discord messages received.

**Solution**:
- Verify webhook URL is correct
- Check if `DISCORD_WEBHOOK_URL` is set in `.env`
- Test webhook manually:

```bash
curl -H "Content-Type: application/json" \
  -d '{"content": "Test message"}' \
  "YOUR_WEBHOOK_URL"
```

## Dependency Issues

### Java Version Mismatch

**Symptom**: "Unsupported class version" or Java errors.

**Solution**:
```bash
# Check Java version
java -version

# Install correct version
sudo apt install openjdk-17-jdk

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
```

### Node.js Version Issues

**Symptom**: "Node.js version X required".

**Solution**:
```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Install specific version
nvm install 18
nvm use 18
```

## System Issues

### Disk Space

**Symptom**: "No space left on device".

**Solution**:
```bash
# Check disk space
df -h

# Clean Docker
docker system prune -a

# Clean old images
docker image prune -a
```

### Out of Memory

**Symptom**: Build or deployment killed/crashes.

**Solution**:
```bash
# Check memory
free -h

# Increase Docker memory limit (Docker Desktop)
# Settings -> Resources -> Memory

# Add swap space
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## Debug Mode

For detailed troubleshooting, run with verbose logging:

```bash
bootstrap my-project --verbose
```

This will show:
- All executed commands
- Detection results
- Configuration values
- Detailed error messages

## Getting Help

If issues persist:
1. Check logs in `.bootstrap.log` (if created)
2. Review project's `project.bootstrap.json`
3. Verify all prerequisites are met
4. Open an issue with:
   - Command run
   - Full error message
   - OS version (`uname -a`)
   - Bootstrapper version
