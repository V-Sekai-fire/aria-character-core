# AriaQcp

Quaternion-Based Characteristic Polynomial (QCP) algorithm implementation for optimal superposition of point sets.

## Overview

AriaQcp provides a robust, numerically stable implementation of the QCP algorithm for calculating optimal rotation and translation to align two sets of 3D points. This is particularly useful for:

- Molecular structure alignment in computational biology
- Point cloud registration in computer vision
- Pose estimation in robotics
- 3D model alignment in graphics applications

## Features

- **Optimal alignment**: Finds the least-squares optimal rotation and translation
- **Weighted points**: Supports per-point weighting for importance-based alignment
- **Numerical stability**: Robust handling of edge cases and numerical precision issues
- **Performance**: Efficient implementation suitable for real-time applications
- **Comprehensive validation**: Extensive input validation and error handling

## Installation

Add `aria_qcp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:aria_qcp, in_umbrella: true}
  ]
end
```

## Usage

### Basic Superposition

```elixir
# Define two point sets
moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}, {0.0, 0.0, 1.0}]
target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}, {0.0, 0.0, 1.0}]

# Calculate optimal transformation
{:ok, {rotation, translation}} = AriaQcp.superpose(moved, target)

# Apply transformation to align points
aligned_points = Enum.map(moved, fn point ->
  rotated = AriaMath.Quaternion.rotate_vector(rotation, point)
  AriaMath.Vector3.add(rotated, translation)
end)
```

### Weighted Superposition

```elixir
moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}]
weights = [1.0, 0.5]  # First point has higher importance

{:ok, {rotation, translation}} = AriaQcp.weighted_superpose(moved, target, weights, true)
```

### Rotation Only

```elixir
# Calculate only rotation, no translation
{:ok, {rotation, translation}} = AriaQcp.rotation_only(moved, target)
# translation will be {0.0, 0.0, 0.0}
```

### Custom Precision

```elixir
# Use higher precision for critical applications
{:ok, {rotation, translation}} = AriaQcp.weighted_superpose(moved, target, [], true, 1.0e-12)
```

## API Reference

### Main Functions

- `AriaQcp.superpose/4` - Basic superposition with equal weights
- `AriaQcp.weighted_superpose/5` - Full control with custom weights and precision
- `AriaQcp.rotation_only/4` - Calculate rotation without translation

### Parameters

- `moved` - List of 3D points `[{x, y, z}, ...]` to be transformed
- `target` - List of 3D points `[{x, y, z}, ...]` to align to
- `weights` - List of weights `[w1, w2, ...]` for each point pair (optional)
- `translate` - Boolean indicating whether to calculate translation
- `precision` - Numerical precision for calculations (default: 1.0e-6)

### Return Values

- `{:ok, {rotation, translation}}` - Success with quaternion rotation and vector translation
- `{:error, reason}` - Error with descriptive reason

### Error Types

- `:empty_point_sets` - One or both point sets are empty
- `:mismatched_point_set_sizes` - Point sets have different lengths
- `:mismatched_weight_count` - Weight count doesn't match point count
- `:negative_weights` - Weights contain negative values
- `:too_many_points` - Exceeds maximum point limit (10,000)
- `:invalid_weights` - Weights contain invalid values (NaN, infinity)
- `:degenerate_points` - Points contain invalid coordinates
- `:numerical_instability` - Calculation encountered numerical issues

## Mathematical Background

The QCP algorithm uses quaternion-based characteristic polynomial methods to find the optimal rotation that minimizes the root-mean-square deviation (RMSD) between two point sets. The algorithm:

1. Centers both point sets around their weighted centroids
2. Constructs the inner product matrix from point correspondences
3. Solves the characteristic polynomial to find the optimal rotation quaternion
4. Calculates the translation vector to align the centroids

## Performance Characteristics

- **Time Complexity**: O(n) where n is the number of points
- **Space Complexity**: O(1) additional space beyond input
- **Point Limits**: Up to 10,000 points supported
- **Numerical Range**: Handles coordinates from 1e-15 to 1e12

## Dependencies

- `aria_math` - Provides Vector3 and Quaternion operations

## Testing

Run the test suite:

```bash
mix test apps/aria_qcp
```

The test suite includes:

- Basic functionality tests
- Edge case handling
- Numerical stability tests
- Performance benchmarks
- Mathematical property verification

## References

- Liu P, Agrafiotis DK, & Theobald DL (2011) "Reply to comment on: Fast determination of the optimal rotation matrix for macromolecular superpositions." Journal of Computational Chemistry 32(1):185-186.
- Liu P, Agrafiotis DK, & Theobald DL (2010) "Fast determination of the optimal rotation matrix for macromolecular superpositions." Journal of Computational Chemistry 31(7):1561-1563.
- Douglas L Theobald (2005) "Rapid calculation of RMSDs using a quaternion-based characteristic polynomial." Acta Crystallogr A 61(4):478-480.

## License

MIT License - see LICENSE.md for details.
