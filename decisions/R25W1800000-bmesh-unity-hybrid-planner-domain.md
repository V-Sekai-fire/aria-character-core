# Procedural Mesh Generation Hybrid Planner Domain

**Status:** Completed  
**Date:** 2025-08-27  
**Decision Makers:** Development Team

## Context

The project requires runtime procedural mesh generation capabilities that integrate with the AriaHybridPlanner framework. The current AriaHybridPlanner framework supports domain creation with actions, task methods, unigoal methods, and multigoal methods using the attribute-based system.

### Procedural Mesh Generation Requirements

The system provides:

- **Non-manifold boundary representation** for 3D meshes with arbitrary attributes
- **Flexible mesh structure** with vertices, edges, loops, and faces
- **Runtime procedural generation** optimized for flexibility over rendering performance
- **Arbitrary attribute system** for mesh property management
- **Topological operations** for mesh manipulation and editing
- **Game engine integration** through standard mesh data structures

Key capabilities needed:

- Vertex/Edge/Loop/Face topology with neighbor traversal
- Custom attribute attachment (Float/Int arrays) to any topological entity
- Built-in support for UVs, normals, colors, and material IDs
- Procedural mesh generation with real-time modification capabilities
- Debug visualization and testing support

### Current Hybrid Planner Architecture

The AriaHybridPlanner framework provides:

- **AriaCore.Domain** structure with actions, methods, unigoal_methods
- **@action** attribute for defining durative actions with entity requirements
- **@task_method** attribute for workflow decomposition strategies
- **@unigoal_method** attribute for single goal achievement with predicate specification
- **@multigoal_method** attribute for multiple goal optimization
- **AriaState** integration for state management and fact storage
- **Entity registry** for capability-based resource management

## Problem Statement

We need to create a hybrid planner domain that can leverage BMeshUnity's procedural mesh generation capabilities to enable:

1. **Mesh generation planning** with durative actions for complex mesh operations
2. **Spatial reasoning** using mesh topology and geometry as planning predicates
3. **Procedural content creation** integrated with temporal planning constraints
4. **Runtime mesh modification** based on planning decisions and goals
5. **Attribute-driven planning** using mesh properties as planning state and goals

## Decision

Implement a procedural mesh generation hybrid planner domain that treats procedural mesh generation as a planning domain with proper actions, goals, and task decomposition, enabling spatial and geometric reasoning within the temporal planning framework.

**Implementation Status:** ✅ **COMPLETED** - Extracted to dedicated umbrella app `apps/aria_bmesh_domain/`

The technical implementation has been moved from this ADR to a standalone Elixir umbrella application for better modularity and maintainability. See `apps/aria_bmesh_domain/` for the complete implementation including:

- **Main domain module**: `apps/aria_bmesh_domain/lib/aria_bmesh_domain.ex`
  - Atomic BMesh actions: `create_bmesh`, `add_vertex`, `add_face`, `remove_edge`, `add_vertex_attribute`, `add_edge_attribute`, `add_face_attribute`
  - All mesh data stored in AriaState facts using tuples like `{mesh_id, vertex_id}, "vertex_exists"`
  - Duration-based actions compatible with AriaHybridPlanner framework

- **Geometric primitives**: `apps/aria_bmesh_domain/lib/aria_bmesh_domain/primitives.ex`
  - **7 implemented task methods** for industry-standard geometric primitives:
    - `create_cuboid_task` - Rectangular box primitives (LOW complexity)
    - `create_cylinder_task` - Circular cross-section extrusions (MEDIUM complexity)
    - `create_triangular_prism_task` - Triangular cross-section extrusions (LOW complexity)
    - `create_cone_task` - Tapered circular meshes (MEDIUM complexity)
    - `create_ellipsoid_task` - Stretched spherical meshes (HIGH complexity)
    - `create_donut_task` - Ring-shaped torus meshes (HIGH complexity)
    - `create_pyramid_task` - Pointed apex meshes with square base (LOW complexity)
  - Each task method decomposes into sequences of atomic BMesh actions
  - Configurable parameters for dimensions, resolution, and complexity

- **Comprehensive test suite**: `apps/aria_bmesh_domain/test/aria_bmesh_domain_test.exs`
- **Documentation**: `apps/aria_bmesh_domain/README.md`

