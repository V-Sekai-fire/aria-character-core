# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQcp.Core do
  @moduledoc """
  Core implementation of the QCP algorithm.

  This module orchestrates the QCP algorithm by delegating to specialized modules
  for validation, state management, eigenvalue calculation, rotation, and translation.
  """

  alias AriaMath.{Vector3, Quaternion}
  alias AriaQcp.{Validation, State, Eigenvalue, Rotation, Translation}

  @default_precision 1.0e-6

  @type point_set :: [Vector3.t()]
  @type weights :: [float()]
  @type qcp_result :: {:ok, {Quaternion.t(), Vector3.t()}} | {:error, term()}

  @doc """
  Calculate optimal rotation and translation to align two point sets using QCP algorithm.
  """
  @spec weighted_superpose(point_set(), point_set(), weights(), boolean(), float()) :: qcp_result()
  def weighted_superpose(moved, target, weights \\ [], translate \\ true, precision \\ @default_precision) do
    with :ok <- Validation.validate_inputs(moved, target, weights),
         {:ok, qcp_state} <- State.initialize_qcp_state(moved, target, weights, translate, precision),
         {:ok, qcp_state} <- State.calculate_inner_product(qcp_state),
         {:ok, rotation} <- Rotation.calculate_rotation(qcp_state),
         {:ok, translation} <- Translation.calculate_translation(qcp_state, rotation) do
      {:ok, {rotation, translation}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Calculate optimal rotation and translation between two point sets.
  """
  @spec calculate(point_set(), point_set()) :: {:ok, {Quaternion.t(), Vector3.t(), float()}} | {:error, term()}
  def calculate(moved, target) do
    case weighted_superpose(moved, target, [], true) do
      {:ok, {rotation, translation}} ->
        # Calculate RMSD using the transformed points for proper alignment assessment
        transformed_moved = apply_transformation(moved, rotation, translation)
        rmsd_value = case rmsd(transformed_moved, target) do
          {:ok, value} -> value
          {:error, _} -> 0.0
        end
        {:ok, {rotation, translation, rmsd_value}}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Apply rotation and translation transformation to a list of points.
  """
  @spec apply_transformation(point_set(), Quaternion.t(), Vector3.t()) :: point_set()
  def apply_transformation(points, rotation, translation) do
    Enum.map(points, fn point ->
      rotated_point = Quaternion.rotate_vector(rotation, point)
      Vector3.add(rotated_point, translation)
    end)
  end

  @doc """
  Calculate the Root Mean Square Deviation (RMSD) between two point sets.
  """
  @spec rmsd(point_set(), point_set()) :: {:ok, float()} | {:error, term()}
  def rmsd(points_a, points_b) do
    cond do
      length(points_a) != length(points_b) ->
        {:error, :mismatched_point_count}

      length(points_a) == 0 ->
        {:error, :empty_point_sets}

      true ->
        sum_squared_distances = points_a
        |> Enum.zip(points_b)
        |> Enum.reduce(0.0, fn {p1, p2}, acc ->
          diff = Vector3.sub(p1, p2)
          squared_distance = Vector3.dot(diff, diff)
          acc + squared_distance
        end)

        mean_squared_distance = sum_squared_distances / length(points_a)
        rmsd_value = :math.sqrt(mean_squared_distance)
        {:ok, rmsd_value}
    end
  end
end
