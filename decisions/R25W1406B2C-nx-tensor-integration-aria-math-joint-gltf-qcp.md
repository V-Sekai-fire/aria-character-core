# ADR: Nx Tensor Integration for aria_math, aria_joint, aria_gltf, and aria_qcp

**Status:** Active  
**Date:** 2025-01-07  
**Deciders:** Development Team  

## Context

Four core mathematical apps in the umbrella project currently use manual tuple-based operations instead of leveraging their existing Nx dependencies for tensor operations:

- **aria_math**: Core mathematical operations (Vector3, Matrix4, Quaternion)
- **aria_joint**: Transform operations and hierarchy management  
- **aria_gltf**: Mesh processing and geometric transformations
- **aria_qcp**: Quaternion-based point cloud registration

While all apps have `:nx` dependencies, they're not utilizing Nx tensors for numerical computing, missing opportunities for performance optimization, GPU acceleration, and better interoperability.

## Decision

Migrate all four apps to use Nx tensors for their core mathematical operations while maintaining API compatibility through adapter layers.

## Implementation Plan

### Phase 1: aria_math Foundation (HIGH PRIORITY)
**File**: `apps/aria_math/lib/aria_math/`

**Core Type Conversions**:
- [x] Convert Vector3 from `{x, y, z}` tuples to `Nx.tensor([x, y, z])`
  - ✅ Created `AriaMath.Vector3.Tensor` module with full Nx implementation
  - ✅ Added batch operations for multiple vectors
  - ✅ Integrated with main `AriaMath.Vector3` module
- [ ] Convert Matrix4 from 16-tuples to `Nx.tensor([[...], [...], [...], [...]])`  
- [ ] Convert Quaternion from `{w, x, y, z}` tuples to `Nx.tensor([w, x, y, z])`
- [ ] Update Primitives (Sphere, Cylinder) to use Nx tensors

**API Compatibility Layer**:
- [x] Create conversion functions: `to_nx/1`, `from_nx/1` for each type
  - ✅ Added `from_tuple/1` and `to_tuple/1` for Vector3
- [x] Maintain existing tuple-based APIs as wrappers
  - ✅ All existing Vector3 APIs preserved
- [x] Add new tensor-native APIs with `_nx` suffix
  - ✅ Added `new_nx/3`, `length_nx/1`, `normalize_nx/1`, `dot_nx/2`, `cross_nx/2`
  - ✅ Added batch operations: `length_batch/1`, `normalize_batch/1`, `dot_batch/2`, `cross_batch/2`

**Performance Optimizations**:
- [x] Replace manual arithmetic with `Nx` operations
  - ✅ All Vector3 tensor operations use optimized Nx functions
- [x] Implement batch operations for multiple vectors/matrices
  - ✅ Batch operations implemented for all core Vector3 functions
- [ ] Add GPU backend configuration options

### Phase 2: aria_joint Integration (MEDIUM PRIORITY)  
**File**: `apps/aria_joint/lib/aria_joint/`

**Transform Operations**:
- [ ] Update `Transform.get_local/1` to use Nx matrix operations
- [ ] Convert hierarchy calculations to tensor operations
- [ ] Optimize batch transform updates for multiple joints

**Registry Integration**:
- [ ] Update joint storage to handle Nx tensors
- [ ] Maintain serialization compatibility
- [ ] Add tensor validation in dirty state management

### Phase 3: aria_gltf Mesh Processing (MEDIUM PRIORITY)
**File**: `apps/aria_gltf/lib/aria_gltf/`

**Mesh Operations**:
- [ ] Convert vertex attribute processing to Nx tensors
- [ ] Implement tensor-based mesh transformations
- [ ] Add batch processing for multiple primitives
- [ ] Optimize accessor data handling with Nx

**Buffer Management**:
- [ ] Integrate Nx with glTF buffer/bufferView system
- [ ] Add efficient tensor serialization for glTF export
- [ ] Support GPU-accelerated mesh operations

### Phase 4: aria_qcp Algorithm Optimization (LOW PRIORITY)
**File**: `apps/aria_qcp/lib/aria_qcp/`

**QCP Algorithm**:
- [ ] Convert point cloud data to Nx tensors
- [ ] Implement tensor-based characteristic polynomial calculation
- [ ] Optimize eigenvalue/eigenvector computations with Nx
- [ ] Add batch processing for multiple point cloud pairs

**Validation System**:
- [ ] Update geometric validation to use Nx operations
- [ ] Implement tensor-based motion validation
- [ ] Optimize convergence checking with Nx

## Implementation Strategy

### Step 1: Dependency Standardization
1. Update all apps to use consistent Nx version (0.10.0)
2. Add Nx compiler configuration for optimization
3. Configure GPU backends where beneficial

### Step 2: Core Type Migration (aria_math)
1. Implement new tensor-based core types
2. Create compatibility layer for existing APIs
3. Add comprehensive test coverage for tensor operations
4. Benchmark performance improvements

### Step 3: Dependent App Updates
1. Update aria_joint to use new aria_math tensor APIs
2. Migrate aria_gltf mesh operations to tensors
3. Optimize aria_qcp algorithm with tensor operations
4. Validate cross-app integration

### Step 4: Performance Optimization
1. Enable GPU acceleration where appropriate
2. Implement batch operations for performance-critical paths
3. Add benchmarking and performance monitoring
4. Optimize memory usage patterns

## Success Criteria

- [ ] All mathematical operations use Nx tensors internally
- [ ] Existing APIs maintain backward compatibility
- [ ] Performance improvements measurable in benchmarks
- [ ] GPU acceleration available for supported operations
- [ ] All tests pass with tensor-based implementations
- [ ] Memory usage optimized for large datasets

## Consequences

**Benefits**:
- **Performance**: Optimized numerical computing with potential GPU acceleration
- **Scalability**: Efficient batch operations for large datasets
- **Interoperability**: Better integration with ML/AI libraries
- **Maintainability**: Cleaner mathematical code using Nx operations

**Risks**:
- **Complexity**: Additional abstraction layer for compatibility
- **Memory**: Potential increased memory usage for small operations
- **Dependencies**: Stronger coupling to Nx ecosystem
- **Migration**: Significant code changes across multiple apps

## Related ADRs

- ADR-041: Apps todo file management (umbrella app structure)
- ADR-042: Systematic cross-app dependency migration

## Current Focus

Starting with aria_math as the foundation since all other apps depend on it. The tensor conversion will provide the base types that other apps can then adopt.