**Key Architectural Decisions:**
- Uses atomic BMesh operations based on `thirdparty/BMeshUnity/Tests/Runtime/TestBMesh.cs`
- All mesh topology stored as AriaState facts rather than external Unity integration
- Composite task methods return sequences of atomic actions for execution
- Trademark-compliant implementation (removed all Media Molecule and Blender references)

## Implementation Plan

### Phase 1: Core Domain Structure (HIGH PRIORITY)

**File**: `apps/aria_hybrid_planner/apps/aria_hybrid_planner/lib/aria_hybrid_planner/domains/bmesh_domain.ex`

**Missing/Required**:

- [ ] BMeshDomain module using AriaCore.ActionAttributes
- [ ] Basic mesh generation actions with @action attributes
- [ ] Mesh state predicates and fact management
- [ ] Entity definitions for mesh generators and spatial analyzers
- [ ] Temporal specifications for mesh operations

**Implementation Patterns Needed**:

- [ ] Domain creation function following AriaBlocks.Domain pattern
- [ ] Action registration using attribute-based system
- [ ] State integration with AriaState for mesh facts
- [ ] Entity registry for mesh operation capabilities

### Phase 2: Mesh Generation Actions (HIGH PRIORITY)

**File**: `apps/aria_hybrid_planner/apps/aria_hybrid_planner/lib/aria_hybrid_planner/domains/bmesh_domain.ex`

**Missing/Required**:

- [ ] @action create_mesh - Generate new mesh with specified parameters
- [ ] @action modify_topology - Add/remove vertices, edges, faces
- [ ] @action set_mesh_attributes - Update vertex/face attributes (UVs, colors)
- [ ] @action analyze_geometry - Compute spatial properties and relationships
- [ ] @action optimize_mesh - Simplify or refine mesh structure

**Implementation Patterns Needed**:

- [ ] Durative action specifications with realistic time estimates
- [ ] Precondition checking using mesh state facts
- [ ] Effect application updating mesh state
- [ ] Entity requirements for mesh generation capabilities

### Phase 3: Spatial Reasoning Methods (MEDIUM PRIORITY)

**File**: `apps/aria_hybrid_planner/apps/aria_hybrid_planner/lib/aria_hybrid_planner/domains/bmesh_domain.ex`

**Missing/Required**:

- [ ] @unigoal_method predicate: "mesh_exists" - Ensure mesh creation
- [ ] @unigoal_method predicate: "vertex_count" - Achieve target vertex count
- [ ] @unigoal_method predicate: "mesh_attribute" - Set specific mesh attributes
- [ ] @unigoal_method predicate: "spatial_relationship" - Achieve geometric constraints
- [ ] @unigoal_method predicate: "mesh_quality" - Optimize mesh properties

**Implementation Patterns Needed**:

- [ ] Goal achievement strategies using mesh operations
- [ ] Precondition checking for spatial constraints
- [ ] Subgoal decomposition for complex geometric requirements
- [ ] Alternative methods for different mesh generation strategies

### Phase 4: Task Decomposition Methods (MEDIUM PRIORITY)

**File**: `apps/aria_hybrid_planner/apps/aria_hybrid_planner/lib/aria_hybrid_planner/domains/bmesh_domain.ex`

**Missing/Required**:

- [ ] @task_method generate_procedural_mesh - Decompose complex mesh generation
- [ ] @task_method apply_mesh_deformation - Break down deformation into steps
- [ ] @task_method create_mesh_hierarchy - Generate multi-resolution meshes
- [ ] @task_method validate_mesh_constraints - Check geometric requirements
- [ ] @task_method export_mesh_data - Prepare mesh for Unity integration

**Implementation Patterns Needed**:

- [ ] Task decomposition into primitive actions
- [ ] Conditional decomposition based on mesh complexity
- [ ] Resource allocation for mesh generation entities
- [ ] Error handling and fallback strategies

### Phase 5: Unity Integration Layer (LOW PRIORITY)

**File**: `apps/aria_hybrid_planner/apps/aria_hybrid_planner/lib/aria_hybrid_planner/bmesh_integration.ex`

**Missing/Required**:

