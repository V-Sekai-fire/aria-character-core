# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaQcp.QCP.Validation.Core do
  @moduledoc """
  Core validation functions for the QCP algorithm.

  Handles validation of point sets, weights, and numerical stability checks.
  """

  alias AriaMath.Vector3

  @max_points 10_000
  @min_weight 1.0e-12
  @max_weight 1.0e12

  @type point_set :: [Vector3.t()]
  @type weights :: [float()]
  @type validation_error ::
    :empty_point_sets |
    :mismatched_point_set_sizes |
    :mismatched_weight_count |
    :negative_weights |
    :too_many_points |
    :invalid_weights |
    :degenerate_points |
    :numerical_instability

  @doc """
  Validates all inputs for the QCP algorithm.
  """
  @spec validate_inputs(point_set(), point_set(), weights()) :: :ok | {:error, validation_error()}
  def validate_inputs(moved, target, weights) do
    with :ok <- validate_point_sets(moved, target),
         :ok <- validate_weights(weights, length(moved)),
         :ok <- validate_numerical_stability(moved, target) do
      :ok
    end
  end

  @doc """
  Validates point sets for basic requirements.
  """
  @spec validate_point_sets(point_set(), point_set()) :: :ok | {:error, validation_error()}
  def validate_point_sets(moved, target) do
    cond do
      length(moved) == 0 or length(target) == 0 ->
        {:error, :empty_point_sets}

      length(moved) != length(target) ->
        {:error, :mismatched_point_set_sizes}

      length(moved) > @max_points ->
        {:error, :too_many_points}

      not all_valid_vectors?(moved) or not all_valid_vectors?(target) ->
        {:error, :degenerate_points}

      true ->
        :ok
    end
  end

  @doc """
  Validates weight array for consistency and numerical stability.
  """
  @spec validate_weights(weights(), non_neg_integer()) :: :ok | {:error, validation_error()}
  def validate_weights(weights, point_count) do
    cond do
      length(weights) > 0 and length(weights) != point_count ->
        {:error, :mismatched_weight_count}

      Enum.any?(weights, fn w -> w < 0.0 end) ->
        {:error, :negative_weights}

      Enum.any?(weights, fn w -> not is_finite_number?(w) end) ->
        {:error, :invalid_weights}

      Enum.any?(weights, fn w -> w > @max_weight end) ->
        {:error, :invalid_weights}

      Enum.all?(weights, fn w -> w < @min_weight end) and length(weights) > 0 ->
        {:error, :invalid_weights}

      true ->
        :ok
    end
  end

  @doc """
  Validates numerical stability of point sets.
  """
  @spec validate_numerical_stability(point_set(), point_set()) :: :ok | {:error, validation_error()}
  def validate_numerical_stability(moved, target) do
    # Check for degenerate cases that could cause numerical instability
    moved_span = calculate_point_span(moved)
    target_span = calculate_point_span(target)

    cond do
      moved_span < 1.0e-12 and length(moved) > 1 ->
        {:error, :degenerate_points}

      target_span < 1.0e-12 and length(target) > 1 ->
        {:error, :degenerate_points}

      true ->
        :ok
    end
  end

  @doc """
  Checks if all vectors in a point set are valid (finite numbers).
  """
  @spec all_valid_vectors?(point_set()) :: boolean()
  def all_valid_vectors?(points) do
    Enum.all?(points, fn {x, y, z} ->
      is_finite_number?(x) and is_finite_number?(y) and is_finite_number?(z)
    end)
  end

  @doc """
  Checks if a number is finite (not NaN or infinity).
  """
  @spec is_finite_number?(number()) :: boolean()
  def is_finite_number?(x) when is_number(x) do
    not (x != x or x == :infinity or x == :neg_infinity)
  end
  def is_finite_number?(_), do: false

  @doc """
  Calculates the maximum span (range) of points in any dimension.
  """
  @spec calculate_point_span(point_set()) :: float()
  def calculate_point_span(points) when length(points) <= 1, do: 0.0
  def calculate_point_span(points) do
    {min_x, max_x} = points |> Enum.map(fn {x, _, _} -> x end) |> Enum.min_max()
    {min_y, max_y} = points |> Enum.map(fn {_, y, _} -> y end) |> Enum.min_max()
    {min_z, max_z} = points |> Enum.map(fn {_, _, z} -> z end) |> Enum.min_max()

    max(max_x - min_x, max(max_y - min_y, max_z - min_z))
  end
end
