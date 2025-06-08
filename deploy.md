# GitHub Actions CI/CD Workflow Strategy

This document outlines an efficient strategy for CI/CD testing using Docker Compose on GitHub Actions.

### Efficient CI/CD Testing with Docker Compose on GitHub Actions

For a balance of speed, resource efficiency, and ease of modification in CI/CD pipelines, using Docker Compose directly on GitHub Actions runners is a highly effective strategy. This approach mirrors local development setups and avoids the overhead of spinning up a Kubernetes cluster for every test run.

1.  **GitHub Actions Workflow Trigger**: Configure workflows to run on pushes to main branches, pull requests, or specific tags.

2.  **Runner Environment**: Utilize standard GitHub-hosted Linux runners (e.g., `ubuntu-latest`). These runners come with Docker and Docker Compose pre-installed.

3.  **Checkout Code**: Use the `actions/checkout` action to get the source code.

4.  **Secrets Management for CI with Docker Compose**:
    *   **OpenBao in Docker Compose**: Define OpenBao as a service in your `docker-compose.yml` file. Include a health check to ensure it's ready before other services start.
    *   **Initial OpenBao Secrets**: Store critical OpenBao bootstrap secrets (e.g., initial root token for development/CI, or pre-generated AppRole credentials for a CI-specific role that can create other roles/secrets) as **GitHub Actions encrypted secrets**.
    *   **Injecting Bootstrap Secrets**: Pass these GitHub Actions secrets as environment variables to a script or directly to the OpenBao container in `docker-compose.yml` to initialize or unseal it. This script/entrypoint can then configure necessary AppRoles and policies for other services.
    *   **Service Configuration**: Configure your Aria services (also defined in `docker-compose.yml`) to fetch their operational secrets from the OpenBao service within the Docker Compose network (e.g., `http://openbao:8200`).

5.  **Service Orchestration with Docker Compose**:
    *   Maintain a `docker-compose.yml` (and potentially `docker-compose.override.yml` for CI-specific tweaks) in your repository.
    *   This file will define all Aria services, OpenBao, CockroachDB, and any other dependencies.
    *   Use Docker health checks within your `docker-compose.yml` to ensure services are ready before tests run.

6.  **Building and Running Services**:
    *   In your GitHub Actions workflow, use `docker-compose up -d --build` to build (if necessary) and start all services in the background.
    *   Ensure your Dockerfiles are optimized for build caching to speed up this step.

7.  **Running Tests**:
    *   Once all services are reported healthy by Docker Compose, execute your integration, end-to-end, or contract tests.
    *   These tests can be run from a script in the workflow or from another container defined in your Docker Compose setup that has access to the other services.

8.  **Cleanup**:
    *   After tests complete (success or failure), use `docker-compose down -v --remove-orphans` to stop and remove all containers, networks, and volumes created by the compose setup. This ensures a clean environment for the next run.

**Benefits of this Approach**:
*   **Speed**: Significantly faster startup and execution times compared to initializing a Kubernetes cluster (like KinD) within a GitHub Action.
*   **Simplicity**: `docker-compose.yml` files are generally simpler to write and maintain than Kubernetes manifests, especially for CI environments where full production parity might not be the primary goal.
*   **Resource Efficiency**: Consumes fewer resources on the GitHub Actions runner compared to running Kubernetes.
*   **Consistency**: Aligns CI testing environment closely with local Docker Compose-based development environments.
*   **Ease of Modification**: Quickly change service configurations, add new services, or modify test setups by editing the Docker Compose files.

For most CI scenarios focusing on application logic, service interaction, and secrets management integration, Docker Compose provides an optimal balance.
