# Prompt: Universal Project Bootstrapper - Sistema Definitivo de Deploy

## 🎯 Visión Ultimate

Quiero crear **EL SCRIPT DEFINITIVO** que me permita, en un servidor Linux limpio, ejecutar **UN SOLO COMANDO** y que automáticamente:

1. **Clone cualquier repositorio mío** (solo pasando el nombre)
2. **Instale todas las dependencias** (Docker, Node, Java, Python, etc.)
3. **Configure secretos desde 1Password** automáticamente
4. **Configure alias globales** (deploy, dlogs, etc.)
5. **Levante todo el stack** (bases de datos, servicios, etc.)
6. **Deje todo listo** para que yo solo ejecute `deploy` o `dlogs`

### Ejemplo de Uso Ideal

```bash
# En un servidor Linux limpio
curl -sSL https://raw.githubusercontent.com/ihabfallahy2/bootstrap/main/bootstrap.sh | bash -s dynamoss

# O con más control
./bootstrap.sh --repo=dynamoss --vault="Production" --env=prod

# Y listo, todo configurado. Solo queda:
deploy
dlogs
```

## 🔗 Conversación Previa con ChatGPT

He discutido una idea inicial aquí: https://chatgpt.com/share/692597b6-7568-8010-b7e5-c494c7920e74

La idea principal era usar **1Password CLI** para centralizar secretos y automatizar su inyección en los proyectos.

## 📚 Sistema Actual en DYNAMOSS (Referencia)

Actualmente tengo implementado en DYNAMOSS un sistema que funciona bien, pero quiero **generalizarlo y mejorarlo**:

### 1. Estructura de Archivos
```
.
├── .env                    # Secretos locales (gitignored)
├── .env.example            # Plantilla con valores de ejemplo
├── docker-compose.yml      # Configuración Docker con referencias a ${VARIABLES}
├── configure.sh            # Script interactivo de configuración
├── deploy.sh               # Script de despliegue
└── setup.sh                # Script de setup inicial
```

### 2. Flujo Actual
1. Usuario clona el repo
2. Ejecuta `./configure.sh` (script interactivo)
3. El script pregunta por cada secreto uno a uno
4. Detecta valores existentes y pregunta si mantenerlos
5. Crea backups automáticos
6. Genera `.env` con todos los secretos
7. Despliega automáticamente con Docker Compose

### 3. Características del Sistema Actual
- ✅ Configuración interactiva (sin editar archivos manualmente)
- ✅ Detección de valores existentes
- ✅ Backups automáticos
- ✅ Modo secreto para contraseñas (oculta input)
- ✅ Validación de Docker
- ✅ Despliegue automático
- ✅ `.env` nunca se sube al repo (gitignored)

### 4. Variables de Entorno en DYNAMOSS
El proyecto usa estas categorías de secretos:
- MongoDB (URI, database)
- Spring Security (usuario/password API)
- F95Zone (credenciales de scraping)
- RPDL API (configuración)
- Configuración de servidor (puerto, perfil)

## Objetivo del Sistema Universal Bootstrapper

### 🚀 Funcionalidad Principal

Un **script maestro** (`bootstrap.sh`) que:

#### 1. Detección Automática del Proyecto
```bash
./bootstrap.sh dynamoss
# Automáticamente detecta:
# - Es un proyecto Spring Boot (Java)
# - Necesita Docker
# - Usa MongoDB
# - Tiene secretos en 1Password vault "dynamoss-prod"
```

#### 2. Instalación de Dependencias
```bash
# El script detecta qué falta e instala:
- Docker & Docker Compose
- Git
- 1Password CLI
- Java/Node/Python (según el proyecto)
- Cualquier otra dependencia específica
```

#### 3. Clonado Inteligente
```bash
# Soporta múltiples formatos:
./bootstrap.sh dynamoss                    # Asume github.com/ihabfallahy2/dynamoss
./bootstrap.sh ihabfallahy2/dynamoss       # GitHub explícito
./bootstrap.sh https://github.com/user/repo # URL completa
./bootstrap.sh gitlab:user/repo            # Otros providers
```

