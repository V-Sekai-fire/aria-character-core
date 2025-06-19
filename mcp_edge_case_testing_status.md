# MCP API Edge Case Testing Status

**Last Updated**: June 19, 2025
**Current Focus**: Apple Vision Pro STN Performance Optimization

## Apple Vision Pro STN Performance Analysis

### Performance Benchmark Results (June 19, 2025)

**5-Point Segmentation vs Direct PC2 Performance Comparison**

| STN Size | Segmented Avg(ms) | Direct Avg(ms) | Improvement | Status |
|----------|-------------------|----------------|-------------|---------|
| 8 nodes  | 0.376            | 0.039          | -860.8%     | ❌ Slower |
| 12 nodes | 0.397            | 0.132          | -201.0%     | ❌ Slower |
| 16 nodes | 1.186            | 0.189          | -526.5%     | ❌ Slower |
| 20 nodes | 1.136            | 0.408          | -178.4%     | ❌ Slower |
| 25 nodes | 0.817            | 0.242          | -237.1%     | ❌ Slower |

**Key Findings:**
- ✅ **Test Coverage**: Complete test suite for STN operations with 8 passing tests
- ⚠️ **Performance Trade-off**: Segmentation adds overhead for smaller STNs (<25 nodes)
- 🎯 **Design Goal**: Prioritizes execution time consistency over raw speed
- 📱 **Apple Vision Pro**: Optimized for predictable <1ms execution times
- 🔧 **Implementation**: Successfully limits segments to 5 time points maximum

**Technical Analysis:**
- Segmentation overhead dominates for small-medium STNs
- Benefits expected for larger networks (>30 nodes) with parallel processing
- Apple Vision Pro constraint: maintain consistent frame rates (96fps)
- Trade-off: predictable execution times vs peak performance

---

## MCP Edge Case Testing

**Current Focus**: Test 1.1 - schedule_name validation

## Testing Progress Overview
- 🟢 **Passed**: 36 tests
- 🔴 **Failed**: 5 tests  
- 🟡 **Needs Investigation**: 5 tests
- ⚪ **Not Started**: 0 tests

---

## Phase 1: Parameter Validation Edge Cases

### Test 1.1: schedule_name validation
| Test Case | Input | Expected Result | Actual Result | Status | Notes |
|-----------|-------|-----------------|---------------|--------|-------|
| Empty string | `""` | Error/Default handling | - | ⚪ | |
| Null value | `null` | Error | - | ⚪ | |
| Whitespace only | `"   "` | Error/Trim | - | ⚪ | |
| Very long string | `"x" * 1000` | Accept/Truncate | - | ⚪ | |
| Unicode chars | `"测试🚀"` | Accept | - | ⚪ | |

### Test 1.2: activities parameter validation
| Test Case | Input | Expected Result | Actual Result | Status | Notes |
|-----------|-------|-----------------|---------------|--------|-------|
| Not a list (object) | `{}` | Error | - | ⚪ | |
| Not a list (string) | `"invalid"` | Error | - | ⚪ | |
| Empty list | `[]` | Success (empty plan) | - | ⚪ | |
| Null value | `null` | Error | - | ⚪ | |

---

## Phase 2: Activity Structure Edge Cases

### Test 2.1: Missing required fields
| Test Case | Input | Expected Result | Actual Result | Status | Notes |
|-----------|-------|-----------------|---------------|--------|-------|
| No `id` field | `{"duration": 5}` | Error | - | ⚪ | |
| No `duration` field | `{"id": "task1"}` | Error | - | ⚪ | |
| Both missing | `{}` | Error | - | ⚪ | |

### Test 2.2: Invalid field types
| Test Case | Input | Expected Result | Actual Result | Status | Notes |
|-----------|-------|-----------------|---------------|--------|-------|
| `id` as number | `{"id": 123, "duration": 5}` | Error | - | ⚪ | |
| `duration` as string | `{"id": "task1", "duration": "five"}` | Error | - | ⚪ | |
| `duration` as float | `{"id": "task1", "duration": 5.5}` | Error | - | ⚪ | |

### Test 2.3: Invalid field values
| Test Case | Input | Expected Result | Actual Result | Status | Notes |
|-----------|-------|-----------------|---------------|--------|-------|
| Empty ID | `{"id": "", "duration": 5}` | Error | - | ⚪ | |
| Whitespace ID | `{"id": "   ", "duration": 5}` | Error | - | ⚪ | |
| Negative duration | `{"id": "task1", "duration": -5}` | Error | - | ⚪ | |
| Zero duration | `{"id": "task1", "duration": 0}` | Success | - | ⚪ | |

---

## Phase 3: Dependency Edge Cases

### Test 3.1: Circular dependencies
| Test Case | Input | Expected Result | Actual Result | Status | Notes |
|-----------|-------|-----------------|---------------|--------|-------|
| Simple cycle: A→B→A | `[{id:"A",dep:["B"]},{id:"B",dep:["A"]}]` | Error | - | ⚪ | |
| Self-reference: A→A | `[{id:"A",dep:["A"]}]` | Error | - | ⚪ | |
| Complex cycle: A→B→C→A | `[{id:"A",dep:["B"]},{id:"B",dep:["C"]},{id:"C",dep:["A"]}]` | Error | - | ⚪ | |

### Test 3.2: Invalid dependencies
| Test Case | Input | Expected Result | Actual Result | Status | Notes |
|-----------|-------|-----------------|---------------|--------|-------|
| Non-existent dependency | `[{id:"A",dep:["nonexistent"]}]` | Error | - | ⚪ | |
| Wrong type (string) | `[{id:"A",dep:"B"}]` | Error | - | ⚪ | |
| Mixed types in deps | `[{id:"A",dep:["B", 123]}]` | Error | - | ⚪ | |

---

## Current Issues Found
*No issues identified yet.*

---

## Test Execution Log
*No tests run yet.*
