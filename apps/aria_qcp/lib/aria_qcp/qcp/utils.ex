# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQcp.QCP.Utils do
  @moduledoc """
  Utility functions for the QCP algorithm.

  Contains helper functions for quaternion operations and transformations.
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
