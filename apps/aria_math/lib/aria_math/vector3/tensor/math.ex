# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Vector3.Tensor.Math do
  @moduledoc """
  Mathematical operations for Vector3 tensors.

  This module provides mathematical operations like dot product, cross product,
  and normalization for individual vectors with numerical stability.
  """

  @type vector3_tensor :: Nx.Tensor.t()

  @doc """
  Vector normalization with validity checking using Nx operations.

  Implements `math/normalize` operation from KHR Interactivity spec.

  Returns {normalized_vector, is_valid} where:
  - normalized_vector: unit vector in same direction as input, or zero vector if invalid
  - is_valid: true if output has unit length, false otherwise

  ## Examples

      iex> vec = AriaMath.Vector3.Tensor.Core.new(3.0, 4.0, 0.0)
      iex> {norm_vec, valid} = AriaMath.Vector3.Tensor.Math.normalize(vec)
      iex> valid
      true
      iex> AriaMath.Vector3.Tensor.Core.to_tuple(norm_vec)
      {0.6, 0.8, 0.0}

      iex> zero_vec = AriaMath.Vector3.Tensor.Core.new(0.0, 0.0, 0.0)
      iex> {norm_vec, valid} = AriaMath.Vector3.Tensor.Math.normalize(zero_vec)
      iex> valid
      false
  """
  @spec normalize(vector3_tensor()) :: {vector3_tensor(), boolean()}
  def normalize(vec) do
    len = vec
          |> Nx.pow(2)
          |> Nx.sum()
          |> Nx.sqrt()

    len_scalar = Nx.to_number(len)

    cond do
      # If length is zero, NaN, or positive infinity, return zero vector and false
      len_scalar == 0.0 or not is_finite_float(len_scalar) ->
        {Nx.tensor([0.0, 0.0, 0.0], type: :f32), false}

      # If length is positive finite number, normalize and return true
      len_scalar > 0.0 ->
        normalized = Nx.divide(vec, len)
        {normalized, true}

      # Default case
      true ->
        {Nx.tensor([0.0, 0.0, 0.0], type: :f32), false}
    end
  end

  @doc """
  Component-wise dot product using Nx operations.

  Implements `math/dot` operation from KHR Interactivity spec.

  ## Examples

      iex> a = AriaMath.Vector3.Tensor.Core.new(1.0, 2.0, 3.0)
      iex> b = AriaMath.Vector3.Tensor.Core.new(4.0, 5.0, 6.0)
      iex> AriaMath.Vector3.Tensor.Math.dot(a, b)
      32.0

      iex> a = AriaMath.Vector3.Tensor.Core.new(1.0, 0.0, 0.0)
      iex> b = AriaMath.Vector3.Tensor.Core.new(0.0, 1.0, 0.0)
      iex> AriaMath.Vector3.Tensor.Math.dot(a, b)
      0.0
  """
  @spec dot(vector3_tensor(), vector3_tensor()) :: float()
  def dot(a, b) do
    a
    |> Nx.multiply(b)
    |> Nx.sum()
    |> Nx.to_number()
  end

  @doc """
  3D cross product using Nx operations.

  Implements `math/cross` operation from KHR Interactivity spec.

  ## Examples

      iex> a = AriaMath.Vector3.Tensor.Core.new(1.0, 0.0, 0.0)
      iex> b = AriaMath.Vector3.Tensor.Core.new(0.0, 1.0, 0.0)
      iex> result = AriaMath.Vector3.Tensor.Math.cross(a, b)
      iex> AriaMath.Vector3.Tensor.Core.to_tuple(result)
      {0.0, 0.0, 1.0}

      iex> a = AriaMath.Vector3.Tensor.Core.new(1.0, 2.0, 3.0)
      iex> b = AriaMath.Vector3.Tensor.Core.new(4.0, 5.0, 6.0)
      iex> result = AriaMath.Vector3.Tensor.Math.cross(a, b)
      iex> AriaMath.Vector3.Tensor.Core.to_tuple(result)
      {-3.0, 6.0, -3.0}
  """
  @spec cross(vector3_tensor(), vector3_tensor()) :: vector3_tensor()
  def cross(a, b) do
    ax = Nx.slice_along_axis(a, 0, 1, axis: 0)
    ay = Nx.slice_along_axis(a, 1, 1, axis: 0)
    az = Nx.slice_along_axis(a, 2, 1, axis: 0)

    bx = Nx.slice_along_axis(b, 0, 1, axis: 0)
    by = Nx.slice_along_axis(b, 1, 1, axis: 0)
    bz = Nx.slice_along_axis(b, 2, 1, axis: 0)

    cx = Nx.subtract(Nx.multiply(ay, bz), Nx.multiply(az, by))
    cy = Nx.subtract(Nx.multiply(az, bx), Nx.multiply(ax, bz))
    cz = Nx.subtract(Nx.multiply(ax, by), Nx.multiply(ay, bx))

    Nx.concatenate([cx, cy, cz], axis: 0)
  end

  @doc """
  Vector subtraction using Nx operations.

  Implements `math/subtract` operation from KHR Interactivity spec.

  ## Examples

      iex> a = AriaMath.Vector3.Tensor.Core.new(5.0, 7.0, 9.0)
      iex> b = AriaMath.Vector3.Tensor.Core.new(1.0, 2.0, 3.0)
      iex> result = AriaMath.Vector3.Tensor.Math.subtract(a, b)
      iex> AriaMath.Vector3.Tensor.Core.to_tuple(result)
      {4.0, 5.0, 6.0}

      iex> a = AriaMath.Vector3.Tensor.Core.new(0.0, 0.0, 0.0)
      iex> b = AriaMath.Vector3.Tensor.Core.new(1.0, 1.0, 1.0)
      iex> result = AriaMath.Vector3.Tensor.Math.subtract(a, b)
      iex> AriaMath.Vector3.Tensor.Core.to_tuple(result)
      {-1.0, -1.0, -1.0}
  """
  @spec subtract(vector3_tensor(), vector3_tensor()) :: vector3_tensor()
  def subtract(a, b) do
    Nx.subtract(a, b)
  end

  # Helper functions

  defp is_finite_float(x) when is_float(x) do
    not (x != x or x == :positive_infinity or x == :negative_infinity)
  end

  defp is_finite_float(_), do: false
end
