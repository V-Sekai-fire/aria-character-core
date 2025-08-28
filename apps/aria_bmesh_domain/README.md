# AriaBmeshDomain

Procedural mesh generation domain for AriaHybridPlanner, enabling spatial and geometric reasoning within temporal planning frameworks.

## Overview

AriaBmeshDomain provides a planning domain that treats procedural mesh generation as a first-class planning concern. It integrates with AriaHybridPlanner to enable sophisticated 3D content creation through temporal planning actions, goals, and task decomposition.

## Features

- **Durative Actions**: Mesh generation operations with realistic time estimates
- **Spatial Reasoning**: Topology and geometry as planning predicates
- **Goal Achievement**: Automated mesh creation and modification to satisfy spatial goals
- **Task Decomposition**: Complex mesh generation workflows broken into manageable steps
- **Entity Management**: Resource allocation for mesh generation capabilities

## Core Components

### Planning Actions

- `create_mesh/2` - Generate new mesh with specified parameters
- `modify_topology/2` - Add/remove vertices, edges, faces
- `setup_mesh_scenario/2` - Initialize mesh generation entities

### Goal Achievement Methods

- `achieve_mesh_existence/2` - Ensure mesh creation goals
- `achieve_vertex_count/2` - Achieve target vertex count goals

### Task Decomposition Methods

- `generate_procedural_mesh/2` - Decompose complex mesh generation workflows

## Geometric Primitives

The domain supports comprehensive geometric primitive generation for testing and development:

### Supported Primitives

- **Cubic Strokes**: Volumetric brush-like meshes
- **Cylinders**: Circular cross-section extrusions
- **Cones**: Tapered circular meshes
- **Cuboids**: Rectangular box primitives
- **Ellipsoids**: Stretched spherical meshes
- **Triangular Prisms**: Triangular cross-section extrusions
- **Donuts (Tori)**: Ring-shaped meshes with holes
- **Biscuits**: Rounded cylindrical shapes
- **Markoids**: Super ellipsoids with variable power for x,y,z axes
- **Pyramids**: Pointed apex meshes

### Complexity Categories

- **Low Complexity**: Cuboids, triangular prisms, pyramids
- **Medium Complexity**: Cylinders, cones, cubic strokes, biscuits
- **High Complexity**: Ellipsoids, donuts, markoids

## Usage

### Basic Domain Creation

```elixir
# Create the domain
domain = AriaBmeshDomain.create()

# Initialize state
state = AriaState.new()

# Set up mesh generation scenario
{:ok, state} = AriaBmeshDomain.setup_mesh_scenario(state, [])
```

### Mesh Generation

```elixir
# Create a simple cuboid
params = AriaBmeshDomain.Primitives.cuboid_params()
{:ok, state} = AriaBmeshDomain.create_mesh(state, ["my_cuboid", params])

# Create a high-resolution cylinder
params = AriaBmeshDomain.Primitives.cylinder_params(
  radial_segments: 32,
  vertex_count: 96
)
{:ok, state} = AriaBmeshDomain.create_mesh(state, ["detailed_cylinder", params])
```

### Mesh Modification

```elixir
# Add vertices and faces to existing mesh
operations = %{add_vertices: 8, add_faces: 4}
{:ok, state} = AriaBmeshDomain.modify_topology(state, ["my_cuboid", operations])
```

### Goal-Driven Planning

```elixir
# Ensure a mesh exists
{:ok, actions} = AriaBmeshDomain.achieve_mesh_existence(state, {"target_mesh", true})

# Achieve specific vertex count
{:ok, actions} = AriaBmeshDomain.achieve_vertex_count(state, {"target_mesh", 100})
```

### Complex Mesh Generation

```elixir
# Generate procedural mesh with task decomposition
{:ok, actions} = AriaBmeshDomain.generate_procedural_mesh(
  state, 
  ["complex_mesh", :high, :sphere]
)
```

## Integration with AriaHybridPlanner

AriaBmeshDomain integrates seamlessly with the AriaHybridPlanner framework:

- Uses `@action` attributes for durative actions
- Implements `@unigoal_method` for goal achievement
- Provides `@task_method` for workflow decomposition
- Manages state through AriaState fact storage
- Supports entity-based resource allocation

## Testing

The domain includes comprehensive test coverage for all geometric primitives and planning operations:

```bash
# Run tests
mix test

# Run specific test group
mix test --only geometric_primitives
```

## Dependencies

- `aria_hybrid_planner` - Core planning framework
- `aria_core` - Domain management and action attributes
- `aria_state` - State management and fact storage

## Architecture

The domain follows standard Elixir umbrella app patterns:

```
apps/aria_bmesh_domain/
├── lib/
│   ├── aria_bmesh_domain.ex          # Main domain module
│   └── aria_bmesh_domain/
│       └── primitives.ex             # Geometric primitive generation
├── test/
│   └── aria_bmesh_domain_test.exs    # Comprehensive test suite
└── mix.exs                           # Project configuration
```

## Future Extensions

Potential areas for expansion:

- **Unity Integration**: Direct communication with Unity mesh systems
- **Advanced Spatial Reasoning**: Collision detection and spatial relationships
- **Mesh Optimization**: Automatic mesh simplification and quality improvement
- **Material Planning**: Texture and material assignment through planning
- **Animation Planning**: Temporal mesh deformation and animation sequences

## Contributing

When adding new geometric primitives or planning operations:

1. Add primitive generation functions to `AriaBmeshDomain.Primitives`
2. Include comprehensive test coverage
3. Update complexity categorization
4. Document usage patterns and examples
5. Ensure integration with existing planning framework

## License

This project follows the same license as the parent aria-character-core project.
