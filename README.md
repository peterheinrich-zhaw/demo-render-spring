# demo-render-spring

[![CI](https://github.com/peterheinrich-zhaw/demo-render-spring/actions/workflows/ci.yml/badge.svg)](
https://github.com/peterheinrich-zhaw/demo-render-spring/actions/workflows/ci.yml
)

This is a minimal Spring Boot demo application designed for local development, Docker-based testing, and deployment to Render.com. The project also includes a CI workflow with GitHub Actions and JUnit test reporting using [dorny/test-reporter](https://github.com/dorny/test-reporter).

---

## Table of Contents

- [Project Overview](#project-overview)
- [Profiles](#profiles)
- [Running Locally](#running-locally)
- [Docker Setup](#docker-setup)
- [CI / GitHub Actions](#ci--github-actions)
- [Testing](#testing)
- [Deploying](#deploying)
- [Badges](#badges)

---

## Project Overview

This project demonstrates:

- Spring Boot 3.5 with Java 21
- Multi-profile configuration:
  - H2 for local dev
  - PostgreSQL for Docker testing
  - PostgreSQL with environment variables for production
- Docker multi-stage build:
  - `debug` stage with shell and JDK
  - `prod` stage with distroless image for production
- GitHub Actions CI with Maven tests
- GitHub-integrated test reporting via Dorny

---

## Profiles

| Profile | Description |
|---------|-------------|
| `local` | Uses H2 in-memory database and `data.sql` for demo data. No external infrastructure needed. |
| `docker` | Uses PostgreSQL in Docker with demo data and standard passwords. Multi-stage build with debug shell. |
| `prod` | Uses PostgreSQL on Render.com with credentials from environment variables. Minimal distroless image. |

You can activate profiles using:

```bash
SPRING_PROFILES_ACTIVE=local mvn spring-boot:run
```

or

```bash
docker run -e SPRING_PROFILES_ACTIVE=docker demo-app:debug
```

---

## Running Locally

### With H2 (no Docker)

```bash
mvn spring-boot:run -Dspring-boot.run.profiles=local
```
Or just revert to the default profile by not specifying any:

```bash
mvn spring-boot:run 
```

Your app will start on `http://localhost:8080` with H2 database.

---

## Docker Setup

### Build Multi-Stage Images

```bash
# Build app
docker build -t demo-app:debug -f Dockerfile .

# Optionally build production image
docker build -t demo-app:prod --target prod -f Dockerfile .
```

### Docker Compose (PostgreSQL + App)

```bash
docker-compose up
```

- Exposes:
  - App: `8080`
  - Postgres: `5432`
- `docker/db/init` contains SQL for demo data

### Notes

- `debug` image allows shell access for debugging:

```bash
docker run -it demo-app:debug sh
```

- `prod` image is distroless; no shell available.

---

## CI / GitHub Actions

- Workflow: `.github/workflows/ci.yml`
- Runs on every `push` and `pull_request`
- Steps:
  1. Checkout code
  2. Set up Java 21 with Maven cache
  3. Run tests: `mvn test`
  4. Publish JUnit report via `dorny/test-reporter`

### Example CI Badge

```markdown
[![CI](https://github.com/OWNER/REPO/actions/workflows/ci.yml/badge.svg)](
https://github.com/OWNER/REPO/actions/workflows/ci.yml
)
```

Replace `OWNER` and `REPO` with your GitHub username and repository.

---

## Testing

- Maven runs tests automatically:

```bash
mvn test
```

- JUnit XML reports are generated at:

```
target/surefire-reports/*.xml
```

- Dorny reads these reports and shows results in:
  - Pull Requests
  - Commit status
  - GitHub Actions tab

- The reporter runs **always**, but **not for PRs from forks**, for security.

---

## Deploying

- Deploy to Render.com using the `prod` Docker image
- Database credentials and URLs should be set via environment variables on Render
- Multi-stage build ensures the prod image is minimal and secure

Example environment variables:

```
SPRING_DATASOURCE_URL=jdbc:postgresql://<host>:5432/app
SPRING_DATASOURCE_USERNAME=<user>
SPRING_DATASOURCE_PASSWORD=<password>
```

---

## References

- [Spring Boot 3](https://spring.io/projects/spring-boot)
- [Docker Multi-Stage Builds](https://docs.docker.com/develop/develop-images/multistage-build/)
- [Render.com Docker Deploy](https://render.com/docs/deploy-docker)
- [Dorny Test Reporter](https://github.com/dorny/test-reporter)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

## Notes

- The app runs as a non-root user in Docker for security.
- CI is required for merges to `main` (Branch Protection recommended).
- Smoke tests and integration with PostgreSQL will be added later.
