# AST Translator OperationRegistry Expansion TODO

## Overview

Expand OperationRegistry from ~50 basic operations to full KHR_interactivity node coverage.

**Current State**: Only 2 of 21 KHR modules registered, ~22 operations mapped
**Target State**: All 21 KHR modules registered and mapped to Elixir AST patterns

**CRITICAL DISCOVERY**: 
- **21 implementation files** in `lib/aria_engine/node_library/khr_interactivity/`
- **Only 2 modules registered** in `khr_interactivity_domain.ex` 
- **19 unregistered modules** containing potentially 100+ operations
- **Real scope is much larger** than initially assessed

**Step 0: Register Missing Modules (BLOCKING)**
Before expanding OperationRegistry, must first register all 21 modules in `khr_interactivity_domain.ex`
</replace_in_file>

## Phase 1: Complete Math Operations Coverage

### Phase 1A: Math Arithmetic (PRIORITY: HIGH)
**File**: `lib/aria_engine/node_library/khr_interactivity/math_arithmetic.ex`

**Currently Missing** (need to add to OperationRegistry):
- [ ] `math_sign` - Sign function (-1, 0, 1)
- [ ] `math_neg` - Negation operation  
- [ ] `math_rem` - Remainder operation (already in KHR, not in registry)
- [ ] `math_clamp` - Clamp operation (already mapped but verify)
- [ ] `math_floor` - Floor operation (already mapped but verify)
- [ ] `math_ceil` - Ceiling operation (already mapped but verify)
- [ ] `math_round` - Round operation (already mapped but verify)
- [ ] `math_trunc` - Truncate operation
- [ ] `math_fract` - Fractional operation
- [ ] `math_saturate` - Saturate operation (clamp to [0,1])
- [ ] `math_mix` - Linear interpolation operation

**Elixir AST Patterns Needed**:
- [ ] Map `:sign` function call
- [ ] Map unary `-` operator (negation)
- [ ] Map `rem/2` function 
- [ ] Map `trunc/1` function
- [ ] Map custom `saturate/1`, `mix/3` functions

### Phase 1B: Math Constants
**File**: `lib/aria_engine/node_library/khr_interactivity/math_constants.ex`

**Operations to Map**:
- [ ] `math_pi` - π constant
- [ ] `math_e` - e constant  
- [ ] `math_infinity` - Infinity constant
- [ ] `math_nan` - NaN constant

**Elixir AST Patterns Needed**:
- [ ] Map `:math.pi()` calls
- [ ] Map `Math.pi` module calls
- [ ] Map literal constants

### Phase 1C: Math Trigonometry  
**File**: `lib/aria_engine/node_library/khr_interactivity/math_trigonometry.ex`

**Operations to Map**:
- [ ] `math_sin`, `math_cos`, `math_tan`
- [ ] `math_asin`, `math_acos`, `math_atan`, `math_atan2`  
- [ ] `math_sinh`, `math_cosh`, `math_tanh`
- [ ] `math_asinh`, `math_acosh`, `math_atanh`

**Elixir AST Patterns Needed**:
- [ ] Map `:math.sin(x)` calls
- [ ] Map `Math.sin(x)` module calls

### Phase 1D: Math Special Functions
**File**: `lib/aria_engine/node_library/khr_interactivity/math_special.ex`

**Operations to Map**:
- [ ] `math_sqrt`, `math_pow`, `math_exp`, `math_log`
- [ ] `math_log2`, `math_log10`
- [ ] Advanced special functions

### Phase 1E: Math Comparison  
**File**: `lib/aria_engine/node_library/khr_interactivity/math_comparison.ex`

**Operations to Map**:
- [ ] `math_equal`, `math_not_equal` (verify current mapping)
- [ ] `math_less_than`, `math_greater_than` (verify current mapping)  
- [ ] `math_less_equal`, `math_greater_equal` (verify current mapping)
- [ ] Additional comparison operations

### Phase 1F: Math Boolean
**File**: `lib/aria_engine/node_library/khr_interactivity/math_boolean.ex`

