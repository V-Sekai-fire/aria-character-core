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

### Testing on Kubernetes with GitHub Actions

Testing the Aria Character Core system on Kubernetes within a GitHub Actions workflow typically involves the following steps:

1.  **Ephemeral Kubernetes Cluster**:

    - Set up a temporary Kubernetes cluster for each test run. Tools like **KinD (Kubernetes in Docker)** are well-suited for this, as they can create a lightweight, local Kubernetes cluster within the GitHub Actions runner environment.

2.  **Secrets Management for CI**:

    - **OpenBao Deployment**: Deploy OpenBao to the test cluster. For CI, you might use a simplified configuration or a pre-configured Docker image.
    - **Bootstrap Secrets**: The initial secrets required to unseal OpenBao or for services to authenticate to OpenBao (e.g., AppRole RoleID & SecretID) must be securely provided. This often means starting with a "root" or initial bootstrap secret.
      - **Initial Secure Injection**: Use **GitHub Actions encrypted secrets** to store and inject this foundational secret (e.g., an initial admin token for OpenBao, or credentials for a script that can create AppRoles). This is the "constant" you provide to kickstart the process.
      - **Dynamic Credentials for Services**: Once OpenBao is accessible and authenticated (using the initial secret if necessary), subsequent credentials for individual services (like their specific AppRole RoleID & SecretID) can often be dynamically generated or retrieved by the services themselves during their startup or by CI scripts.
      - These secrets (both the initial bootstrap ones and any dynamically generated ones passed around) can be exposed as environment variables to your deployment scripts or directly to Kubernetes secrets that are then mounted into your application pods.
    - **Service Configuration**: Ensure your service deployment manifests (e.g., Kubernetes YAML) are configured to fetch their operational secrets from the OpenBao instance running in the test cluster.

3.  **Service Deployment**:

    - Use Kubernetes manifests (YAML files) or Helm charts to deploy your Aria services and their dependencies (like CockroachDB) to the test cluster.
    - These manifests should be parameterized or configured to work within the CI environment, pointing to the in-cluster OpenBao service.

4.  **Running Tests**:

    - Once all services are deployed and healthy, execute your integration or end-to-end tests.
    - These tests could be scripts that run `kubectl exec` commands, or dedicated test containers that run within the cluster and interact with the services.

5.  **Cleanup**:
    - Ensure that the ephemeral Kubernetes cluster (if using KinD) is destroyed at the end of the workflow.

This approach allows for comprehensive testing of service interactions, secret management, and deployment configurations in an environment that closely mirrors a production Kubernetes setup.

Refer to the `apps/aria_security/README.md` for detailed information on setting up and managing OpenBao itself. For other services, consult their individual READMEs for specific deployment and secrets integration steps.