- [ ] Mesh data serialization for Unity communication
- [ ] BMesh command generation and execution
- [ ] State synchronization between planner and Unity
- [ ] Performance monitoring and optimization
- [ ] Debug visualization integration

**Implementation Patterns Needed**:

- [ ] JSON/binary serialization protocols
- [ ] Command pattern for mesh operations
- [ ] Event-driven state updates
- [ ] Performance metrics collection

## Implementation Strategy

### Step 1: Domain Foundation

1. Create BMeshDomain module with AriaCore.ActionAttributes
2. Define basic mesh generation actions with proper attributes
3. Implement mesh state management in AriaState
4. Create entity registry for mesh capabilities

### Step 2: Action Implementation

1. Implement @action create_mesh with duration and entity requirements
2. Add @action modify_topology for structural changes
3. Create @action set_mesh_attributes for property updates
4. Test action execution with mock mesh operations

### Step 3: Goal Achievement

1. Implement @unigoal_method for mesh existence goals
2. Add spatial relationship achievement methods
3. Create mesh quality optimization methods
4. Test goal satisfaction with mesh state

### Step 4: Task Decomposition

1. Add @task_method for complex mesh generation workflows
2. Implement procedural generation task breakdown
3. Create validation and export task methods
4. Test end-to-end mesh generation planning

### Current Focus: Domain Foundation

Starting with BMeshDomain implementation because:

- Establishes core architecture following proven patterns
- Provides foundation for all mesh planning operations
- Enables early testing of planning integration
- Creates clear interface for Unity communication

## Technical Architecture

### Domain Structure