#### 4. Configuración Automática de Secretos
```bash
# Lee de 1Password automáticamente:
# 1. Busca vault del proyecto
# 2. Lee todos los secretos necesarios
# 3. Genera .env automáticamente
# 4. No requiere input del usuario
```

#### 5. Setup del Entorno
```bash
# Configura todo automáticamente:
- Alias globales (deploy, dlogs, dstatus, etc.)
- Permisos de Docker
- Variables de entorno del shell
- Git hooks (si existen)
```

#### 6. Levantamiento del Stack
```bash
# Inicia todo automáticamente:
- Bases de datos (MongoDB, PostgreSQL, etc.)
- Servicios de caché (Redis, etc.)
- La aplicación principal
- Servicios auxiliares
```

### 📋 Flujo Completo del Bootstrapper

```mermaid
graph TD
    A[Usuario ejecuta bootstrap.sh] --> B{Servidor limpio?}
    B -->|Sí| C[Instalar dependencias base]
    B -->|No| D[Verificar dependencias]
    C --> E[Clonar repositorio]
    D --> E
    E --> F[Detectar tipo de proyecto]
    F --> G[Leer project.bootstrap.json]
    G --> H[Instalar deps específicas]
    H --> I[Conectar con 1Password]
    I --> J[Generar .env desde secretos]
    J --> K[Configurar alias globales]
    K --> L[Ejecutar setup.sh del proyecto]
    L --> M[Levantar stack completo]
    M --> N[Verificar que todo funciona]
    N --> O[✅ Listo para usar]
```

### 🗂️ Estructura del Proyecto Bootstrap

```
bootstrap/                          # Repo universal
├── bootstrap.sh                    # Script maestro
├── lib/
│   ├── detect.sh                   # Detección de proyecto
│   ├── install.sh                  # Instalación de deps
│   ├── secrets.sh                  # Gestión de secretos
│   ├── git.sh                      # Operaciones Git
│   └── aliases.sh                  # Configuración de alias
├── templates/
│   ├── spring-boot/                # Template Spring Boot
│   ├── nodejs/                     # Template Node.js
│   ├── python/                     # Template Python
│   └── generic/                    # Template genérico
├── docs/
│   ├── USAGE.md                    # Guía de uso
│   ├── ADDING_PROJECTS.md          # Cómo agregar proyectos
│   └── TROUBLESHOOTING.md          # Solución de problemas
└── README.md
```

### 📄 Archivo de Configuración del Proyecto

Cada proyecto tendrá un `project.bootstrap.json`:

```json
{
  "name": "dynamoss",
  "type": "spring-boot",
  "repository": "https://github.com/ihabfallahy2/dynamoss",
  "dependencies": {
    "system": ["docker", "docker-compose", "git"],
    "runtime": ["java-17"],
    "optional": ["1password-cli"]
  },
  "secrets": {
    "vault": "dynamoss-prod",
    "required": [
      "MONGODB_URI",
      "VAULT_USER",
      "VAULT_PASS",
      "F95_USERNAME",
      "F95_PASSWORD"
    ]
  },
  "services": {
    "databases": ["mongodb"],
    "cache": [],
    "other": []
  },
  "aliases": {
    "deploy": "cd ~/projects/dynamoss && make deploy",
    "dlogs": "cd ~/projects/dynamoss && make logs-app",
    "dstatus": "cd ~/projects/dynamoss && make status"
  },
  "hooks": {
    "post-clone": "./setup.sh",
    "post-secrets": "./configure.sh --auto",
    "post-deploy": "echo 'DYNAMOSS deployed successfully!'"
  }
}
```

### 🎯 Casos de Uso del Bootstrapper

#### Caso 1: Servidor Nuevo (Producción)
```bash
# SSH al servidor nuevo
ssh user@production-server

# Ejecutar bootstrapper
curl -sSL https://bootstrap.ihabfallahy.dev/install | bash -s dynamoss --env=prod

# Esperar 2-5 minutos...
# ✅ Todo listo, aplicación corriendo
```

#### Caso 2: Desarrollo Local
```bash
# En tu laptop
./bootstrap.sh dynamoss --env=dev --vault="Development"

# Configura todo para desarrollo local
# Usa secretos de desarrollo
```

