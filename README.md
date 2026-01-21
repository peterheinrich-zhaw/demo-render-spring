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
- [Deploying to Render](#deploying-to-render)

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
- Automatic deployment to Render.com on new release

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
docker compose up
```

- Exposes:
  - App: `8080`
  - Postgres: `5432`
- `docker/db/init` contains SQL for demo data

### Notes

- `debug` image allows shell access for debugging:

```bash
docker compose run --service-ports --entrypoint sh app
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
  5. On release deploy to Render

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


## Deploying to Render

This section describes all steps and best practices for deploying the Spring Boot app to Render using the prod Docker image.

### 1. Set Up a Render Web Service

- Go to your Render dashboard and create a new Web Service.
- Select Docker as the environment.
- Connect your GitHub repository containing the project.
- Render will build the Docker image from your Dockerfile.

### 2. Configure Environment Variables

Add the following Environment Variables under the Web Service settings:

```bash
 SPRING_PROFILES_ACTIVE=prod
 SPRING_DATASOURCE_URL=jdbc:postgresql://<host>:5432/app
 SPRING_DATASOURCE_USERNAME=<user>
 SPRING_DATASOURCE_PASSWORD=<password>
```

Render automatically sets a PORT environment variable that your app must use.

### 3. Spring Boot Configuration for Dynamic Port

In src/main/resources/application-prod.yml, configure Spring Boot to use the PORT variable provided by Render:

```yaml 
server: 
    port: ${PORT:8080} 
spring: 
    datasource: 
        url: ${SPRING_DATASOURCE_URL} 
        username: ${SPRING_DATASOURCE_USERNAME} 
        password: ${SPRING_DATASOURCE_PASSWORD}
```

This ensures the app listens on the port Render expects.

### 4. Flyway Database Migrations

- Flyway is included in the prod build and will automatically run migrations on startup.
- Make sure migration scripts are placed under src/main/resources/db/migration with names like V1__init.sql.
- No manual intervention is needed; when the container starts, Flyway initializes the database schema.


### 6. Multi-Stage Docker Considerations

- The prod stage uses a distroless image for minimal size and security.
- All dependencies, including Flyway, are included in the JAR built in the build stage.
- The container runs as a non-root user for security.

### 7. Deployment Flow Summary

1. Render builds the Docker image from your repository.
2. Container starts using the prod profile.
3. Spring Boot reads environment variables (DB credentials, PORT).
4. Flyway automatically runs migrations on the PostgreSQL database.
5. App listens on the port provided by Render and is fully operational.

### 8. Manual Deployment via GitHub Actions

The Render Web Service is set to Manual Deployment mode. This ensures that deployments only happen when explicitly triggered, rather than on every push to the repository.

In this project, we use a GitHub Actions workflow that runs CI (build & test) on every push and pull_request, but only triggers a deployment when a release is created.

The workflow includes a deploy job which:

 1. Checks out the repository.
 2. Uses a Render Deploy Hook URL stored securely in GitHub Secrets (RENDER_DEPLOYMENT_HOOK_URL).
 3. Sends a curl request to that URL to trigger the Render deployment.

Example configuration snippet from .github/workflows/ci.yml:

```yaml 
deploy: 
    name: Deploy 
    runs-on: ubuntu-latest 
    needs: build-test 
    if: github.event_name == 'release' 
    steps: 
     - name: Checkout code 
       uses: actions/checkout@v4 
     - name: Deploy 
       env: 
        deploy_url: ${{ secrets.RENDER_DEPLOYMENT_HOOK_URL }} 
       run: | 
        curl "$deploy_url"
```

This approach ensures that production deployments are controlled and only happen when a release is created, while all other pushes and pull requests are tested but not deployed.

## References

- [Spring Boot 3](https://spring.io/projects/spring-boot)
- [Docker Multi-Stage Builds](https://docs.docker.com/develop/develop-images/multistage-build/)
- [Render.com Docker Deploy](https://render.com/docs/deploy-docker)
- [Dorny Test Reporter](https://github.com/dorny/test-reporter)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
