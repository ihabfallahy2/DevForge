# CI/CD Best Practices for Universal Bootstrapper

## GitHub Actions

### Setup

1. **Add Secrets** to your repository:
   - `OP_SERVICE_ACCOUNT_TOKEN` - 1Password service account token
   - `VAULT_NAME` - 1Password vault name
   - `DISCORD_WEBHOOK_URL` - Discord webhook (optional)

2. **Copy workflow file**:
   ```bash
   cp .github/workflows/bootstrap.yml YOUR_PROJECT/.github/workflows/
   ```

3. **Customize** the workflow for your project type

### Example Workflow

See [`.github/workflows/bootstrap.yml`](../.github/workflows/bootstrap.yml)

---

## GitLab CI

### Setup

1. **Add CI/CD Variables** in Settings → CI/CD → Variables:
   - `OP_SERVICE_ACCOUNT_TOKEN` - 1Password service account token (masked)
   - `VAULT_NAME` - 1Password vault name
   - `DISCORD_WEBHOOK_URL` - Discord webhook (optional)

2. **Copy pipeline file**:
   ```bash
   cp .gitlab-ci.yml YOUR_PROJECT/
   ```

3. **Customize** the pipeline for your project

### Example Pipeline

See [`.gitlab-ci.yml`](../.gitlab-ci.yml)

---

## Security Best Practices

### 1. Service Accounts

✅ **DO**: Use 1Password service accounts for CI/CD
```bash
export OP_SERVICE_ACCOUNT_TOKEN="ops_xxx..."
```

❌ **DON'T**: Use personal 1Password accounts in CI/CD

### 2. Secret Masking

Ensure all CI/CD platforms mask your secrets:
- GitHub: Secrets are automatically masked
- GitLab: Mark variables as "Masked"

### 3. Branch Protection

Configure branch protection rules:
- Require PR reviews before merge
- Require status checks to pass
- Deploy only from protected branches

---

## Testing Strategy

### Unit Tests

Run unit tests before deployment:
```yaml
- name: Unit Tests
  run: ./mvnw test  # or npm test, pytest, etc.
```

### Integration Tests

Run integration tests in staging:
```yaml
- name: Integration Tests
  run: ./tests/run_integration_tests.sh
```

### Smoke Tests

Run smoke tests after deployment:
```yaml
- name: Smoke Test
  run: curl -f http://localhost:8080/health
```

---

## Deployment Strategies

### 1. Staging First

Always deploy to staging before production:
```yaml
deploy-staging:
  if: github.ref == 'refs/heads/develop'
  
deploy-production:
  if: github.ref == 'refs/heads/main'
```

### 2. Manual Approval

Require manual approval for production:
```yaml
deploy-production:
  environment:
    name: production
    # Requires manual approval in GitHub
```

### 3. Rollback Plan

Always have a rollback strategy:
```bash
# Keep previous deployment backed up
cp -r /opt/app /opt/app.backup.$(date +%s)

# Deploy new version
./deploy.sh

# If fails, rollback
cp -r /opt/app.backup.* /opt/app
```

---

## Environment-Specific Configuration

### Development
```yaml
env:
  ENVIRONMENT: dev
  VAULT_NAME: myproject-dev
  REPLICAS: 1
```

### Staging
```yaml
env:
  ENVIRONMENT: staging
  VAULT_NAME: myproject-staging
  REPLICAS: 2
```

### Production
```yaml
env:
  ENVIRONMENT: prod
  VAULT_NAME: myproject-prod
  REPLICAS: 3
```

---

## Monitoring and Notifications

### Discord Notifications

The bootstrapper automatically sends notifications if `DISCORD_WEBHOOK_URL` is set.

### Custom Notifications

Add custom notification steps:
```yaml
- name: Notify on Failure
  if: failure()
  run: |
    curl -X POST $DISCORD_WEBHOOK_URL \
      -H "Content-Type: application/json" \
      -d '{"content": "❌ Deployment failed!"}'
```

---

## Caching

### GitHub Actions

Cache dependencies:
```yaml
- uses: actions/cache@v3
  with:
    path: ~/.m2/repository  # or node_modules, .venv, etc.
    key: ${{ runner.os }}-maven-${{ hashFiles('**/pom.xml') }}
```

### GitLab CI

Cache dependencies:
```yaml
cache:
  paths:
    - .m2/repository
    - node_modules
```

---

## Troubleshooting

### Common Issues

1. **"Not authenticated with 1Password"**
   - Verify `OP_SERVICE_ACCOUNT_TOKEN` is set correctly
   - Check token hasn't expired

2. **"Secrets not found"**
   - Verify vault name is correct
   - Ensure service account has access to vault

3. **"Permission denied"**
   - Ensure scripts are executable: `chmod +x *.sh`
   - Use `sudo` where necessary

### Debug Mode

Enable verbose logging:
```yaml
- name: Bootstrap (Debug)
  run: bootstrap . --verbose
```

---

## Complete Example

See the working examples in:
- [GitHub Actions](.github/workflows/bootstrap.yml)
- [GitLab CI](.gitlab-ci.yml)

For project-specific customization, refer to your `project.bootstrap.json`.
