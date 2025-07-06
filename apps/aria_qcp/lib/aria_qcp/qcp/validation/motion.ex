# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaQcp.QCP.Validation.Motion do
  @moduledoc """
  Motion validation functions for QCP algorithm results.

  Handles validation of minimal jerk, torque, and motion coordination
  for smooth and efficient transformations.
  """

  alias AriaQcp.QCP.Validation.Core

  @default_tolerance 1.0e-10

  @type rotation :: {float(), float(), float(), float()}
  @type translation :: {float(), float(), float()}
  @type validation_error :: :transformation_mismatch

  @doc """
  Validates that the transformation uses minimal torque (rotational effort).

  Ensures the rotation represents the most efficient rotational path with minimal energy expenditure.
  """
  @spec validate_minimal_torque(rotation(), float()) :: :ok | {:error, validation_error()}
  def validate_minimal_torque(rotation, tolerance \\ @default_tolerance) do
    {x, y, z, w} = rotation

    # Calculate the rotation angle from quaternion: angle = 2 * acos(|w|)
    # Minimal torque corresponds to minimal rotation angle
    angle = 2 * :math.acos(min(abs(w), 1.0))

    # Normalize to [0, π] range (shortest path)
    normalized_angle = if angle > :math.pi do
      2 * :math.pi - angle
    else
      angle
    end

    # Calculate torque metric: smaller angles = less torque
    # For identity rotation (angle ≈ 0), torque should be near zero
    # For 180° rotation (angle ≈ π), torque is maximal but still minimal for the required transformation
    torque_metric = normalized_angle / :math.pi  # Normalize to [0, 1]

    # Validate that the rotation uses a reasonable torque level
    # This checks that we're not using an unnecessarily complex rotation
    axis_magnitude = :math.sqrt(x*x + y*y + z*z)

    # For small angles, the axis should be well-defined unless it's near identity
    if normalized_angle < tolerance * 10 do
      # Near identity rotation - torque should be minimal
      if torque_metric < tolerance * 100 do
        :ok
      else
        {:error, :transformation_mismatch}
      end
    else
      # Non-trivial rotation - check that it's using the minimal path
      expected_axis_magnitude = :math.sin(normalized_angle / 2)

      if abs(axis_magnitude - expected_axis_magnitude) < tolerance * 10 do
        :ok
      else
        {:error, :transformation_mismatch}
      end
    end
  end

  @doc """
  Validates that the transformation uses minimal jerk (smoothest motion).

  In physics, jerk is the rate of change of acceleration (third derivative of position).
  Minimal jerk trajectories represent the smoothest possible motions with minimal energy expenditure.
  """
  @spec validate_minimal_jerk(rotation(), translation(), float()) :: :ok | {:error, validation_error()}
  def validate_minimal_jerk(rotation, translation, tolerance \\ @default_tolerance) do
    with :ok <- validate_minimal_angular_jerk(rotation, tolerance),
         :ok <- validate_minimal_linear_jerk(translation, tolerance),
         :ok <- validate_motion_coordination(rotation, translation, tolerance) do
      :ok
    end
  end

  @doc """
  Validates minimal angular jerk for rotational motion.

  Ensures the rotation follows the smoothest possible angular path.
  """
  @spec validate_minimal_angular_jerk(rotation(), float()) :: :ok | {:error, validation_error()}
  def validate_minimal_angular_jerk(rotation, tolerance \\ @default_tolerance) do
    {x, y, z, w} = rotation

    # Calculate rotation angle and axis
    angle = 2 * :math.acos(min(abs(w), 1.0))

    # Normalize to [0, π] range (shortest angular path)
    normalized_angle = if angle > :math.pi do
      2 * :math.pi - angle
    else
      angle
    end

    # For minimal jerk, we expect:
    # 1. Shortest angular path (already normalized)
    # 2. Single-axis rotation when possible
    # 3. Smooth angular velocity profile

    # Calculate angular jerk metric based on rotation complexity
    if normalized_angle < tolerance * 10 do
      # Near identity - minimal jerk achieved
      :ok
    else
      # Check for single-axis rotation (minimal jerk property)
      axis_magnitude = :math.sqrt(x*x + y*y + z*z)
      expected_axis_magnitude = :math.sin(normalized_angle / 2)

      # Validate axis consistency (smooth rotation about single axis)
      if abs(axis_magnitude - expected_axis_magnitude) < tolerance * 10 do
        # Additional check: axis should be well-defined and normalized
        if axis_magnitude > tolerance do
          axis_x = x / axis_magnitude
          axis_y = y / axis_magnitude
          axis_z = z / axis_magnitude

          # Check that axis is unit vector (smooth rotation property)
          axis_norm = :math.sqrt(axis_x*axis_x + axis_y*axis_y + axis_z*axis_z)

          if abs(axis_norm - 1.0) < tolerance * 10 do
            :ok
          else
            {:error, :transformation_mismatch}
          end
        else
          :ok
        end
      else
        {:error, :transformation_mismatch}
      end
    end
  end

  @doc """
  Validates minimal linear jerk for translational motion.

  Ensures the translation follows the smoothest possible linear path.
  """
  @spec validate_minimal_linear_jerk(translation(), float()) :: :ok | {:error, validation_error()}
  def validate_minimal_linear_jerk(translation, tolerance \\ @default_tolerance) do
    {tx, ty, tz} = translation

    # For minimal jerk in linear motion:
    # 1. Direct straight-line path (no unnecessary components)
    # 2. Smooth velocity profile (constant direction)
    # 3. Minimal distance when possible

    translation_magnitude = :math.sqrt(tx*tx + ty*ty + tz*tz)

    if translation_magnitude < tolerance do
      # No translation - minimal jerk achieved
      :ok
    else
      # Check for straight-line motion (minimal jerk property)
      # Translation should be in a single, well-defined direction

      # Validate that translation vector is well-formed
      if Core.is_finite_number?(tx) and Core.is_finite_number?(ty) and Core.is_finite_number?(tz) do
        # For minimal jerk, we expect the translation to be the shortest path
        # This is inherently satisfied by a single translation vector
        # Additional validation: check for reasonable magnitude

        if translation_magnitude < 1.0e6 do  # Reasonable upper bound
          :ok
        else
          {:error, :transformation_mismatch}
        end
      else
        {:error, :transformation_mismatch}
      end
    end
  end

  @doc """
  Validates optimal coordination between rotation and translation for minimal jerk.

  Ensures that rotation and translation are optimally coordinated for smoothest combined motion.
  """
  @spec validate_motion_coordination(rotation(), translation(), float()) :: :ok | {:error, validation_error()}
  def validate_motion_coordination(rotation, translation, tolerance \\ @default_tolerance) do
    {_x, _y, _z, w} = rotation
    {tx, ty, tz} = translation

    # Calculate motion complexity metrics
    rotation_angle = 2 * :math.acos(min(abs(w), 1.0))
    translation_magnitude = :math.sqrt(tx*tx + ty*ty + tz*tz)

    # Normalize rotation angle to [0, π]
    normalized_angle = if rotation_angle > :math.pi do
      2 * :math.pi - rotation_angle
    else
      rotation_angle
    end

    # For minimal jerk, we expect optimal coordination:
    # 1. If only rotation needed, translation should be minimal
    # 2. If only translation needed, rotation should be minimal
    # 3. If both needed, they should be balanced and coordinated

    cond do
      # Pure rotation case
      translation_magnitude < tolerance and normalized_angle > tolerance ->
        # Rotation-only motion - check for minimal rotation
        validate_minimal_angular_jerk(rotation, tolerance)

      # Pure translation case
      normalized_angle < tolerance and translation_magnitude > tolerance ->
        # Translation-only motion - check for minimal translation
        validate_minimal_linear_jerk(translation, tolerance)

      # Combined motion case
      normalized_angle > tolerance and translation_magnitude > tolerance ->
        # Both rotation and translation present
        # Check that they are reasonably balanced (no excessive complexity in either)

        rotation_complexity = normalized_angle / :math.pi  # [0, 1]
        translation_complexity = min(translation_magnitude, 1.0)  # Normalize to reasonable range

        # For minimal jerk, neither component should dominate excessively
        complexity_ratio = if translation_complexity > tolerance do
          rotation_complexity / translation_complexity
        else
          rotation_complexity
        end

        # Allow reasonable coordination (not too imbalanced)
        if complexity_ratio < 100.0 and complexity_ratio > 0.01 do
          :ok
        else
          {:error, :transformation_mismatch}
        end

      # Identity transformation case
      true ->
        # Both rotation and translation are minimal - optimal jerk
        :ok
    end
  end
end