#### Caso 3: Múltiples Proyectos
```bash
# Configurar varios proyectos en el mismo servidor
./bootstrap.sh dynamoss --dir=/opt/dynamoss
./bootstrap.sh mi-api --dir=/opt/mi-api
./bootstrap.sh frontend --dir=/opt/frontend

# Cada uno con sus propios alias:
# dynamoss-deploy, api-deploy, frontend-deploy
```

#### Caso 4: CI/CD
```bash
# En GitHub Actions / GitLab CI
- name: Bootstrap Project
  run: |
    curl -sSL https://bootstrap.ihabfallahy.dev/install | \
    bash -s ${{ github.repository }} --env=ci --non-interactive
```

### 🔐 Integración con 1Password

#### Estructura en 1Password
```
Vaults:
├── dynamoss-prod/
│   ├── MONGODB_URI
│   ├── VAULT_USER
│   ├── VAULT_PASS
│   ├── F95_USERNAME
│   └── F95_PASSWORD
├── dynamoss-dev/
│   └── (mismos secretos con valores de dev)
└── shared/
    └── (secretos compartidos entre proyectos)
```

#### Comando de Lectura Automática
```bash
# El bootstrapper ejecuta internamente:
op item list --vault="dynamoss-prod" --format=json | \
  jq -r '.[] | "\(.title)=\(.fields[] | select(.label=="password").value)"' \
  > .env
```

### 📢 Notificaciones Discord

#### Integración con Discord Webhooks
El bootstrapper debe soportar notificaciones a Discord para eventos importantes:

```json
// En project.bootstrap.json
{
  "notifications": {
    "discord": {
      "webhook_url": "${DISCORD_WEBHOOK_URL}",
      "events": [
        "deploy-start",
        "deploy-success",
        "deploy-failure",
        "health-check-failed",
        "secrets-updated"
      ],
      "mention_on_failure": "@DevOps"
    }
  }
}
```

#### Mensajes de Discord
```bash
# Deploy iniciado
🚀 **DYNAMOSS Deploy Started**
Environment: Production
Branch: main
Commit: abc123f
Triggered by: @usuario

# Deploy exitoso
✅ **DYNAMOSS Deploy Successful**
Environment: Production
Duration: 2m 34s
Health Check: ✅ Passed
URL: https://dynamoss.example.com

# Deploy fallido
❌ **DYNAMOSS Deploy Failed**
Environment: Production
Error: Database connection timeout
Logs: [View Logs](https://logs.example.com)
@DevOps
```

### 🔄 Auto-Deploy con Git Hooks

#### Git Hooks Automáticos
El bootstrapper debe configurar hooks de Git para auto-deploy:

```bash
# .git/hooks/post-receive (en servidor)
#!/bin/bash
echo "🔄 New commit detected, auto-deploying..."

# Notificar a Discord
curl -X POST $DISCORD_WEBHOOK_URL \
  -H "Content-Type: application/json" \
  -d '{
    "content": "🔄 **Auto-Deploy Triggered**\nCommit: '"$(git log -1 --pretty=%B)"'\nAuthor: '"$(git log -1 --pretty=%an)"'"
  }'

# Ejecutar deploy
cd /path/to/project
./deploy.sh

# Notificar resultado
if [ $? -eq 0 ]; then
  curl -X POST $DISCORD_WEBHOOK_URL \
    -H "Content-Type: application/json" \
    -d '{"content": "✅ **Auto-Deploy Successful**"}'
else
  curl -X POST $DISCORD_WEBHOOK_URL \
    -H "Content-Type: application/json" \
    -d '{"content": "❌ **Auto-Deploy Failed** @DevOps"}'
fi
```

#### GitHub Webhooks (Alternativa)
```json
// En project.bootstrap.json
{
  "auto_deploy": {
    "enabled": true,
    "trigger": "push",
    "branches": ["main", "production"],
    "webhook": {
      "type": "github",
      "secret": "${GITHUB_WEBHOOK_SECRET}"
    },
    "pre_deploy_checks": [
      "tests-passing",
      "no-conflicts",
      "approved-pr"
    ],
    "rollback_on_failure": true
  }
}
```

#### Servidor de Webhooks
El bootstrapper debe incluir un pequeño servidor para recibir webhooks:

```bash
# lib/webhook-server.sh
# Servidor simple que escucha webhooks de GitHub/GitLab
# Puerto: 9000 (configurable)
# Ruta: /webhook/deploy

# Cuando recibe un webhook:
# 1. Valida el secret
# 2. Verifica la rama
# 3. Notifica a Discord (deploy iniciado)
# 4. Ejecuta git pull
# 5. Ejecuta deploy.sh
# 6. Notifica resultado a Discord
```

### 🔔 Sistema de Notificaciones Completo

```json
// project.bootstrap.json - Sección completa de notificaciones
{
  "notifications": {
    "discord": {
      "enabled": true,
      "webhook_url": "${DISCORD_WEBHOOK_URL}",
      "events": {
        "deploy": {
          "start": true,
          "success": true,
          "failure": true,
          "mention_on_failure": "@DevOps"
        },
        "health_check": {
          "failed": true,
          "recovered": true
        },
        "secrets": {
          "updated": true,
          "rotation_needed": true
        },
        "errors": {
          "critical": true,
          "mention": "@OnCall"
        }
      },
      "format": "rich",  // rich | simple
      "include_logs": true,
      "max_log_lines": 50
    },
    "email": {
      "enabled": false,
      "smtp_server": "${SMTP_SERVER}",
      "recipients": ["admin@example.com"]
    },
    "slack": {
      "enabled": false,
      "webhook_url": "${SLACK_WEBHOOK_URL}"
    }
  }
}
```

### Requisitos Funcionales
1. **Centralización de Secretos**
   - Usar 1Password como fuente única de verdad
   - Organizar secretos por proyecto/entorno
   - Versionado de secretos

2. **Automatización**
   - Script que lea de 1Password y genere `.env` automáticamente
   - No requerir edición manual de archivos
   - Integración con flujo de CI/CD

3. **Compatibilidad**
   - Funcionar con el sistema interactivo actual de DYNAMOSS
   - Permitir modo "manual" (sin 1Password) para desarrollo local
   - Soportar múltiples entornos (dev, staging, prod)

4. **Reutilización**
   - Template/boilerplate para nuevos proyectos
   - Estructura estándar de archivos
   - Scripts genéricos adaptables

5. **Seguridad**
   - Secretos nunca en el repo
   - Encriptación en tránsito
   - Auditoría de accesos (via 1Password)

### Casos de Uso

#### Caso 1: Nuevo Proyecto
```bash
# Clonar template
git clone https://github.com/usuario/project-template.git mi-proyecto
cd mi-proyecto

# Configurar con 1Password
./setup-secrets.sh --vault="Mi Vault" --project="mi-proyecto"

# Desplegar
./deploy.sh
```

#### Caso 2: Proyecto Existente (como DYNAMOSS)
```bash
# Migrar a 1Password (opcional)
./migrate-to-1password.sh

# O seguir usando modo interactivo
./configure.sh
```

#### Caso 3: CI/CD
```bash
# En GitHub Actions / GitLab CI
- name: Setup Secrets
  run: ./setup-secrets.sh --vault="CI" --env="prod" --non-interactive
```

## Estructura Propuesta

### Archivos del Sistema
```
.secrets/
├── secrets.schema.json      # Schema de secretos requeridos
├── 1password.config.json    # Configuración de 1Password
├── setup-secrets.sh          # Script principal
├── migrate-to-1password.sh  # Migración desde .env
└── validate-secrets.sh       # Validación de secretos

.env.example                  # Template (como ahora)
.env                          # Generado automáticamente (gitignored)
configure.sh                  # Modo interactivo (fallback)
```

### secrets.schema.json
Define qué secretos necesita el proyecto:
```json
{
  "project": "dynamoss",
  "version": "1.0",
  "secrets": [
    {
      "name": "MONGODB_URI",
      "description": "MongoDB connection string",
      "required": true,
      "category": "database",
      "example": "mongodb+srv://user:pass@cluster.mongodb.net/db"
    },
    {
      "name": "VAULT_USER",
      "description": "API authentication username",
      "required": true,
      "category": "security"
    }
  ]
}
```

## Preguntas para el Diseño

1. **Organización en 1Password**
   - ¿Cómo estructurar vaults/items para múltiples proyectos?
   - ¿Un vault por proyecto o por entorno?