**Operations to Map**:
- [ ] `math_bool_and`, `math_bool_or`, `math_bool_not` (verify current mapping)
- [ ] `math_bool_xor`, `math_bool_nand`, `math_bool_nor`

### Phase 1G: Math Integer
**File**: `lib/aria_engine/node_library/khr_interactivity/math_integer.ex`

**Operations to Map**:
- [ ] Integer-specific arithmetic operations
- [ ] Integer overflow handling
- [ ] Integer-specific min/max/clamp

### Phase 1H: Math Bitwise  
**File**: `lib/aria_engine/node_library/khr_interactivity/math_bitwise.ex`

**Operations to Map**:
- [ ] `math_bitwise_and`, `math_bitwise_or`, `math_bitwise_xor`
- [ ] `math_bitwise_not`, `math_bitwise_left_shift`, `math_bitwise_right_shift`
- [ ] `math_bitwise_test_bit`, `math_bitwise_set_bit`, `math_bitwise_clear_bit`, `math_bitwise_toggle_bit`

**Elixir AST Patterns Needed**:
- [ ] Map `band/2`, `bor/2`, `bxor/2`, `bnot/1`
- [ ] Map `bsl/2`, `bsr/2` (bit shift operations)

### Phase 1I: Math Vector Operations
**File**: `lib/aria_engine/node_library/khr_interactivity/math_vector.ex`

**Operations to Map**:
- [ ] Vector 2D operations: `math_vector2_add`, `math_vector2_sub`, etc.
- [ ] Vector 3D operations: `math_vector3_add`, `math_vector3_sub`, etc.  
- [ ] Vector 4D operations: `math_vector4_add`, `math_vector4_sub`, etc.
- [ ] Vector utility: `math_vector_normalize`, `math_vector_dot`, `math_vector_cross`

### Phase 1J: Math Matrix Operations
**File**: `lib/aria_engine/node_library/khr_interactivity/math_matrix.ex`

**Operations to Map**:
- [ ] Matrix 2x2, 3x3, 4x4 operations
- [ ] Matrix arithmetic, multiplication, inverse, transpose
- [ ] Matrix transformation operations

### Phase 1K: Math Quaternion  
**File**: `lib/aria_engine/node_library/khr_interactivity/math_quaternion.ex`

**Operations to Map**:
- [ ] Quaternion arithmetic and utility operations
- [ ] Quaternion rotations and conversions

### Phase 1L: Math Advanced
**File**: `lib/aria_engine/node_library/khr_interactivity/math_advanced.ex`

**Operations to Map**:
- [ ] Advanced mathematical operations
- [ ] Complex transformations and utilities

### Phase 1M: Math Swizzle  
**File**: `lib/aria_engine/node_library/khr_interactivity/math_swizzle.ex`

**Operations to Map**:
- [ ] Vector/matrix combine operations: `math_combine2`, `math_combine3`, `math_combine4`
- [ ] Vector/matrix extract operations: `math_extract2`, `math_extract3`, `math_extract4`
- [ ] Matrix combine/extract: `math_combine2x2`, `math_extract4x4`, etc.

## Phase 2: Control Flow Operations

### Phase 2A: Basic Control Flow
**File**: `lib/aria_engine/node_library/khr_interactivity/control_flow.ex`

**Operations to Map**:
- [ ] `flow_sequence` - Sequential execution
- [ ] `flow_branch` - Conditional branching (if/then/else)
- [ ] Basic control structures

**Elixir AST Patterns Needed**:
- [ ] Map `if condition do ... else ... end` 
- [ ] Map `case ... do ... end`
- [ ] Map sequential blocks `do ... end`

### Phase 2B: Advanced Control Flow
**File**: `lib/aria_engine/node_library/khr_interactivity/flow_advanced.ex`

**Operations to Map**:
- [ ] `flow_switch` - Switch statements
- [ ] `flow_while`, `flow_for` - Loop constructs
- [ ] `flow_multi_gate`, `flow_throttle` - Advanced synchronization
- [ ] `flow_delay`, `flow_cancel_delay` - Delay management

