# ADR-019: 3D Coordinates with Godot Conventions

## Status

Accepted

## Context

The temporal planner must use a coordinate system that supports future 3D expansion while maintaining simplicity for weekend implementation, with compatibility for eventual Godot engine integration.

## Decision

Use 3D coordinates with Godot engine conventions for future compatibility, but keep all movement on Z=0 for weekend implementation speed.

## Rationale

- **Future Compatibility**: Follow Godot's right-handed 3D coordinate system for seamless integration
- **Weekend Simplicity**: All TimeStrike action happens on Z=0 plane for rapid implementation
- **Extensibility**: Data structures ready for multi-level expansion without code rewrite
- **Direct Translation**: Positions translate directly to Godot Vector3 without transformation

## Implementation

### Godot Coordinate System

- **X-axis**: Points right (positive = east, negative = west)
- **Y-axis**: Points up (positive = up/north, negative = down/south)
- **Z-axis**: Points toward camera (positive = forward/out, negative = backward/into screen)
- **Right-Handed System**: Thumb=+X, Index=+Y, Middle=+Z

### Weekend Implementation (Z=0 Plane)

- **Movement Plane**: All agents move in X-Y plane only: `{x, y, 0}`
- **Map Coordinates**: X=0-24 (width), Y=0-9 (height), Z=0 (ground level)
- **Distance Calculation**: `sqrt((x2-x1)² + (y2-y1)²)` (Z difference always 0)
- **Future Ready**: Z coordinate stored in all position data for later expansion

### Battlefield Layout

- **X Range**: 0 to 25 (width, left to right)
- **Y=0**: Ground level for all agents and terrain
- **Z Range**: 0 to 10 (depth, near to far from camera)
- **Agent Height**: Y + 0.3 for capsule positioning above ground
- **Camera View**: Looking down at Y=0 plane from positive Y position

## Technical Details

```elixir
# All positions use 3D coordinates with Z=0
position: {12, 5, 0}  # Godot-compatible Vector3
movement_speed: 3.0   # units per second in X-Y plane
target: {18, 7, 0}    # destination coordinates

# Future Godot integration (no conversion needed)
# AriaEngine {5, 3, 0} → Godot Vector3(5, 3, 0)
```

## Weekend Implementation Benefits

- **Development Speed**: 2D pathfinding and collision much faster to implement
- **Debugging Ease**: Easier to visualize and debug in 2D displays
- **Mathematical Simplicity**: Distance calculations avoid Z-axis complexity
- **Upgrade Path**: Future 3D upgrade requires no coordinate system changes

## Consequences

### Positive

- Future Godot integration with zero coordinate transformation
- Maintains 3D-ready data structures throughout development
- Simplifies weekend implementation while preserving extensibility
- Clear mathematical foundation for distance and movement calculations

### Negative

- May not fully exercise 3D coordinate system during initial development
- Z=0 limitation may not reveal 3D-specific edge cases
- Potential confusion between 2D implementation and 3D data structures
- Unused coordinate dimension adds minor memory overhead

## Related Decisions

- Links to ADR-010 (Map & Terrain System) for spatial framework
- Supports ADR-018 (MVP Definition) with 3D coordinate integration
- Enables ADR-028 (Three.js 3D Visualization) with native coordinate support
- Implements ADR-029 (Godot Coordinate Convention) enforcement
