# Truck Signs API
 
## Table of Contents
 
- [Description](#description)
- [Quickstart](#quickstart)
- [Usage](#usage)
  - [Environment Variables](#environment-variables)
  - [Running with Docker Compose](#running-with-docker-compose)
  - [Running with Docker Run](#running-with-docker-run)
  - [Building the Image Manually](#building-the-image-manually-without-docker-compose)
  - [Customizing the Configuration](#customizing-the-configuration)  
## Description
 
The Truck Signs API is a Django-based REST API for managing truck sign data. This repository contains everything needed to build and run the application in a containerized environment:
 
- `Dockerfile` — builds the Django application image
- `docker-compose.yml` — orchestrates the backend service together with a PostgreSQL database
- `entrypoint.sh` — handles startup tasks such as waiting for the database, running migrations, and creating an initial superuser
The application is served via Gunicorn as a WSGI application and uses PostgreSQL as its database backend in production.
 
## Quickstart

Before you start, make sure you have Docker (version 20.10 or later) installed, and a `.env` file with the required environment variables (see [Environment Variables](#environment-variables)).

### How to Build the Image

Build the backend image locally:

```bash
docker build -t truck-signs-api:latest .
```

This builds the Django application image using the `Dockerfile` in the project root. The database image (`postgres:16-alpine`) is pulled directly from Docker Hub and does not need to be built.

### Starting the Application

```bash
docker compose up -d
```

This starts both the backend and the PostgreSQL database on a shared network. Once running, the API is reachable at `http://<host>:8020`.

To stop the application:

```bash
docker compose down
```
 
## Usage
 
### Environment Variables
 
The application is configured entirely through environment variables, provided via a `.env` file (not committed to the repository). Example:
 
```env
MODE=prod
DEBUG_ENABLED=False
SECRET_KEY=<your-secret-key>
 
DB_NAME=<your-db-name>
DB_USER=<your-db-user>
DB_PASSWORD=<your-db-password>
DB_HOST=tsa_db
DB_PORT=5432
 
ALLOWED_HOSTS=localhost,127.0.0.1,<your-domain-or-ip>
CORS_ALLOWED_ORIGINS=http://localhost:3000
 
DJANGO_SUPERUSER_USERNAME=<admin-username>
DJANGO_SUPERUSER_EMAIL=<admin-email>
DJANGO_SUPERUSER_PASSWORD=<admin-password>
```
 
| Variable | Description |
|---|---|
| `MODE` | `prod` uses PostgreSQL; any other value falls back to SQLite for local development |
| `DEBUG_ENABLED` | Enables/disables Django debug mode |
| `SECRET_KEY` | Django secret key |
| `DB_NAME` / `DB_USER` / `DB_PASSWORD` | PostgreSQL credentials |
| `DB_HOST` / `DB_PORT` | PostgreSQL host and port (service name and port when using Docker Compose) |
| `ALLOWED_HOSTS` | Comma-separated list of allowed hostnames |
| `CORS_ALLOWED_ORIGINS` | Comma-separated list of allowed CORS origins |
| `DJANGO_SUPERUSER_USERNAME` / `_EMAIL` / `_PASSWORD` | Credentials for the automatically created superuser |
 
### Running with Docker Compose
 
This is the recommended way to run the application, as it automatically sets up both the backend and the PostgreSQL database on a shared network:
 
```bash
docker compose up -d
```
 
To stop the application:
 
```bash
docker compose down
```
 
Database data persists across restarts thanks to a named Docker volume (`postgres_data`).
 
### Running with Docker Run
 
If you want to run the backend container standalone (e.g. against an already running database), you can use `docker run` directly. Replace the placeholder values with your actual configuration:
 
```bash
docker run -d \
  --name tsa_backend \
  -p 8020:8000 \
  -e MODE=prod \
  -e DEBUG_ENABLED=False \
  -e SECRET_KEY=<your-secret-key> \
  -e DB_NAME=<your-db-name> \
  -e DB_USER=<your-db-user> \
  -e DB_PASSWORD=<your-db-password> \
  -e DB_HOST=<your-db-host> \
  -e DB_PORT=5432 \
  -e ALLOWED_HOSTS=localhost,127.0.0.1,<your-domain-or-ip> \
  -e DJANGO_SUPERUSER_USERNAME=<admin-username> \
  -e DJANGO_SUPERUSER_EMAIL=<admin-email> \
  -e DJANGO_SUPERUSER_PASSWORD=<admin-password> \
  truck-signs-api:latest
```

### Building the Image Manually (without Docker Compose)

Build the backend image locally:

```bash
docker build -t truck-signs-api:latest .
```

This builds the Django application image using the `Dockerfile` in the project root. The database image (`postgres:16-alpine`) is pulled directly from Docker Hub and does not need to be built.

### Running the Application

Create a shared network and a named volume for the database:

```bash
docker network create tsa-network
docker volume create postgres_data
```

Start the database container:

```bash
docker run -d \
  --name tsa_db \
  --network tsa-network \
  --restart unless-stopped \
  --env-file .env \
  -v postgres_data:/var/lib/postgresql/data \
  postgres:16-alpine
```

Start the backend container:

```bash
docker run -d \
  --name tsa_backend \
  --network tsa-network \
  --restart unless-stopped \
  --env-file .env \
  -p 8020:8000 \
  -v ./src/staticfiles:/app/src/staticfiles \
  -v ./src/media:/app/src/media \
  truck-signs-api:latest
```

Once running, the API is reachable at `http://<host>:8020`.
 
### Customizing the Configuration
 
- **Changing the exposed port**: The container internally serves the application on port `8000` (see `EXPOSE 8000` in the `Dockerfile` and the Gunicorn bind address). To expose it on a different host port, adjust the port mapping, e.g. `-p 9000:8000` for `docker run`, or the `ports` entry under the `backend` service in `docker-compose.yml`.
- **Switching between development and production database**: Setting `MODE` to anything other than `prod` switches the application to a local SQLite database, useful for local development without PostgreSQL.
- **Adjusting Gunicorn workers**: The number of Gunicorn worker processes is set in the `command` of the `backend` service in `docker-compose.yml` (`--workers 4`). Increase or decrease this value based on the resources available on your host.
- **Database persistence**: Database files are stored in the named volume `postgres_data`, which is managed by Docker and survives container restarts. No host bind-mount is used for the database, in line with best practices for data persistence and isolation.