2. **Compatibilidad con Sistema Actual**
   - ¿Cómo integrar sin romper el flujo actual de DYNAMOSS?
   - ¿Permitir ambos modos (1Password + manual)?

3. **Template para Nuevos Proyectos**
   - ¿Qué archivos incluir en el template?
   - ¿Cómo hacer el template agnóstico del stack tecnológico?

4. **Migración**
   - ¿Cómo migrar proyectos existentes a este sistema?
   - ¿Script de migración automática?

5. **Fallbacks**
   - ¿Qué hacer si 1Password no está disponible?
   - ¿Modo offline?

## Entregables Esperados

Por favor, diseña e implementa el **Universal Project Bootstrapper**:

### 1. **Script Maestro (`bootstrap.sh`)**
El script principal que orquesta todo:
- Detección automática de proyecto
- Instalación de dependencias
- Clonado de repositorio
- Configuración de secretos
- Setup completo
- Despliegue automático

**Características:**
```bash
# Uso básico
./bootstrap.sh <proyecto>

# Opciones avanzadas
./bootstrap.sh <proyecto> \
  --env=<prod|dev|staging> \
  --vault=<nombre-vault> \
  --dir=<directorio-destino> \
  --branch=<rama-git> \
  --non-interactive \
  --skip-deploy \
  --verbose
```

### 2. **Librería de Utilidades (`lib/`)**

#### `lib/detect.sh`
- Detectar tipo de proyecto (Spring Boot, Node.js, Python, etc.)
- Leer `project.bootstrap.json`
- Identificar dependencias necesarias
- Detectar servicios requeridos (DB, cache, etc.)

#### `lib/install.sh`
- Instalar Docker & Docker Compose
- Instalar 1Password CLI
- Instalar runtimes (Java, Node, Python)
- Instalar herramientas específicas del proyecto
- Verificar instalaciones

#### `lib/secrets.sh`
- Conectar con 1Password
- Leer secretos del vault
- Generar `.env` automáticamente
- Validar secretos requeridos
- Modo fallback (interactivo si 1Password no disponible)

#### `lib/git.sh`
- Clonar repositorio
- Detectar formato de URL
- Checkout de rama específica
- Configurar Git hooks

#### `lib/aliases.sh`
- Configurar alias globales
- Detectar shell (bash/zsh)
- Evitar duplicados
- Recargar configuración

#### `lib/discord.sh`
- Enviar notificaciones a Discord
- Formatear mensajes (rich embeds)
- Menciones en caso de error
- Logs incluidos en mensajes

#### `lib/webhook-server.sh`
- Servidor HTTP simple para recibir webhooks
- Validación de secrets de GitHub/GitLab
- Trigger automático de deploys
- Integración con notificaciones Discord

### 3. **Templates de Proyecto**

#### `templates/spring-boot/`
```
spring-boot/
├── project.bootstrap.json    # Configuración del template
├── .env.example               # Variables de ejemplo
├── docker-compose.yml         # Stack por defecto
├── Dockerfile                 # Build de la app
├── Makefile                   # Comandos comunes
├── setup.sh                   # Setup específico
└── README.md                  # Documentación
```

#### `templates/nodejs/`
Similar estructura para Node.js

#### `templates/python/`
Similar estructura para Python

#### `templates/generic/`
Template mínimo para proyectos custom

### 4. **Archivo de Configuración del Proyecto**

Cada proyecto debe tener `project.bootstrap.json` en la raíz:

