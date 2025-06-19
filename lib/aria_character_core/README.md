# AriaCharacterCore

AriaCharacterCore is the main application module that orchestrates and integrates all components of the Aria Character Core system. It provides the unified interface and coordination layer for the entire ecosystem.

## Overview

AriaCharacterCore serves as the central hub that brings together:

- **Application Coordination**: Manages startup, supervision, and lifecycle of all Aria components
- **Service Integration**: Provides unified APIs across all Aria modules
- **Configuration Management**: Centralized configuration for the entire system
- **Health Monitoring**: System-wide health checks and monitoring
- **API Gateway**: External interface for client applications

## Core Responsibilities

### Application Management
- `AriaCharacterCore.Application` - Main application supervisor
- Component lifecycle management and supervision trees
- Graceful startup and shutdown coordination
- Inter-service communication and dependency management

### Service Coordination
- Unified API layer across all Aria components
- Service discovery and registration
- Load balancing and failover management
- Cross-component transaction coordination

### System Integration
- External API endpoints and client interfaces
- WebSocket connections for real-time communication
- REST API for standard operations
- GraphQL interface for complex queries

## Architecture

AriaCharacterCore follows a microservices-inspired architecture within a single application:

```
AriaCharacterCore (Main Application)
├── AriaEngine (Planning & Execution)
├── AriaAuth (Authentication & Sessions)
├── AriaStorage (Content-Addressable Storage)
├── AriaSecurity (Secrets & Cryptography)
├── AriaTown (Game World Simulation)
└── Integration Layer (APIs & Communication)
```

## Usage

### Starting the Application

```elixir
# Start the complete Aria system
{:ok, _} = AriaCharacterCore.Application.start(:normal, [])

# Check system health
AriaCharacterCore.health_check()
```

### Service Access

```elixir
# Access planning services
{:ok, plan} = AriaCharacterCore.plan_task(domain, state, goals)

# Manage user sessions
{:ok, session} = AriaCharacterCore.authenticate_user(credentials)

# Store and retrieve data
{:ok, file_id} = AriaCharacterCore.store_file(file_path)
{:ok, content} = AriaCharacterCore.retrieve_file(file_id)

# Simulate game world
{:ok, world_state} = AriaCharacterCore.advance_simulation(delta_time)
```

### Configuration

```elixir
# Configure the entire system
config :aria_character_core,
  # Engine configuration
  planning_timeout: 30_000,
  max_plan_depth: 10,
  
  # Authentication configuration
  session_timeout: 3600,
  max_sessions_per_user: 5,
  
  # Storage configuration
  storage_backend: :filesystem,
  chunk_size: 64_000,
  
  # Security configuration
  secrets_backend: :openbao,
  encryption_at_rest: true,
  
  # Game world configuration
  simulation_speed: 1.0,
  max_npcs: 100
```

## API Endpoints

### REST API

```
GET    /api/health              # System health check
POST   /api/auth/login          # User authentication
GET    /api/auth/session        # Session validation
POST   /api/planning/plan       # Create execution plan
GET    /api/storage/files/:id   # Retrieve file
POST   /api/storage/files       # Upload file
GET    /api/world/state         # Get world state
POST   /api/world/advance       # Advance simulation
```

### WebSocket API

```elixir
# Real-time planning updates
channel "planning:*", AriaCharacterCore.PlanningChannel

# World simulation events
channel "world:*", AriaCharacterCore.WorldChannel

# User session management
channel "user:*", AriaCharacterCore.UserChannel
```

### GraphQL API

```graphql
type Query {
  user(id: ID!): User
  plan(id: ID!): Plan
  worldState: WorldState
  files(filter: FileFilter): [File]
}

type Mutation {
  createPlan(input: PlanInput!): Plan
  uploadFile(input: FileInput!): File
  advanceWorld(deltaTime: Int!): WorldState
}

type Subscription {
  planUpdates(planId: ID!): PlanUpdate
  worldEvents: WorldEvent
  userNotifications(userId: ID!): Notification
}
```

## Development

### Running the Application

```bash
# Start in development mode
mix phx.server

# Start with interactive shell
iex -S mix phx.server

# Run tests
mix test --timeout 120

# Check code quality
mix credo
mix dialyzer
```

### Environment Setup

```bash
# Install dependencies
mix deps.get

# Set up databases
mix ecto.setup

# Compile assets
mix assets.deploy
```

## Deployment

### Production Configuration

```elixir
config :aria_character_core, AriaCharacterCoreWeb.Endpoint,
  url: [host: "aria.example.com", port: 443, scheme: "https"],
  check_origin: ["https://aria.example.com"],
  secret_key_base: {:system, "SECRET_KEY_BASE"}

config :aria_character_core,
  database_url: {:system, "DATABASE_URL"},
  redis_url: {:system, "REDIS_URL"}
```

### Docker Deployment

```dockerfile
FROM elixir:1.15-alpine
WORKDIR /app
COPY . .
RUN mix deps.get --only prod
RUN mix compile
RUN mix assets.deploy
CMD ["mix", "phx.server"]
```

## Monitoring

### Health Checks

```elixir
# System-wide health check
AriaCharacterCore.HealthCheck.status()
# => %{
#   status: :healthy,
#   components: %{
#     engine: :healthy,
#     auth: :healthy,
#     storage: :healthy,
#     security: :healthy,
#     town: :healthy
#   },
#   uptime: 3600,
#   version: "1.0.0"
# }
```

### Metrics and Logging

- **Telemetry**: Comprehensive metrics collection
- **Structured Logging**: JSON-formatted logs for analysis
- **Performance Monitoring**: Request/response times and throughput
- **Error Tracking**: Automatic error reporting and alerting

## Security

### Security Features

- **Authentication**: Multi-factor authentication support
- **Authorization**: Role-based access control
- **Encryption**: End-to-end encryption for sensitive data
- **Audit Logging**: Comprehensive audit trails
- **Rate Limiting**: Protection against abuse and DoS attacks

### Security Configuration

```elixir
config :aria_character_core,
  # HTTPS enforcement
  force_ssl: true,
  
  # CORS configuration
  cors_origins: ["https://app.example.com"],
  
  # Rate limiting
  rate_limit: [
    max_requests: 1000,
    window_ms: 60_000
  ],
  
  # Session security
  session_signing_salt: {:system, "SESSION_SIGNING_SALT"},
  session_encryption_salt: {:system, "SESSION_ENCRYPTION_SALT"}
```

## Related Components

AriaCharacterCore integrates and coordinates:

- **AriaEngine**: Core planning and execution engine
- **AriaAuth**: Authentication and session management
- **AriaStorage**: Persistent storage and archiving
- **AriaSecurity**: Security infrastructure and secrets management
- **AriaTown**: Game world simulation and NPC behavior

## Status

AriaCharacterCore provides a stable, production-ready platform for intelligent character systems. The modular architecture enables easy scaling and extension while maintaining system coherence and reliability.