**Elixir AST Patterns Needed**:
- [ ] Map complex case/switch patterns
- [ ] Map loop constructs (challenging - may need special syntax)
- [ ] Map temporal operations

## Phase 3: Variable Management Operations

### Phase 3A: Basic Variables
**File**: `lib/aria_engine/node_library/khr_interactivity/variable_management.ex`

**Operations to Map**:
- [ ] `variable_get` - Get variable value
- [ ] `variable_set` - Set variable value  
- [ ] `variable_exists` - Check variable existence
- [ ] `variable_delete` - Delete variable

**Elixir AST Patterns Needed**:
- [ ] Map variable assignment: `var = value`
- [ ] Map variable reference: `var`
- [ ] Map special variable functions

### Phase 3B: Advanced State  
**File**: `lib/aria_engine/node_library/khr_interactivity/state_advanced.ex`

**Operations to Map**:
- [ ] `variable_set_multiple` - Batch variable updates
- [ ] `pointer_get`, `pointer_set` - Pointer operations
- [ ] `pointer_interpolate` - Advanced interpolation

## Phase 4: Event System Operations

### Phase 4A: Basic Events
**File**: `lib/aria_engine/node_library/khr_interactivity/event_system.ex`

**Operations to Map**:
- [ ] `event_send` - Send event with data
- [ ] `event_receive` - Receive event data
- [ ] `event_on_start` - On start lifecycle event
- [ ] `event_on_tick` - On tick lifecycle event

**Elixir AST Patterns Needed**:
- [ ] Map event handling patterns
- [ ] Map lifecycle hooks
- [ ] Map process communication patterns

### Phase 4B: Advanced Events
**File**: `lib/aria_engine/node_library/khr_interactivity/event_advanced.ex`

**Operations to Map**:
- [ ] Advanced event processing
- [ ] Debug operations and logging
- [ ] Event system management

## Phase 5: Animation Control Operations

### Phase 5A: Animation System
**File**: `lib/aria_engine/node_library/khr_interactivity/animation_system.ex`

**Operations to Map**:
- [ ] `animation_start`, `animation_stop` - Playback control
- [ ] `animation_pause`, `animation_resume` - Pause control
- [ ] `animation_get_time`, `animation_stop_at` - Time management  
- [ ] `animation_is_playing` - Status queries

**Elixir AST Patterns Needed**:
- [ ] Map animation control functions
- [ ] Map temporal animation patterns

## Phase 6: Type Conversion Operations

### Phase 6A: Type Conversion
**File**: `lib/aria_engine/node_library/khr_interactivity/type_conversion.ex`

**Operations to Map**:
- [ ] `type_bool_to_int`, `type_bool_to_float` - Boolean conversions
- [ ] `type_int_to_bool`, `type_int_to_float` - Integer conversions
- [ ] `type_float_to_bool`, `type_float_to_int` - Float conversions

**Elixir AST Patterns Needed**:
- [ ] Map explicit type conversion functions
- [ ] Map automatic type coercion patterns

## Implementation Strategy

### Step 1: Read and Analyze
1. Read each KHR module file systematically
2. Extract all registered operations and their signatures
3. Document required Elixir AST patterns for each

### Step 2: Expand OperationRegistry
1. Add missing operations to the registry maps
2. Define appropriate Elixir AST patterns  
3. Add type validation and metadata

### Step 3: Update PatternMatcher
1. Add pattern recognition for new operations
2. Handle complex AST structures (control flow, etc.)
3. Add pattern complexity scoring

### Step 4: Update MultiCategoryExtractor
1. Handle new operation categories
2. Support complex extraction patterns
3. Add proper dependency tracking

### Step 5: Testing
1. Add comprehensive tests for each new operation
2. Test complex combinations and edge cases
3. Validate generated KHR node sequences

### Step 6: Documentation  
1. Update operation registry documentation
2. Add usage examples for each category
3. Document AST pattern conventions

## Current Focus: Phase 1A (Math Arithmetic)

Starting with completing math arithmetic operations since they're:
- Most commonly used
- Well-defined patterns  
- Already partially implemented
- Foundation for other operations

Next: Read `khr_interactivity_domain.ex` to understand complete scope.
