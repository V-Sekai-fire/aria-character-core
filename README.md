# Aria Character Core

A comprehensive character AI system providing hybrid planning, knowledge management, workflow execution, and coordination capabilities in a unified application.

## Overview

AriaCharacterCore consolidates functionality that was previously distributed across multiple umbrella applications into a single, cohesive system:

- **AriaEngine** - Hybrid planning and AI core with HTN planning, temporal constraints, and domain management
- **AriaTown** - RDF knowledge base and NPC management system
- **AriaWorkflow** - Workflow execution and state management
- **AriaAuth** - Authentication and authorization services
- **AriaSecurity** - Security and access control
- **AriaStorage** - File and data storage management
- **AriaCoordinate** - Web coordination interface
- **AriaMonitor** - System monitoring and telemetry
- **AriaInterpret** - AI/ML interpretation services
- **AriaFileManagement** - File operations and management

## Architecture

The system uses a single application supervisor that manages all components:

```elixir
AriaCharacterCore.Application
├── AriaTown.KnowledgeBase
├── AriaTown.PersistenceManager  
├── AriaTown.TimeManager
├── AriaTown.NPCManager
└── [Other component supervisors as needed]
```

## Project Structure

```
lib/
├── aria_character_core.ex          # Main module
├── aria_character_core/
│   └── application.ex               # Application supervisor
├── aria_engine/                    # Planning and AI core
├── aria_town/                      # Knowledge base and NPCs
├── aria_workflow/                  # Workflow management
├── aria_auth/                      # Authentication
├── aria_security/                  # Security services
├── aria_storage/                   # Storage management
├── aria_coordinate/                # Web coordination
├── aria_monitor/                   # Monitoring
├── aria_interpret/                 # AI/ML interpretation
└── aria_file_management/           # File operations
```

## Development

### Dependencies

```bash
mix deps.get
```

### Compilation

```bash
mix compile
```

Note: Some warnings about undefined functions are expected during development as module implementations are completed.

### Testing

```bash
mix test
```

## Features

### AriaEngine
- HTN (Hierarchical Task Network) planning
- Temporal constraint solving with STN (Simple Temporal Networks)
- Domain-specific planning with extensible domain providers
- Hybrid planning strategies with multiple algorithms

### AriaTown  
- RDF-based knowledge representation
- SPARQL query capabilities
- NPC behavior management
- Temporal reasoning and time management

### AriaWorkflow
- State machine-based workflow execution
- Event-driven workflow processing
- Workflow composition and chaining

## Configuration

Configuration is managed through standard Elixir config files in the `config/` directory:

- `config.exs` - Base configuration
- `dev.exs` - Development settings
- `prod.exs` - Production settings  
- `test.exs` - Test environment settings

## Contributing

This project follows established development practices:

- Use descriptive commit messages without conventional commit prefixes
- Focus on one logical change per commit
- Include comprehensive tests for new functionality
- Follow Elixir/OTP design patterns and conventions

## License

Copyright (c) 2025-present K. S. Ernest (iFire) Lee  
SPDX-License-Identifier: MIT