```json
{
  "name": "nombre-proyecto",
  "version": "1.0.0",
  "type": "spring-boot|nodejs|python|generic",
  "description": "Descripción del proyecto",
  
  "repository": {
    "url": "https://github.com/user/repo",
    "default_branch": "main"
  },
  
  "dependencies": {
    "system": ["docker", "docker-compose", "git"],
    "runtime": ["java-17", "maven"],
    "optional": ["1password-cli"]
  },
  
  "secrets": {
    "provider": "1password",
    "vault": "proyecto-prod",
    "vault_dev": "proyecto-dev",
    "required": [
      "DATABASE_URL",
      "API_KEY",
      "SECRET_KEY"
    ],
    "optional": [
      "FEATURE_FLAG_X"
    ]
  },
  
  "services": {
    "databases": ["mongodb", "postgresql"],
    "cache": ["redis"],
    "queues": ["rabbitmq"],
    "other": []
  },
  
  "ports": {
    "app": 8080,
    "db": 27017,
    "cache": 6379
  },
  
  "aliases": {
    "deploy": "make deploy",
    "logs": "make logs-app",
    "status": "make status",
    "stop": "make stop",
    "restart": "make restart"
  },
  
  "hooks": {
    "pre-clone": "",
    "post-clone": "./setup.sh",
    "pre-secrets": "",
    "post-secrets": "./configure.sh --auto",
    "pre-deploy": "",
    "post-deploy": "echo 'Deployed successfully!'",
    "health-check": "curl -f http://localhost:8080/actuator/health"
  },
  
  "environment": {
    "prod": {
      "vault": "proyecto-prod",
      "branch": "main",
      "replicas": 3
    },
    "dev": {
      "vault": "proyecto-dev",
      "branch": "develop",
      "replicas": 1
    }
  },
  
  "notifications": {
    "discord": {
      "enabled": true,
      "webhook_url": "${DISCORD_WEBHOOK_URL}",
      "events": {
        "deploy": {
          "start": true,
          "success": true,
          "failure": true,
          "mention_on_failure": "@DevOps"
        },
        "health_check": {
          "failed": true,
          "recovered": true
        }
      },
      "format": "rich"
    }
  },
  
  "auto_deploy": {
    "enabled": true,
    "trigger": "push",
    "branches": ["main", "production"],
    "webhook": {
      "type": "github",
      "port": 9000,
      "secret": "${GITHUB_WEBHOOK_SECRET}"
    },
    "pre_deploy_checks": [
      "tests-passing",
      "no-conflicts"
    ],
    "rollback_on_failure": true,
    "notify_on_deploy": true
  }
}
```

### 5. **Documentación Completa**

#### `docs/USAGE.md`
- Guía de uso del bootstrapper
- Ejemplos de comandos
- Casos de uso comunes
- Troubleshooting

#### `docs/ADDING_PROJECTS.md`
- Cómo preparar un proyecto para el bootstrapper
- Crear `project.bootstrap.json`
- Configurar secretos en 1Password
- Testing del setup

#### `docs/ARCHITECTURE.md`
- Arquitectura del sistema
- Flujo de ejecución
- Componentes y responsabilidades
- Extensibilidad

#### `docs/1PASSWORD_SETUP.md`
- Configuración de 1Password
- Estructura de vaults
- Naming conventions
- Best practices

### 6. **Scripts de Utilidad**

#### `install.sh`
Script de instalación del bootstrapper:
```bash
curl -sSL https://bootstrap.ihabfallahy.dev/install | bash
```

#### `update.sh`
Actualizar el bootstrapper a la última versión

#### `uninstall.sh`
Desinstalar el bootstrapper completamente

### 7. **Testing y Validación**

#### `tests/`
```
tests/
├── test-spring-boot.sh    # Test con proyecto Spring Boot
├── test-nodejs.sh         # Test con proyecto Node.js
├── test-python.sh         # Test con proyecto Python
├── test-clean-server.sh   # Test en servidor limpio
└── test-1password.sh      # Test integración 1Password
```

### 8. **CI/CD Integration**

#### `.github/workflows/bootstrap.yml`
Workflow de ejemplo para GitHub Actions

#### `.gitlab-ci.yml`
Pipeline de ejemplo para GitLab CI

### 9. **Ejemplos de Proyectos**

#### `examples/dynamoss/`
DYNAMOSS como ejemplo completo con:
- `project.bootstrap.json` configurado
- Secretos en 1Password
- Documentación de setup

#### `examples/simple-api/`
API simple como ejemplo mínimo

#### `examples/microservices/`
Ejemplo con múltiples servicios

## Restricciones

- **NO implementar nada en DYNAMOSS** - Es un proyecto existente que funciona
- El sistema debe ser **opcional** - No forzar 1Password
- Debe ser **retrocompatible** - Funcionar con flujos existentes
- **Documentación clara** - Para que pueda implementarlo yo mismo

## Tecnologías

