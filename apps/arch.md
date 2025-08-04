# Aria Character Core - Umbrella App Architecture Railroad Diagram

## Dependency Railroad Diagram

```
                    External Dependencies
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                 aria_character_core                     │
│                 (Umbrella Root)                         │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│                Internal Apps Layer                      │
└─────────────────────┬───────────────────────────────────┘
                      │
              ┌───────┼───────┐
              │       │       │
              ▼       ▼       ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │aria_serial  │ │ ast_migrate │ │ aria_math   │
    │(Foundation) │ │ (Tooling)   │ │(Foundation) │
    └─────────────┘ └─────────────┘ └──────┬──────┘
                                           │
                                           ▼
                                  ┌─────────────┐
                                  │aria_joint   │
                                  │(Animation)  │
                                  └──────┬──────┘
                                         │
                                         ▼
                                  ┌─────────────┐
                                  │aria_gltf    │
                                  │(3D Assets)  │
                                  └─────────────┘

                      ┌─────────────┐
                      │aria_qcp     │
                      │(Constraint) │*
                      └─────────────┘

              ┌─────────────────────┐
              │aria_membrane_       │
              │pipeline             │**
              │(Processing)         │
              └─────────────────────┘

    ┌─────────────────────┐
    │aria_hybrid_planner  │***
    │(External Git)       │
    └─────────────────────┘
```

## Legend

- `*` = Has broken dependency reference to non-existent `aria_state`
- `**` = Has broken dependency references to non-existent apps
- `***` = External git dependency, not in local apps/

## Dependency Chain Analysis

### Tier 1: Foundation Apps (No Internal Dependencies)
- **aria_serial**: Serial number generation (timex, jason)
- **ast_migrate**: AST manipulation tooling (sourceror, jason)
- **aria_math**: Mathematical operations (nx, torchx)

### Tier 2: Core Apps (Depend on Tier 1)
- **aria_joint**: Joint/skeletal animation
  - Depends on: `aria_math`
  
### Tier 3: Asset Apps (Depend on Tier 1-2)
- **aria_gltf**: glTF 3D file format support
  - Depends on: `aria_math`, `aria_joint`

### Tier 4: Specialized Apps (Mixed Dependencies)
- **aria_qcp**: Constraint satisfaction (BROKEN)
  - Depends on: `aria_math`, `aria_state` (NON-EXISTENT)

### Processing Layer (External Dependencies)
- **aria_membrane_pipeline**: Stream processing (BROKEN)
  - Depends on: `aria_hybrid_planner` (git), `aria_minizinc_goal` (NON-EXISTENT)

### External Dependencies
- **aria_hybrid_planner**: Planning system (git repository)

## Architectural Issues Identified

### Missing Apps Referenced in Dependencies
1. `aria_core` - Referenced in root mix.exs but doesn't exist
2. `aria_state` - Referenced by aria_qcp but doesn't exist  
3. `aria_minizinc_goal` - Referenced by aria_membrane_pipeline but doesn't exist

### Inconsistent Dependency Declarations
- Some apps use `in_umbrella: true`
- Some apps use `path: "../app_name"`
- Some apps missing umbrella configuration entirely

### Clean Dependency Chain (Working Apps)
```
aria_math ← aria_joint ← aria_gltf
```

### Isolated Apps (No Internal Dependencies)
```
aria_serial
ast_migrate
```

### Broken Apps (Unresolvable Dependencies)
```
aria_qcp (missing aria_state)
aria_membrane_pipeline (missing aria_minizinc_goal)
```

## Recommendations

1. **Create missing apps** or remove references to them
2. **Standardize dependency declarations** across all apps
3. **Fix umbrella build configuration** for consistent compilation
4. **Consider dependency inversion** for better modularity
5. **Document external git dependencies** and their integration points

## External Dependency Categories

### Development & Testing
- credo, dialyxir, ex_doc (quality tools)
- mox, stream_data (testing)

### Core Infrastructure  
- phoenix, bandit (web framework)
- ecto_sql, ecto_sqlite3 (database)
- jason, telemetry (utilities)

### Specialized Domains
- nx, torchx (numerical computing)
- membrane_core (stream processing)
- libgraph (graph algorithms)
- rdf, json_ld (knowledge representation)

### External Services
- ex_aws, ex_aws_s3 (cloud storage)
- macfly, bcrypt_elixir (authentication)
- finch, req (HTTP clients)
