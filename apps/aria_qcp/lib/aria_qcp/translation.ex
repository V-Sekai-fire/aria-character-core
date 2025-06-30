# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQcp.Translation do
  @moduledoc """
  Translation calculation for QCP algorithm.

  This module handles the calculation of optimal translation vectors
  to align point sets after rotation has been applied.
  """

  alias AriaMath.{Vector3, Quaternion}
  alias AriaQcp.State

  @type qcp_state :: State.qcp_state()

  @doc """
  Calculate the optimal translation vector for point alignment.
  """
  @spec calculate_translation(qcp_state(), Quaternion.t()) :: {:ok, Vector3.t()} | {:error, term()}
  def calculate_translation(qcp_state, rotation_quaternion) do
    %{translate: translate, moved_center: moved_center, target_center: target_center} = qcp_state

    if translate do
      # Apply rotation to the moved center point
      rotated_moved_center = Quaternion.rotate_vector(rotation_quaternion, moved_center)

      # Translation is the difference between target center and rotated moved center
      translation = Vector3.sub(target_center, rotated_moved_center)

      {:ok, translation}
    else
      # No translation requested
      {:ok, {0.0, 0.0, 0.0}}
    end
  end

  @doc """
  Calculate translation without rotation (for identity rotation cases).
  """
  @spec calculate_simple_translation(qcp_state()) :: {:ok, Vector3.t()} | {:error, term()}
  def calculate_simple_translation(qcp_state) do
    %{translate: translate, moved_center: moved_center, target_center: target_center} = qcp_state

    if translate do
      translation = Vector3.sub(target_center, moved_center)
      {:ok, translation}
    else
      {:ok, {0.0, 0.0, 0.0}}
    end
  end

  @doc """
  Calculate weighted translation for point sets with custom weights.
  """
  @spec calculate_weighted_translation(qcp_state(), Quaternion.t()) :: {:ok, Vector3.t()} | {:error, term()}
  def calculate_weighted_translation(qcp_state, rotation_quaternion) do
    %{
      moved: moved, target: target, weights: weights,
      translate: translate, w_sum: w_sum
    } = qcp_state

    if translate and w_sum > 1.0e-12 do
      # Calculate weighted centers after rotation
      rotated_moved = Enum.map(moved, fn point ->
        Quaternion.rotate_vector(rotation_quaternion, point)
      end)

      weighted_rotated_center = calculate_weighted_center(rotated_moved, weights, w_sum)
      weighted_target_center = calculate_weighted_center(target, weights, w_sum)

      translation = Vector3.sub(weighted_target_center, weighted_rotated_center)
      {:ok, translation}
    else
      {:ok, {0.0, 0.0, 0.0}}
    end
  end

  # Private helper functions

  @spec calculate_weighted_center([Vector3.t()], [float()], float()) :: Vector3.t()
  defp calculate_weighted_center(points, weights, total_weight) do
    weighted_sum = points
                   |> Enum.zip(weights)
                   |> Enum.reduce({0.0, 0.0, 0.0}, fn {point, weight}, acc ->
                     scaled_point = Vector3.scale(point, weight)
                     Vector3.add(acc, scaled_point)
                   end)

    Vector3.scale(weighted_sum, 1.0 / total_weight)
  end
end
