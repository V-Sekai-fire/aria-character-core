# 🌐 Deployment & Service Management

This section outlines the general strategy for deploying services within the Aria Character Core system, keeping them operational, and securing them, with a primary focus on leveraging OpenBao for secrets management.

### Core Principles

1.  **Process Supervision**: Each service, including third-party dependencies like OpenBao and CockroachDB, requires a supervision strategy to ensure it's running and restarts on failure. This can range from Docker Compose locally, Dokku or systemd on single servers, to Kubernetes in clustered environments.
2.  **Secrets Management with OpenBao (`aria_security`)**:
    - OpenBao is the central source for all secrets (database credentials, API keys, certificates).
    - Services must securely authenticate to OpenBao to retrieve secrets, typically using the **AppRole auth method**.
    - Avoid hardcoding secrets; fetch them dynamically from OpenBao at startup or runtime.
    - The secure bootstrapping of initial credentials for services to connect to OpenBao is critical and depends on the deployment environment.
3.  **Service-Specific Strategies**: Detailed deployment, supervision, and secrets management instructions for each core service and its direct dependencies (like CockroachDB for `aria_data`) are documented within their respective `apps/<service_name>/README.md` files.

### General Workflow for Services Using OpenBao

1.  **OpenBao Deployment**: The `aria_security` service (or a standalone OpenBao instance) must be deployed, initialized, unsealed, and configured with appropriate auth methods (e.g., AppRole for other Aria services) and secrets paths.
2.  **Service Deployment**: When an Aria service (e.g., `aria_data`, `aria_storage`) is deployed:
    - It receives its initial bootstrap credentials (e.g., AppRole RoleID & SecretID) to authenticate with OpenBao. This injection method varies by environment (e.g., secure environment variables, init containers, manual setup for first run).
    - The service starts and uses its OpenBao client to authenticate.
    - It then fetches its required operational secrets (e.g., database connection strings, API keys for external services, TLS certificates for dependencies) from its designated paths in OpenBao.
    - The service uses these fetched secrets to configure itself and connect to other services or backends.

Refer to the `apps/aria_security/README.md` for detailed information on setting up and managing OpenBao itself. For other services, consult their individual READMEs for specific deployment and secrets integration steps.
