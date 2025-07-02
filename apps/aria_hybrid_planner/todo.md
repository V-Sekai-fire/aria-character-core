# Major Redundancies Found:

### 1. **State Module Duplication**

- `lib/state.ex` - Generic state interface (delegates to actual implementation)
- `lib/aria_hybrid_planner/state.ex` - Actual state implementation

### 2. **Multigoal Module Duplication**

- `lib/multigoal.ex` - Simple local Multigoal module (basic struct)
- `lib/aria_hybrid_planner/multigoal.ex` - Full AriaEngineCore.Multigoal implementation (comprehensive)

### 3. **Core Module Duplication**

- `lib/core.ex` - Simple local Core module (basic struct)
- `lib/aria_hybrid_planner/core.ex` - More comprehensive core implementation

### 4. **Planning Infrastructure Overlap**

- Multiple planning-related modules that likely have overlapping functionality
- Old AriaEngine compatibility shims alongside new implementations

## Consolidation Plan:

### Phase 1: **Identify Usage Patterns**

- Analyze which versions of each module are actually being used
- Map dependencies to understand which implementations are active
- Identify dead code that can be safely removed

### Phase 2: **Consolidate State Management**

- Keep the comprehensive `AriaHybridPlanner.State` implementation
- Remove the generic `State` interface wrapper
- Update all references to use the consolidated version

### Phase 3: **Consolidate Multigoal Handling**

- Keep the full-featured `AriaEngineCore.Multigoal` implementation
- Remove the simple `Multigoal` stub
- Ensure all multigoal operations use the comprehensive version

### Phase 4: **Consolidate Core Functionality**

- Merge or choose between the Core implementations
- Remove redundant AriaEngine compatibility layers
- Streamline the module hierarchy

### Phase 5: **Clean Architecture**

- Establish clear module boundaries
- Remove duplicate planning utilities
- Consolidate similar functionality into single modules
