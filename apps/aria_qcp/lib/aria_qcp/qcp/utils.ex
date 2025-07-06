# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaQcp.QCP.Utils do
  @moduledoc """
  Utility functions for the QCP algorithm.

  Contains helper functions for quaternion operations and transformations.

  ## Examples

  ### Quaternion Canonical Representation

      iex> # Ensure quaternions always have positive w component
      iex> quat_negative_w = {0.5, 0.5, 0.5, -0.5}
      iex> canonical = AriaQcp.QCP.Utils.find_closest_quaternion_orientation(quat_negative_w)
      iex> {x, y, z, w} = canonical
      iex> w >= 0.0
      true
      iex> # Verify it represents the same rotation
      iex> import :math, only: [sqrt: 1]
      iex> magnitude = sqrt(x*x + y*y + z*z + w*w)
      iex> abs(magnitude - 1.0) < 1.0e-10
      true

  ### Quaternion Dot Product for Similarity

      iex> # Calculate similarity between two rotations
      iex> q1 = {0.0, 0.0, 0.0, 1.0}  # Identity rotation
      iex> q2 = {0.0, 0.0, 0.707, 0.707}  # 90° rotation around Z
      iex> dot_product = AriaQcp.QCP.Utils.quaternion_dot(q1, q2)
      iex> abs(dot_product - 0.707) < 0.001  # cos(45°) ≈ 0.707
      true

  ### Medical Robotics: Surgical Tool Orientation

      iex> # Ensure consistent tool orientation for surgical procedures
      iex> tool_rotation = {0.1, 0.2, 0.3, -0.9}  # Negative w component
      iex> canonical_orientation = AriaQcp.QCP.Utils.apply_rmd_flipping_check(tool_rotation)
      iex> {_, _, _, w} = canonical_orientation
      iex> w >= 0.0  # Always positive for consistent representation
      true

  ### Translation Calculation for Point Cloud Alignment

      iex> # Calculate translation needed to align centroids
      iex> alias AriaMath.Quaternion
      iex> qcp_state = %{
      ...>   translate: true,
      ...>   target_center: {5.0, 3.0, 2.0},
      ...>   moved_center: {1.0, 1.0, 1.0}
      ...> }
      iex> identity_rotation = {0.0, 0.0, 0.0, 1.0}
      iex> {:ok, translation} = AriaQcp.QCP.Utils.calculate_translation(qcp_state, identity_rotation)
      iex> {tx, ty, tz} = translation
      iex> abs(tx - 4.0) < 1.0e-10 and abs(ty - 2.0) < 1.0e-10 and abs(tz - 1.0) < 1.0e-10
      true
  """

  alias AriaMath.{Vector3, Quaternion}

  @doc """
  Finds the closest quaternion orientation (canonical representation).
  """
  @spec find_closest_quaternion_orientation(Quaternion.t()) :: Quaternion.t()
  def find_closest_quaternion_orientation({x, y, z, w}) do
    # Ensure w >= 0 for canonical quaternion representation
    # This is the standard way to resolve quaternion dual representation
    if w >= 0.0 do
      {x, y, z, w}
    else
      {-x, -y, -z, -w}
    end
  end

  @doc """
  Calculates the dot product of two quaternions.
  """
  @spec quaternion_dot(Quaternion.t(), Quaternion.t()) :: float()
  def quaternion_dot({x1, y1, z1, w1}, {x2, y2, z2, w2}) do
    x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2
  end

  @doc """
  Ensures canonical quaternion representation with w >= 0.

  This provides a consistent quaternion representation without the complex
  RMD flipping logic that was causing sign issues.
  """
  @spec apply_rmd_flipping_check(Quaternion.t()) :: Quaternion.t()
  def apply_rmd_flipping_check({x, y, z, w}) do
    # Simply ensure canonical representation (w >= 0)
    # This is the standard way to resolve quaternion dual representation
    if w >= 0.0 do
      {x, y, z, w}
    else
      {-x, -y, -z, -w}
    end
  end

  @doc """
  Calculates translation vector from rotation and center points.
  """
  @spec calculate_translation(map(), Quaternion.t()) :: {:ok, Vector3.t()}
  def calculate_translation(qcp_state, rotation) do
    %{translate: translate, target_center: target_center, moved_center: moved_center} = qcp_state

    if translate do
      # Translation = target_center - rotation * moved_center
      rotated_moved_center = Quaternion.rotate_vector(rotation, moved_center)
      translation = Vector3.sub(target_center, rotated_moved_center)
      {:ok, translation}
    else
      {:ok, {0.0, 0.0, 0.0}}
    end
  end
end
