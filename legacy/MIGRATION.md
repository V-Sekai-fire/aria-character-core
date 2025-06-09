# Docker to Native Migration

This document explains the migration from Docker-based deployment to native system deployment for Aria Character Core.

## Migration Summary

**Date:** June 2025  
**Status:** ✅ Complete

The project has been successfully migrated from Docker containers to native system installation for better performance, security, and resource utilization.

## What Was Moved

### Legacy Docker Files (now in `legacy/docker/`)
- `Dockerfile` - Multi-stage container build
- `docker-compose.yml` - Container orchestration
- `docker_openbao/` - OpenBao container configuration
- `docker_s3_config_generator/` - S3 configuration generator

## Native Replacement Components

### 1. System Dependencies
- **Ubuntu packages**: Installed via `just install-ubuntu-deps`
- **Build tools**: gcc, pkg-config, libssl-dev, etc.
- **Security tools**: softhsm2, opensc, pcsc-lite

### 2. Runtime Environment
- **Erlang/Elixir**: Managed via asdf (`just install-elixir-erlang-env`)
- **CockroachDB**: Native binary installation (`just install-cockroach`)
- **OpenBao**: Native .deb package (`just install-openbao`)
- **SeaweedFS**: Native binary (`just install-seaweedfs`)

### 3. Service Management

#### Development (Native processes)
```bash
# Start foundation services
just foundation-startup

# Start all services  
just start-all

# Check status
just status

# Stop all services
just stop-all-services
```

#### Production (Systemd services)
```bash
# Setup production environment
sudo just setup-production

# Start services
just start-production

# Check status  
just status-production

# View logs
just logs-production
```

### 4. Configuration Files

#### Systemd Services (`systemd/`)
- `aria-cockroachdb.service` - CockroachDB database
- `aria-openbao.service` - OpenBao secrets management
- `aria-seaweedfs.service` - SeaweedFS distributed storage
- `aria-app.service` - Main Elixir application
- `aria.target` - Service coordination

#### Native Configuration
- SoftHSM configuration in `/etc/softhsm2.conf`
- OpenBao configuration in `/opt/aria/config/openbao.hcl`
- Application data in `/opt/aria/data/`

## Benefits of Native Deployment

### Performance
- **Reduced overhead**: No container runtime overhead
- **Direct hardware access**: Better performance for HSM operations
- **Memory efficiency**: No duplicate layers or container metadata

### Security
- **Reduced attack surface**: No container runtime vulnerabilities
- **System-level isolation**: Use of systemd security features
- **Direct HSM access**: No container-mediated PKCS#11 operations

### Operational
- **Systemd integration**: Standard Linux service management
- **Resource control**: Better cgroup and limit management
- **Logging**: Integrated with journald
- **Monitoring**: Standard system monitoring tools

### Development
- **Faster iteration**: No container rebuild cycles
- **Native debugging**: Direct access to processes and files
- **Hot reloading**: Direct code reloading without container restart

## Migration Verification

### Services Running Check
```bash
# Development
just status

# Production  
just status-production
```

### Health Endpoints
- **Application**: http://localhost:4000/health
- **OpenBao**: http://localhost:8200/v1/sys/health
- **CockroachDB**: http://localhost:8080/health
- **SeaweedFS**: http://localhost:8333

### Testing
```bash
# Run all tests with native setup
just test-all
```

## Rollback (If Needed)

If you need to temporarily use the legacy Docker setup:

```bash
# Copy back Docker files
cp legacy/docker/* .

# Use Docker Compose  
docker-compose up -d

# Or build/run manually
docker build -t aria-character-core .
docker run -p 4000:4000 -p 8200:8200 aria-character-core
```

## Future Considerations

- **Container options**: Docker files preserved for potential future container deployments
- **Kubernetes**: Could create K8s manifests based on systemd services if needed
- **Cloud deployment**: Native setup provides foundation for cloud-init scripts

## Support

For issues with the native deployment:
1. Check service status: `just status-production`
2. View logs: `just logs-production` 
3. Restart services: `just restart-production`
4. Check justfile commands: `just` (shows all available commands)

The native deployment is now the primary and recommended method for running Aria Character Core.