```elixir
defmodule AriaHybridPlanner.Domains.BMeshDomain do
  @moduledoc """
  BMeshUnity procedural mesh generation domain for AriaHybridPlanner.

  This module implements a planning domain that treats procedural mesh generation
  as a first-class planning concern, enabling spatial and geometric reasoning
  within the temporal planning framework using BMeshUnity integration.

  Based on BMeshUnity library which provides a flexible mesh structure similar
  to Blender's BMesh system with runtime procedural generation capabilities.

  ## Core Capabilities

  - **Mesh Generation Planning**: Durative actions for complex mesh operations
  - **Spatial Reasoning**: Topology and geometry as planning predicates  
  - **Procedural Content Creation**: Integrated with temporal planning constraints
  - **Runtime Mesh Modification**: Based on planning decisions and goals
  - **Attribute-driven Planning**: Using mesh properties as planning state

  ## Planning Actions

  - `create_mesh/2` - Generate new mesh with specified parameters
  - `modify_topology/2` - Add/remove vertices, edges, faces
  - `setup_mesh_scenario/2` - Initialize mesh generation entities

  ## Goal Achievement

  - `achieve_mesh_existence/2` - Ensure mesh creation goals
  - `achieve_vertex_count/2` - Achieve target vertex count goals

  ## Task Decomposition

  - `generate_procedural_mesh/2` - Decompose complex mesh generation workflows

  ## Usage

      iex> domain = AriaHybridPlanner.Domains.BMeshDomain.create()
      iex> state = AriaState.new()
      iex> {:ok, new_state} = AriaHybridPlanner.Domains.BMeshDomain.setup_mesh_scenario(state, [])
      iex> {:ok, mesh_state} = AriaHybridPlanner.Domains.BMeshDomain.create_mesh(new_state, ["mesh1", %{vertex_count: 100}])

  ## References

  - BMeshUnity: Runtime procedural mesh generation library
  - R25W1398085: Unified durative action specification and planner standardization
  - R25W10069A4: Align unigoal method registration with GTpyhop design
  """
  use AriaCore.ActionAttributes

  @type mesh_id :: String.t()
  @type vertex_count :: non_neg_integer()
  @type mesh_params :: map()

  # Entity setup
  @action duration: "PT0S"
  @spec setup_mesh_scenario(AriaState.t(), []) :: {:ok, AriaState.t()} | {:error, atom()}
  def setup_mesh_scenario(state, []) do
    state = state
    |> register_entity(["mesh_generator", "generator", [:mesh_creation, :topology_modification]])
    |> register_entity(["spatial_analyzer", "analyzer", [:geometry_analysis, :constraint_checking]])
    |> register_entity(["mesh_optimizer", "optimizer", [:mesh_simplification, :quality_improvement]])

    {:ok, state}
  end

  # Basic mesh generation actions
  @action duration: "PT5S"
  @spec create_mesh(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def create_mesh(state, [mesh_id, params]) do
    # Check preconditions
    mesh_exists = AriaState.get_fact(state, mesh_id, "mesh_exists")
    
    if mesh_exists == true do
      {:error, :mesh_already_exists}
    else
      # Create mesh with BMeshUnity integration
      new_state = state
      |> AriaState.set_fact(mesh_id, "mesh_exists", true)
      |> AriaState.set_fact(mesh_id, "vertex_count", Map.get(params, :vertex_count, 0))
      |> AriaState.set_fact(mesh_id, "face_count", Map.get(params, :face_count, 0))
      
      {:ok, new_state}
    end
  end

  @action duration: "PT2S"
  @spec modify_topology(AriaState.t(), [String.t()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def modify_topology(state, [mesh_id, operations]) do
    # Check preconditions
    mesh_exists = AriaState.get_fact(state, mesh_id, "mesh_exists")
    
    if mesh_exists != true do
      {:error, :mesh_not_found}
    else
      # Apply topology modifications
      current_vertices = AriaState.get_fact(state, mesh_id, "vertex_count")
      current_faces = AriaState.get_fact(state, mesh_id, "face_count")
      
      new_vertices = current_vertices + Map.get(operations, :add_vertices, 0) - Map.get(operations, :remove_vertices, 0)
      new_faces = current_faces + Map.get(operations, :add_faces, 0) - Map.get(operations, :remove_faces, 0)
      
      new_state = state
      |> AriaState.set_fact(mesh_id, "vertex_count", max(0, new_vertices))
      |> AriaState.set_fact(mesh_id, "face_count", max(0, new_faces))
      
      {:ok, new_state}
    end
  end

  # Spatial reasoning unigoal methods
  @unigoal_method predicate: "mesh_exists"
  @spec achieve_mesh_existence(AriaState.t(), {String.t(), boolean()}) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def achieve_mesh_existence(state, {mesh_id, true}) do
    mesh_exists = AriaState.get_fact(state, mesh_id, "mesh_exists")
    
    if mesh_exists == true do
      {:ok, []}  # Already exists
    else
      # Generate action to create mesh
      {:ok, [{:create_mesh, [mesh_id, %{vertex_count: 4, face_count: 1}]}]}
    end
  end

  @unigoal_method predicate: "vertex_count"
  @spec achieve_vertex_count(AriaState.t(), {String.t(), non_neg_integer()}) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def achieve_vertex_count(state, {mesh_id, target_count}) do
    current_count = AriaState.get_fact(state, mesh_id, "vertex_count") || 0
    
    if current_count == target_count do
      {:ok, []}  # Already at target
    else
      # Generate topology modification to reach target
      vertex_diff = target_count - current_count
      operations = if vertex_diff > 0 do
        %{add_vertices: vertex_diff}
      else
        %{remove_vertices: abs(vertex_diff)}
      end
      
      {:ok, [{:modify_topology, [mesh_id, operations]}]}
    end
  end

  # Task decomposition methods
  @task_method true
  @spec generate_procedural_mesh(AriaState.t(), [any()]) :: {:ok, [AriaHybridPlanner.todo_item()]} | {:error, atom()}
  def generate_procedural_mesh(state, [mesh_id, complexity, style]) do
    # Decompose complex mesh generation into steps
    base_params = case complexity do
      :low -> %{vertex_count: 100, face_count: 50}
      :medium -> %{vertex_count: 500, face_count: 250}
      :high -> %{vertex_count: 2000, face_count: 1000}
    end
    
    style_params = case style do
      :plane -> %{shape: "plane"}
      :sphere -> %{shape: "sphere", subdivisions: 3}
      :cube -> %{shape: "cube"}
      _ -> %{shape: "plane"}
    end
    
    params = Map.merge(base_params, style_params)
    
    {:ok, [
      {:create_mesh, [mesh_id, params]},
      {"mesh_quality", mesh_id, :good}
    ]}
  end

  # Domain creation
  @spec create() :: AriaCore.Domain.t()
  def create() do
    domain = AriaCore.new_domain(:bmesh_world)
    domain = AriaCore.register_attribute_specs(domain, __MODULE__)
    domain
  end

  # Helper functions
  defp register_entity(state, [entity_id, type, capabilities]) do
    state
    |> AriaState.set_fact(entity_id, "type", type)
    |> AriaState.set_fact(entity_id, "capabilities", capabilities)
    |> AriaState.set_fact(entity_id, "status", "available")
  end
end
```

