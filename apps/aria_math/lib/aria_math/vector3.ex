# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Vector3 do
  @moduledoc """
  Vector3 mathematical operations implementing glTF KHR Interactivity `float3` operations.

  All operations follow IEEE-754 standard for NaN, infinity, and special case handling
  as defined in the glTF KHR Interactivity specification.

  Vector3 supports both tuple-based operations {x, y, z} and Nx tensor operations
  for optimized numerical computing and potential GPU acceleration.
  """

  import Kernel, except: [length: 1]
  @type t :: {float(), float(), float()}

  # Core operations
  defdelegate new(x, y, z), to: AriaMath.Vector3.Core
  defdelegate length(vec), to: AriaMath.Vector3.Core
  defdelegate normalize(vec), to: AriaMath.Vector3.Core
  defdelegate dot(vec1, vec2), to: AriaMath.Vector3.Core
  defdelegate cross(vec1, vec2), to: AriaMath.Vector3.Core

  # Arithmetic operations
  defdelegate add(vec1, vec2), to: AriaMath.Vector3.Arithmetic
  defdelegate sub(vec1, vec2), to: AriaMath.Vector3.Arithmetic
  defdelegate mul(vec1, vec2), to: AriaMath.Vector3.Arithmetic
  defdelegate scale(vec, scalar), to: AriaMath.Vector3.Arithmetic
  defdelegate mul_scalar(vec, scalar), to: AriaMath.Vector3.Arithmetic
  defdelegate mix(vec1, vec2, t), to: AriaMath.Vector3.Arithmetic
  defdelegate lerp(vec1, vec2, t), to: AriaMath.Vector3.Arithmetic
  defdelegate min(vec1, vec2), to: AriaMath.Vector3.Arithmetic
  defdelegate max(vec1, vec2), to: AriaMath.Vector3.Arithmetic
  defdelegate component_abs(vec), to: AriaMath.Vector3.Arithmetic

  # Utility functions
  defdelegate approx_equal?(vec1, vec2, tolerance \\ 1.0e-6), to: AriaMath.Vector3.Utilities
  defdelegate equal?(vec1, vec2, tolerance \\ 1.0e-6), to: AriaMath.Vector3.Utilities
  defdelegate distance(point1, point2), to: AriaMath.Vector3.Utilities
  defdelegate zero(), to: AriaMath.Vector3.Utilities
  defdelegate unit_x(), to: AriaMath.Vector3.Utilities
  defdelegate unit_y(), to: AriaMath.Vector3.Utilities
  defdelegate unit_z(), to: AriaMath.Vector3.Utilities

  @doc """
  Divide a vector by a scalar.

  ## Examples

      iex> AriaMath.Vector3.div_scalar({6.0, 8.0, 10.0}, 2.0)
      {3.0, 4.0, 5.0}

      iex> AriaMath.Vector3.div_scalar({1.0, 2.0, 3.0}, 0.0)
      {:positive_infinity, :positive_infinity, :positive_infinity}
  """
  @spec div_scalar(t(), float()) :: t()
  def div_scalar({x, y, z}, scalar) when is_number(scalar) do
    case scalar do
      +0.0 -> {:positive_infinity, :positive_infinity, :positive_infinity}
      -0.0 -> {:negative_infinity, :negative_infinity, :negative_infinity}
      _ -> {x / scalar, y / scalar, z / scalar}
    end
  end

  # Nx tensor-based operations
  alias AriaMath.Vector3.Tensor

  @doc """
  Creates a new Vector3 tensor from three float components.
  """
  defdelegate new_nx(x, y, z), to: Tensor, as: :new

  @doc """
  Creates a Vector3 tensor from a tuple.
  """
  defdelegate from_tuple(tuple), to: Tensor

  @doc """
  Converts a Vector3 tensor to a tuple.
  """
  defdelegate to_tuple(tensor), to: Tensor

  @doc """
  Vector length using Nx operations.
  """
  defdelegate length_nx(tensor), to: Tensor, as: :length

  @doc """
  Batch vector length calculation for multiple vectors.
  """
  defdelegate length_batch(tensors), to: Tensor

  @doc """
  Vector normalization using Nx operations.
  """
  defdelegate normalize_nx(tensor), to: Tensor, as: :normalize

  @doc """
  Batch vector normalization for multiple vectors.
  """
  defdelegate normalize_batch(tensors), to: Tensor

  @doc """
  Dot product using Nx operations.
  """
  defdelegate dot_nx(a, b), to: Tensor, as: :dot

  @doc """
  Batch dot product for multiple vector pairs.
  """
  defdelegate dot_batch(a_tensors, b_tensors), to: Tensor

  @doc """
  Cross product using Nx operations.
  """
  defdelegate cross_nx(a, b), to: Tensor, as: :cross

  @doc """
  Batch cross product for multiple vector pairs.
  """
  defdelegate cross_batch(a_tensors, b_tensors), to: Tensor

  @doc """
  Batch vector scaling for multiple vectors.
  """
  defdelegate scale_batch(tensors, scalar), to: Tensor
end
