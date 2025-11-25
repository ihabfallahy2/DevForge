# 1Password Setup Guide

This guide explains how to configure 1Password for use with the Universal Project Bootstrapper.

## Prerequisites

- A 1Password account (personal or team)
- 1Password CLI installed (the bootstrapper can install it automatically)

## Installation

The bootstrapper will automatically install 1Password CLI if it's not present. However, you can also install it manually:

### Ubuntu/Debian
```bash
curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
    sudo tee /etc/apt/sources.list.d/1password.list

sudo apt update && sudo apt install 1password-cli
```

## Authentication

### Interactive Login
```bash
op signin
```

Follow the prompts to sign in to your 1Password account.

### Service Accounts (Recommended for CI/CD)

For automated environments, use a Service Account:

1. In 1Password, create a Service Account
2. Generate a token
3. Set the token as an environment variable:
   ```bash
   export OP_SERVICE_ACCOUNT_TOKEN="your-token-here"
   ```

The bootstrapper will automatically use the service account token if present.

## Vault Structure

### Organizing Secrets

We recommend organizing your secrets by project and environment:

```
1Password Vaults:
├── my-project-prod/
│   ├── DATABASE_URL
│   ├── API_KEY
│   └── SECRET_KEY
├── my-project-dev/
│   ├── DATABASE_URL
│   ├── API_KEY
│   └── SECRET_KEY
└── shared/
    └── COMMON_SECRET
```

### Naming Conventions

For secrets to be automatically recognized:
- **Vault Name**: Follow the pattern `{project-name}-{environment}` (e.g., `dynamoss-prod`)
- **Item Title**: Use the exact environment variable name (e.g., `DATABASE_URL`)
- **Field Name**: Use "password", "credential", "text", or "value"

### Creating a Secret

1. Open 1Password
2. Create a new vault (or use an existing one)
3. Add a new item:
   - **Title**: `DATABASE_URL` (the exact env var name)
   - **Type**: Password, Login, or Secure Note
   - Add a field named "password" or "value" with your secret

## Using with the Bootstrapper

The bootstrapper will automatically:
1. Authenticate with 1Password (if not already authenticated)
2. Read the vault specified in `project.bootstrap.json` or via `--vault` flag
3. Fetch all secrets matching your project's requirements
4. Generate a `.env` file with the secrets

### Example

```bash
bootstrap my-project --env=prod --vault="my-project-prod"
```

This will fetch secrets from the `my-project-prod` vault.

## Security Best Practices

1. **Use Service Accounts for CI/CD**: Never use personal credentials in automated environments
2. **Rotate Secrets Regularly**: Update secrets in 1Password periodically
3. **Limit Vault Access**: Grant vault access only to necessary team members
4. **Use Environment-Specific Vaults**: Separate prod, dev, and staging secrets
5. **Audit Access**: Regularly review who has access to sensitive vaults

## Troubleshooting

### "Not signed in"
Run `op signin` to authenticate.

### "Vault not found"
Ensure the vault name is correct and you have access to it.

### "Item not found"
Verify that:
- The item title matches the environment variable name exactly
- The item has a field named "password", "credential", "text", or "value"

### Service Account Issues
Ensure `OP_SERVICE_ACCOUNT_TOKEN` is set and valid:
```bash
echo $OP_SERVICE_ACCOUNT_TOKEN
op account list
```
