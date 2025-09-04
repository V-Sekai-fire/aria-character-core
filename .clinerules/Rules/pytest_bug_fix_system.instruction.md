# Pytest Bug Fix System - Systematic Approach for unittest→pytest Conversion Issues

## The Principle

During unittest→pytest conversions, consistently-occurring bugs emerge that require structured resolution. This system provides categorization and systematic fixes for the most common pytest conversion issues.

## Bug Pattern Categorization

### **Pattern 1: Fixture Name Mismatches**
- **Symptoms**: "fixture not found" errors, `generic_blender_instances` not defined
- **Root Cause**: Incorrect fixture names from unittest→pytest conversion
- **Solution**:
  1. Add missing fixture definitions to `conftest.py`
  2. Map old fixture names to new ones
  3. Ensure backward compatibility

### **Pattern 2: Attribute Access Errors**
- **Symptoms**: "'BlenderTestMixin' object has no attribute 'sender'"
- **Root Cause**: Missing attribute initialization in mixin classes
- **Solution**:
  1. Implement proper `__init__` method in mixin classes
  2. Initialize all expected attributes (sender, receiver, _blenders, etc.)
  3. Add fallback handling for ImportError cases

### **Pattern 3: Return Value Issues**
- **Symptoms**: "NoneType object is not subscriptable" errors
- **Root Cause**: Setup functions return None instead of expected objects
- **Solution**:
  1. Audit all setup functions for proper return values
  2. Add defensive null checks before array access
  3. Improve error handling for missing dependencies

### **Pattern 4: Legacy Method Remnants**
- **Symptoms**: "AttributeError: 'VRtistTestCase' object has no attribute 'setUp'"
- **Root Cause**: Remaining unittest-style method calls
- **Solution**:
  1. Complete pytest function conversion
  2. Remove all class-based inheritance patterns
  3. Convert all test methods to pytest functions

### **Pattern 5: Module Import Issues**
- **Symptoms**: "ModuleNotFoundError: No module named 'mixer'"
- **Root Cause**: Server module path issues in broadcaster tests
- **Solution**:
  1. Fix module import paths
  2. Add fallback handling for missing dependencies
  3. Update server process configuration

## Implementation Priority Framework

### **Phase 1: Fix Infrastructure Issues (Priority: HIGH)**
1. Add critical fixtures to `conftest.py`:
   - `blender_instances()` - Primary Blender fixture
   - `generic_blender_instances()` - Backward compatibility
   - `shape_key_setup()` - Shape key fixture
   - `scene_blender_instances()` - Scene-specific fixture

2. Fix BlenderTestMixin attributes:
   - Implement proper `__init__` method
   - Initialize sender, receiver, _blenders
   - Add ImportError handling

3. Fix blender_setup() function:
   - Ensure non-None return value
   - Add proper error handling
   - Defensive null checks

### **Phase 2: Fix Legacy Remnants (Priority: MEDIUM)**
1. Complete class→function conversion
2. Remove unittest method calls
3. Convert all test structures to pytest patterns

### **Phase 3: Fix Module Import Issues (Priority: LOW)**
1. Update server import paths
2. Add dependency fallbacks
3. Configure broadcaster modules

## Quality Assurance Framework

### **Validation Steps:**
1. **Collection Test**: `pytest tests --collect-only -v`
2. **Individual File Tests**: Test each file separately
3. **Integration Testing**: `pytest tests --tb=short`
4. **Error Code Tracking**: Monitor specific error patterns

### **Success Metrics:**
- ✅ **81/81 tests collected** (no collection errors)
- ✅ **Zero "fixture not found" errors**
- ✅ **Zero "has no attribute" errors**
- ✅ **Zero "NoneType object is not" errors**
- ✅ **Zero legacy method errors**
- ✅ **Stable broadcaster server imports**

## Implementation Guidelines

### **Fixture Conventions:**
```python
@pytest.fixture
def blender_instances():
    """Standard Blender fixture - returns [sender, receiver]"""
    return blender_setup()

@pytest.fixture  
def generic_blender_instances():
    """Alias for blender_instances - backward compatibility"""
    return blender_setup()

