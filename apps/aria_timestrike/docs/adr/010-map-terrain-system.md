# ADR-010: Map & Terrain System

## Status
Accepted

## Context
The temporal planner needs a spatial framework for calculating movement, line-of-sight, and tactical positioning while maintaining simplicity for weekend implementation scope.

## Decision
2D grid-based system with optional Z-level hints for future 3D expansion (weekend-scope appropriate).

## Rationale
- **Weekend Scope**: Focus on 2D grid with clear, simple mechanics for rapid implementation
- **Future Compatibility**: Data structures support Z-coordinate extension without breaking changes
- **Simple Implementation**: 2D grid foundation reduces complexity while maintaining functionality
- **Extensible Design**: Can be upgraded to full 3D post-weekend without code rewrite

## Implementation
### 2D Grid Foundation
- **Map Storage**: Simple 2D grid (25×10 for TimeStrike)
- **Coordinate System**: {x, y} coordinates with optional :z metadata for future expansion
- **Voxel Properties**: Each grid cell has properties: `:walkable`, `:cover`, `:chasm`, `:escape_zone`

### Movement & Visibility
- **Movement**: Euclidean distance calculation in 2D plane
- **Cover Mechanics**: Adjacent to cover provides 25% damage reduction
- **Path Validation**: Check each cell in 2D path for `:walkable` property
- **Line-of-Sight**: Simple 2D bresenham algorithm for visibility checks

### Future 3D Readiness
- **Z-Coordinate Storage**: Z-coordinate stored but not used in calculations initially
- **Upgrade Path**: Clear migration to 3D without architectural changes

## Technical Details
```elixir
# Map cell structure
%{
  walkable: true,
  cover: false,
  chasm: false,
  escape_zone: false,
  z_level: 0  # Future expansion
}

# Movement calculation (2D for weekend)
distance = :math.sqrt(:math.pow(x2-x1, 2) + :math.pow(y2-y1, 2))
```

## Consequences
### Positive
- Rapid implementation suitable for weekend timeline
- Clear spatial framework for tactical calculations
- Future 3D extensibility without breaking changes
- Simple debugging and visualization

### Negative
- Limited tactical complexity in 2D-only implementation
- May not fully exercise 3D coordinate system initially
- Cover mechanics simplified compared to full 3D
- Line-of-sight calculations less sophisticated than 3D

## Related Decisions
- Links to ADR-009 (Action Duration Calculations) for movement timing
- Supports ADR-019 (3D Coordinates with Godot Conventions) for future expansion
- Enables ADR-023 (MVP Timing Implementation) with simple distance calculations