- **1Password CLI** - Gestión de secretos
- **Bash** - Scripts de automatización
- **Docker / Docker Compose** - Despliegue
- **JSON** - Configuración
- Agnóstico del lenguaje de programación del proyecto

## Inspiración

Toma como referencia:
- El sistema actual de DYNAMOSS (configure.sh, deploy.sh)
- Herramientas como dotenv, direnv
- Sistemas de secrets management (Vault, AWS Secrets Manager)
- Pero simplificado y enfocado en 1Password

## Resultado Final

Quiero poder:
1. Clonar un nuevo proyecto desde un template
2. Ejecutar un comando que lea secretos de 1Password
3. Que se genere automáticamente el `.env`
4. Desplegar sin tocar archivos manualmente

Y todo esto debe ser **reutilizable** para cualquier proyecto futuro, no solo DYNAMOSS.

---

## 🎯 Características Clave del Sistema

### 1. **Un Solo Comando para Todo**
```bash
curl -sSL https://bootstrap.ihabfallahy.dev/install | bash -s dynamoss
```

### 2. **Clonado Inteligente**
- Solo pasas el nombre del repo
- Detecta automáticamente el tipo de proyecto
- Instala todas las dependencias necesarias

### 3. **Gestión Automática de Secretos**
- Lee de 1Password automáticamente
- Genera `.env` sin intervención manual
- Soporta múltiples entornos (prod/dev/staging)

### 4. **Notificaciones Discord** 🆕
- Notifica cada deploy (inicio, éxito, fallo)
- Menciones automáticas en caso de error
- Health checks y alertas
- Logs incluidos en mensajes

### 5. **Auto-Deploy con Commits** 🆕
- Webhook server integrado
- Deploy automático al hacer push
- Validación pre-deploy (tests, conflictos)
- Rollback automático en caso de fallo
- Notificaciones Discord de cada deploy

### 6. **Configuración de Alias Globales**
- `deploy`, `dlogs`, `dstatus` automáticos
- Personalizables por proyecto
- Soporta múltiples proyectos en el mismo servidor

### 7. **Multi-Proyecto**
- Gestiona múltiples proyectos en el mismo servidor
- Cada uno con sus propios secretos y alias
- Aislamiento completo entre proyectos

### 8. **CI/CD Ready**
- Integración con GitHub Actions
- Integración con GitLab CI
- Modo no-interactivo para pipelines

---

## 📋 Flujo Completo de Uso

### Primera Vez
```bash
# 1. Instalar bootstrapper
curl -sSL https://bootstrap.ihabfallahy.dev/install | bash

# 2. Configurar proyecto
./bootstrap.sh dynamoss --env=prod

# Esperar 2-5 minutos...
# ✅ Todo listo:
#    - Repo clonado
#    - Dependencias instaladas
#    - Secretos configurados desde 1Password
#    - Alias configurados
#    - Webhook server corriendo
#    - Aplicación desplegada
#    - Discord notificado

# 3. Usar
deploy    # Redesplegar manualmente
dlogs     # Ver logs
dstatus   # Ver estado
```

### Después del Setup
```bash
# En tu laptop, haces un commit
git commit -m "feat: nueva funcionalidad"
git push origin main

# Automáticamente en el servidor:
# 1. Webhook recibe el push
# 2. Discord notifica: "🔄 Auto-Deploy Triggered"
# 3. Git pull automático
# 4. Deploy automático
# 5. Health check
# 6. Discord notifica: "✅ Deploy Successful"

# Tú solo ves las notificaciones en Discord
# Sin tocar el servidor
```

---

## 🚀 Resultado Final

**Objetivo:** Que el usuario **NUNCA** tenga que:
- ❌ Editar archivos manualmente (nano/vim)
- ❌ Recordar comandos complejos
- ❌ SSH al servidor para cada deploy
- ❌ Configurar secretos manualmente
- ❌ Instalar dependencias a mano

**Solo necesita:**
- ✅ Ejecutar `bootstrap.sh` una vez
- ✅ Hacer `git push`
- ✅ Ver notificaciones en Discord
- ✅ Usar alias simples (`deploy`, `dlogs`)

---

**Nota**: Este sistema será la base para todos mis proyectos futuros, así que debe ser robusto, bien documentado y fácil de mantener.