### State Integration

```elixir
# Mesh state facts in AriaState
# {"mesh_exists", mesh_id, true/false}
# {"vertex_count", mesh_id, count}
# {"face_count", mesh_id, count}
# {"mesh_attribute", {mesh_id, attribute_name}, value}
# {"spatial_relationship", {mesh_id1, mesh_id2}, relationship_type}
# {"mesh_quality", mesh_id, quality_score}
```

### Unity Communication

```elixir
defmodule AriaHybridPlanner.BMeshIntegration do
  # Command generation for Unity
  def create_mesh_command(mesh_id, params) do
    %{
      command: "create_mesh",
      mesh_id: mesh_id,
      parameters: params,
      timestamp: DateTime.utc_now()
    }
  end

  # State synchronization
  def sync_mesh_state(unity_mesh_data) do
    # Update AriaState with Unity mesh information
  end
end
```

## Success Criteria

### Functional Requirements

- [ ] Generate procedural meshes through planning actions with proper durations
- [ ] Achieve mesh-related goals using unigoal methods
- [ ] Decompose complex mesh generation tasks using task methods
- [ ] Maintain mesh state in AriaState with proper fact management
- [ ] Support entity-based resource allocation for mesh operations

### Performance Requirements

- [ ] Handle mesh generation planning for 1000+ vertex meshes
- [ ] Complete mesh creation actions within specified durations
- [ ] Support concurrent mesh operations through entity management
- [ ] Memory usage under 50MB for typical planning scenarios
- [ ] Planning time under 1 second for simple mesh goals

### Integration Requirements

- [ ] Seamless integration with AriaHybridPlanner framework
- [ ] Compatible with AriaCore.Domain and AriaState systems
- [ ] Works with existing entity registry and temporal specifications
- [ ] Supports lazy execution and solution tree patterns
- [ ] Integrates with Unity through command serialization

## Risks and Mitigation

### Technical Risks

- **Mesh complexity planning overhead**: Mitigate with level-of-detail planning strategies
- **State synchronization complexity**: Use clear fact naming conventions and validation
- **Unity integration latency**: Implement asynchronous command execution
- **Memory usage for large meshes**: Use streaming and progressive mesh generation

### Planning Risks

- **Goal satisfaction complexity**: Start with simple geometric goals and expand gradually
- **Action duration estimation**: Use empirical testing to calibrate mesh operation times
- **Entity resource contention**: Implement proper capability-based allocation
- **Multigoal optimization**: Leverage existing multigoal methods for spatial constraints

## Related ADRs

- **R25W1398085**: Unified durative action specification and planner standardization
- **R25W10069A4**: Align unigoal method registration with GTpyhop design
- **R25W153B3FE**: Hybrid coordinator v2 monolithic refactoring
- **R25W166REST**: Restructure apps standard Elixir pattern

## Consequences

### Positive

- Enables sophisticated procedural content generation within temporal planning
- Provides spatial reasoning capabilities for geometric planning problems
- Creates reusable mesh generation patterns for game development
- Integrates procedural generation with entity-based resource management
- Supports real-time content adaptation based on planning decisions

### Negative

- Increases system complexity with mesh state management requirements
- Requires careful performance optimization for complex mesh operations
- Adds dependency on Unity and BMeshUnity library
- May require specialized knowledge of mesh topology and planning
- Potential memory overhead for large mesh planning scenarios

### Neutral

- Establishes new domain-specific planning patterns for procedural content
- Creates precedent for integrating external libraries in planning domains
- Requires documentation and examples for effective mesh planning use
- May influence future procedural generation architecture decisions
- Demonstrates attribute-based domain creation for complex domains
