# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQcp.QCP.Validation do
  @moduledoc """
  Main validation module for QCP algorithm results.

  Provides a unified interface for all validation functions by delegating
  to specialized validation submodules:

  - `Core`: Basic input validation and numerical stability
  - `Geometric`: Rotation and geometric property validation
  - `Optimization`: RMSD minimization and optimality checks
  - `Motion`: Minimal jerk, torque, and motion coordination
  """

  alias AriaQcp.QCP.Validation.{Core, Geometric, Optimization, Motion}
  alias AriaMath.Vector3

  @default_tolerance 1.0e-10

  @type point_set :: [Vector3.t()]
  @type weights :: [float()]
  @type rotation :: {float(), float(), float(), float()}
  @type translation :: Vector3.t()
  @type validation_error ::
    Core.validation_error() |
    Geometric.validation_error() |
    Optimization.validation_error() |
    Motion.validation_error()

  # Core validation functions

  @doc """
  Validates all inputs for the QCP algorithm.
  """
  @spec validate_inputs(point_set(), point_set(), weights()) :: :ok | {:error, validation_error()}
  defdelegate validate_inputs(moved, target, weights), to: Core

  @doc """
  Validates point sets for basic requirements.
  """
  @spec validate_point_sets(point_set(), point_set()) :: :ok | {:error, validation_error()}
  defdelegate validate_point_sets(moved, target), to: Core

  @doc """
  Validates weight array for consistency and numerical stability.
  """
  @spec validate_weights(weights(), non_neg_integer()) :: :ok | {:error, validation_error()}
  defdelegate validate_weights(weights, point_count), to: Core

  @doc """
  Validates numerical stability of point sets.
  """
  @spec validate_numerical_stability(point_set(), point_set()) :: :ok | {:error, validation_error()}
  defdelegate validate_numerical_stability(moved, target), to: Core

  @doc """
  Checks if all vectors in a point set are valid (finite numbers).
  """
  @spec all_valid_vectors?(point_set()) :: boolean()
  defdelegate all_valid_vectors?(points), to: Core

  @doc """
  Checks if a number is finite (not NaN or infinity).
  """
  @spec is_finite_number?(number()) :: boolean()
  defdelegate is_finite_number?(x), to: Core

  @doc """
  Calculates the maximum span (range) of points in any dimension.
  """
  @spec calculate_point_span(point_set()) :: float()
  defdelegate calculate_point_span(points), to: Core

  # Geometric validation functions

  @doc """
  Validates that a quaternion represents a valid rotation (normalized).
  """
  @spec validate_rotation(rotation(), float()) :: :ok | {:error, validation_error()}
  defdelegate validate_rotation(rotation, tolerance \\ @default_tolerance), to: Geometric

  @doc """
  Validates that applying a rotation to moved points aligns them with target points.
  """
  @spec validate_alignment(rotation(), translation(), point_set(), point_set(), float()) :: :ok | {:error, validation_error()}
  defdelegate validate_alignment(rotation, translation, moved_points, target_points, tolerance \\ @default_tolerance), to: Geometric

  @doc """
  Validates that two unit vectors are aligned (pointing in same direction).
  """
  @spec validate_vector_alignment(Vector3.t(), Vector3.t(), float()) :: :ok | {:error, validation_error()}
  defdelegate validate_vector_alignment(vector1, vector2, tolerance \\ @default_tolerance), to: Geometric

  @doc """
  Validates that a rotation represents approximately the expected angle.
  """
  @spec validate_rotation_angle(rotation(), float(), float()) :: :ok | {:error, validation_error()}
  defdelegate validate_rotation_angle(rotation, expected_angle_radians, tolerance \\ @default_tolerance), to: Geometric

  @doc """
  Validates that two quaternions represent the same rotation (handles q and -q equivalence).
  """
  @spec validate_rotations_equivalent(rotation(), rotation(), float()) :: :ok | {:error, validation_error()}
  defdelegate validate_rotations_equivalent(rotation1, rotation2, tolerance \\ @default_tolerance), to: Geometric

  @doc """
  Validates that a rotation preserves distances between points.
  """
  @spec validate_distances_preserved(rotation(), point_set(), float()) :: :ok | {:error, validation_error()}
  defdelegate validate_distances_preserved(rotation, points, tolerance \\ @default_tolerance), to: Geometric

  @doc """
  Validates that a rotation is a proper rotation (determinant = +1, not a reflection).
  """
  @spec validate_proper_rotation(rotation(), float()) :: :ok | {:error, validation_error()}
  defdelegate validate_proper_rotation(rotation, tolerance \\ @default_tolerance), to: Geometric

  @doc """
  Validates that a rotation preserves orthogonality of basis vectors.
  """
  @spec validate_orthogonality_preserved(rotation(), float()) :: :ok | {:error, validation_error()}
  defdelegate validate_orthogonality_preserved(rotation, tolerance \\ @default_tolerance), to: Geometric

  @doc """
  Validates that a transformation achieves the expected geometric result for known test cases.
  """
  @spec validate_known_transformation(rotation(), translation(), atom(), float()) :: :ok | {:error, validation_error()}
  defdelegate validate_known_transformation(rotation, translation, test_case, tolerance \\ @default_tolerance), to: Geometric

  # Optimization validation functions

  @doc """
  Validates that the transformation achieves minimal RMSD (Root Mean Square Deviation).
  """
  @spec validate_minimal_rmsd(rotation(), translation(), point_set(), point_set(), float()) :: :ok | {:error, validation_error()}
  defdelegate validate_minimal_rmsd(rotation, translation, moved_points, target_points, tolerance \\ @default_tolerance), to: Optimization

  @doc """
  Validates that the rotation uses the minimal angle to achieve the transformation.
  """
  @spec validate_minimal_rotation_angle(rotation(), float(), float()) :: :ok | {:error, validation_error()}
  defdelegate validate_minimal_rotation_angle(rotation, expected_max_angle, tolerance \\ @default_tolerance), to: Optimization

  @doc """
  Validates that the transformation is efficient (minimal combined rotation and translation).
  """
  @spec validate_transformation_efficiency(rotation(), translation(), atom(), float()) :: :ok | {:error, validation_error()}
  defdelegate validate_transformation_efficiency(rotation, translation, expected_type, tolerance \\ @default_tolerance), to: Optimization

  @doc """
  Validates against known optimal transformations for standard geometric cases.
  """
  @spec validate_against_known_optimal(rotation(), translation(), atom(), float()) :: :ok | {:error, validation_error()}
  defdelegate validate_against_known_optimal(rotation, translation, test_case, tolerance \\ @default_tolerance), to: Optimization

  @doc """
  Validates that the transformation represents the globally optimal solution.
  """
  @spec validate_globally_optimal(rotation(), translation(), point_set(), point_set(), float()) :: :ok | {:error, validation_error()}
  defdelegate validate_globally_optimal(rotation, translation, moved_points, target_points, tolerance \\ @default_tolerance), to: Optimization

  # Motion validation functions

  @doc """
  Validates that the transformation uses minimal torque (rotational effort).
  """
  @spec validate_minimal_torque(rotation(), float()) :: :ok | {:error, validation_error()}
  defdelegate validate_minimal_torque(rotation, tolerance \\ @default_tolerance), to: Motion

  @doc """
  Validates that the transformation uses minimal jerk (smoothest motion).
  """
  @spec validate_minimal_jerk(rotation(), translation(), float()) :: :ok | {:error, validation_error()}
  defdelegate validate_minimal_jerk(rotation, translation, tolerance \\ @default_tolerance), to: Motion

  @doc """
  Validates minimal angular jerk for rotational motion.
  """
  @spec validate_minimal_angular_jerk(rotation(), float()) :: :ok | {:error, validation_error()}
  defdelegate validate_minimal_angular_jerk(rotation, tolerance \\ @default_tolerance), to: Motion

  @doc """
  Validates minimal linear jerk for translational motion.
  """
  @spec validate_minimal_linear_jerk(translation(), float()) :: :ok | {:error, validation_error()}
  defdelegate validate_minimal_linear_jerk(translation, tolerance \\ @default_tolerance), to: Motion

  @doc """
  Validates optimal coordination between rotation and translation for minimal jerk.
  """
  @spec validate_motion_coordination(rotation(), translation(), float()) :: :ok | {:error, validation_error()}
  defdelegate validate_motion_coordination(rotation, translation, tolerance \\ @default_tolerance), to: Motion

  # Comprehensive validation functions

  @doc """
  Performs comprehensive validation of QCP algorithm results.

  Validates all aspects: inputs, geometry, optimization, and motion properties.
  """
  @spec validate_comprehensive(rotation(), translation(), point_set(), point_set(), weights(), float()) :: :ok | {:error, validation_error()}
  def validate_comprehensive(rotation, translation, moved_points, target_points, weights, tolerance \\ @default_tolerance) do
    with :ok <- Core.validate_inputs(moved_points, target_points, weights),
         :ok <- Geometric.validate_rotation(rotation, tolerance),
         :ok <- Geometric.validate_alignment(rotation, translation, moved_points, target_points, tolerance),
         :ok <- Optimization.validate_minimal_rmsd(rotation, translation, moved_points, target_points, tolerance),
         :ok <- Motion.validate_minimal_jerk(rotation, translation, tolerance) do
      :ok
    end
  end

  @doc """
  Performs basic validation suitable for most use cases.

  Validates essential properties without expensive comprehensive checks.
  """
  @spec validate_basic(rotation(), translation(), point_set(), point_set(), weights(), float()) :: :ok | {:error, validation_error()}
  def validate_basic(rotation, translation, moved_points, target_points, weights, tolerance \\ @default_tolerance) do
    with :ok <- Core.validate_inputs(moved_points, target_points, weights),
         :ok <- Geometric.validate_rotation(rotation, tolerance),
         :ok <- Geometric.validate_alignment(rotation, translation, moved_points, target_points, tolerance) do
      :ok
    end
  end

  @doc """
  Validates transformation for known test cases with appropriate tolerances.

  Uses relaxed tolerances suitable for QCP algorithm numerical precision.
  """
  @spec validate_for_test_case(rotation(), translation(), point_set(), point_set(), atom(), float()) :: :ok | {:error, validation_error()}
  def validate_for_test_case(rotation, translation, moved_points, target_points, test_case, tolerance \\ @default_tolerance) do
    # Use more generous tolerance for test validation due to QCP numerical precision
    test_tolerance = tolerance * 1000

    with :ok <- Geometric.validate_rotation(rotation, test_tolerance),
         :ok <- Geometric.validate_alignment(rotation, translation, moved_points, target_points, test_tolerance),
         :ok <- Optimization.validate_against_known_optimal(rotation, translation, test_case, test_tolerance) do
      :ok
    end
  end
end
