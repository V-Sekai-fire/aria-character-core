# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Vector3.Tensor.Core do
  @moduledoc """
  Core Vector3 tensor operations for basic vector creation and conversion.

  This module provides fundamental vector operations including creation,
  conversion between formats, and basic properties like length and magnitude.
  """

  @type vector3_tensor :: Nx.Tensor.t()
  @type vector3_tuple :: {float(), float(), float()}

  @doc """
  Creates a new Vector3 tensor from three float components.

  ## Examples

      iex> AriaMath.Vector3.Tensor.Core.new(1.0, 2.0, 3.0)
      #Nx.Tensor<
        f32[3]
        [1.0, 2.0, 3.0]
      >
  """
  @spec new(float(), float(), float()) :: vector3_tensor()
  def new(x, y, z) when is_number(x) and is_number(y) and is_number(z) do
    Nx.tensor([x / 1, y / 1, z / 1], type: :f32)
  end

  @doc """
  Convert a Vector3 tuple to tensor format.

  ## Examples

      iex> AriaMath.Vector3.Tensor.Core.from_tuple({1.0, 2.0, 3.0})
      #Nx.Tensor<
        f32[3]
        [1.0, 2.0, 3.0]
      >
  """
  @spec from_tuple(vector3_tuple()) :: vector3_tensor()
  def from_tuple({x, y, z}) when is_number(x) and is_number(y) and is_number(z) do
    Nx.tensor([x / 1, y / 1, z / 1], type: :f32)
  end

  @doc """
  Convert a Vector3 tensor to tuple format.

  ## Examples

      iex> vec = AriaMath.Vector3.Tensor.Core.new(1.0, 2.0, 3.0)
      iex> AriaMath.Vector3.Tensor.Core.to_tuple(vec)
      {1.0, 2.0, 3.0}
  """
  @spec to_tuple(vector3_tensor()) :: vector3_tuple()
  def to_tuple(vec) when is_struct(vec, Nx.Tensor) do
    [x, y, z] = Nx.to_list(vec)
    {x, y, z}
  end

  @doc """
  Vector length using Nx operations for numerical stability.

  Implements `math/length` operation from KHR Interactivity spec.

  ## Examples

      iex> vec = AriaMath.Vector3.Tensor.Core.new(3.0, 4.0, 0.0)
      iex> AriaMath.Vector3.Tensor.Core.length(vec)
      5.0

      iex> vec = AriaMath.Vector3.Tensor.Core.new(1.0, 1.0, 1.0)
      iex> AriaMath.Vector3.Tensor.Core.length(vec)
      1.7320508075688772
  """
  @spec length(vector3_tensor()) :: float()
  def length(vec) do
    vec
    |> Nx.pow(2)
    |> Nx.sum()
    |> Nx.sqrt()
    |> Nx.to_number()
  end

  @doc """
  Single vector magnitude calculation.

  ## Examples

      iex> vector = AriaMath.Vector3.Tensor.Core.new(3.0, 4.0, 0.0)
      iex> AriaMath.Vector3.Tensor.Core.magnitude(vector)
      5.0
  """
  @spec magnitude(vector3_tensor()) :: float()
  def magnitude(vector) do
    vector
    |> Nx.pow(2)
    |> Nx.sum()
    |> Nx.sqrt()
    |> Nx.to_number()
  end
end
