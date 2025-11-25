# Adding Projects to the Universal Bootstrapper

This guide explains how to prepare your project to be compatible with the Universal Project Bootstrapper.

## 1. Create `project.bootstrap.json`

Create a file named `project.bootstrap.json` in the root of your repository. This file defines your project's configuration.

### Example Configuration

```json
{
  "name": "my-awesome-project",
  "type": "spring-boot",
  "dependencies": {
    "system": ["docker", "docker-compose", "git"],
    "runtime": ["java-17"]
  },
  "secrets": {
    "vault": "my-project-prod",
    "required": [
      "DATABASE_URL",
      "API_KEY"
    ]
  },
  "aliases": {
    "deploy": "./deploy.sh",
    "logs": "docker-compose logs -f app"
  },
  "hooks": {
    "post-clone": "./setup.sh",
    "post-deploy": "echo 'Deployed!'"
  }
}
```

### Configuration Fields

| Field | Description | Required |
|-------|-------------|----------|
| `name` | Project name | Yes |
| `type` | Project type (`spring-boot`, `nodejs`, `python`, `generic`) | Yes |
| `dependencies.system` | System packages to install (e.g., `docker`) | No |
| `dependencies.runtime` | Runtime environments (e.g., `java-17`, `node-18`) | No |
| `secrets.vault` | Default 1Password vault name | No |
| `secrets.required` | List of required environment variables | No |
| `aliases` | Custom shell aliases mapping | No |
| `hooks` | Commands to run at specific lifecycle events | No |

## 2. Create Deployment Scripts

Ensure your project has scripts for common operations. We recommend:

- `deploy.sh`: Handles building and starting the application
- `setup.sh`: Handles initial setup (permissions, directories)

Make sure these scripts are executable (`chmod +x`).

## 3. Configure Secrets in 1Password

1. Create a vault in 1Password (e.g., `my-project-prod`).
2. Add items for each secret required by your project.
   - The item title should match the environment variable name (e.g., `DATABASE_URL`).
   - The value should be in a field named "password", "credential", "text", or "value".

## 4. Test Compatibility

Run the bootstrapper locally to verify everything works:

```bash
bootstrap . --env=dev --skip-deploy
```

(Assuming you are in the project directory, or pass the path/URL)
