# Universal Project Bootstrapper - User Guide

## Introduction

The Universal Project Bootstrapper is a powerful tool designed to automate the setup and deployment of your projects. With a single command, you can clone a repository, install dependencies, configure secrets from 1Password, and deploy your application.

## Installation

To install the bootstrapper on your system (or server), run:

```bash
curl -sSL https://bootstrap.ihabfallahy.dev/install | bash
```

This will install `bootstrap.sh` to `/usr/local/bin/bootstrap` (or similar) and setup necessary directories.

## Basic Usage

The simplest way to use the bootstrapper is to provide the project name:

```bash
bootstrap dynamoss
```

This command will:
1. Clone `https://github.com/ihabfallahy2/dynamoss`
2. Detect the project type (e.g., Spring Boot)
3. Install required dependencies (Docker, Java, etc.)
4. Configure secrets from the default 1Password vault
5. Deploy the application

## Advanced Usage

### Specifying Environment

You can specify the target environment (prod, dev, staging) using the `--env` flag:

```bash
bootstrap dynamoss --env=dev
```

This will look for secrets in the `dynamoss-dev` vault (or configured equivalent).

### Custom Vault

If your secrets are in a specific vault, you can specify it:

```bash
bootstrap dynamoss --vault="My Custom Vault"
```

### Custom Directory

To clone into a specific directory:

```bash
bootstrap dynamoss --dir=/opt/projects/dynamoss
```

### Specific Branch

To checkout a specific git branch:

```bash
bootstrap dynamoss --branch=feature/new-ui
```

### Non-Interactive Mode

For CI/CD pipelines or automated scripts, use the `--non-interactive` flag to disable user prompts:

```bash
bootstrap dynamoss --non-interactive
```

### Skip Deployment

If you only want to setup the project but not deploy it immediately:

```bash
bootstrap dynamoss --skip-deploy
```

## Global Aliases

The bootstrapper automatically configures shell aliases for your projects. After running the bootstrapper, reload your shell config (`source ~/.bashrc` or `source ~/.zshrc`) to use them.

Common aliases (may vary by project):
- `deploy`: Re-deploy the application
- `logs`: View application logs
- `status`: Check service status
- `stop`: Stop the application
- `restart`: Restart the application

## 1Password Integration

The bootstrapper relies on 1Password for secret management. Ensure you have:
1. A 1Password account
2. The 1Password CLI (`op`) installed (the bootstrapper can install it for you)
3. A vault containing your project secrets

The bootstrapper will try to find secrets in 1Password that match the required environment variables defined in your project's `project.bootstrap.json`.

## Discord Notifications

To enable Discord notifications:
1. Create a Webhook in your Discord channel
2. Add the `DISCORD_WEBHOOK_URL` secret to your 1Password vault (or environment)
3. The bootstrapper will automatically notify you on deploy start, success, or failure.

## Troubleshooting

If you encounter issues, run with the `--verbose` flag for detailed logs:

```bash
bootstrap dynamoss --verbose
```

Check `docs/TROUBLESHOOTING.md` for more solutions.
