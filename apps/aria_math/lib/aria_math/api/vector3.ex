# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.API.Vector3 do
  @moduledoc """
  Vector3 operations for the AriaMath external API.

  This module contains all Vector3-related delegations and operations
  for the AriaMath external API, keeping the main API module focused.
  """

  alias AriaMath.Vector3

  @doc """
  Create a 3D vector from three components.

  ## Examples

      iex> AriaMath.API.Vector3.vector3(1.0, 2.0, 3.0)
      {1.0, 2.0, 3.0}
  """
  def vector3(x, y, z), do: Vector3.new(x, y, z)

  @doc """
  Add two 3D vectors component-wise.

  ## Examples

      iex> AriaMath.API.Vector3.add({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0})
      {5.0, 7.0, 9.0}
  """
  defdelegate add(v1, v2), to: Vector3

  @doc """
  Add two 3D vectors component-wise (alias for add/2).

  ## Examples

      iex> AriaMath.API.Vector3.add_vectors({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0})
      {5.0, 7.0, 9.0}
  """
  defdelegate add_vectors(v1, v2), to: Vector3, as: :add

  @doc """
  Subtract two 3D vectors component-wise.

  ## Examples

      iex> AriaMath.API.Vector3.subtract({4.0, 5.0, 6.0}, {1.0, 2.0, 3.0})
      {3.0, 3.0, 3.0}
  """
  defdelegate subtract(v1, v2), to: Vector3, as: :sub

  @doc """
  Subtract two 3D vectors component-wise (alias for subtract/2).

  ## Examples

      iex> AriaMath.API.Vector3.subtract_vectors({4.0, 5.0, 6.0}, {1.0, 2.0, 3.0})
      {3.0, 3.0, 3.0}
  """
  defdelegate subtract_vectors(v1, v2), to: Vector3, as: :sub

  @doc """
  Scale a 3D vector by a scalar value.

  ## Examples

      iex> AriaMath.API.Vector3.scale({1.0, 2.0, 3.0}, 2.0)
      {2.0, 4.0, 6.0}
  """
  defdelegate scale(vector, scalar), to: Vector3

  @doc """
  Scale a 3D vector by a scalar value (alias for scale/2).

  ## Examples

      iex> AriaMath.API.Vector3.scale_vector({1.0, 2.0, 3.0}, 2.0)
      {2.0, 4.0, 6.0}
  """
  defdelegate scale_vector(vector, scalar), to: Vector3, as: :scale

  @doc """
  Compute the dot product of two 3D vectors.

  ## Examples

      iex> AriaMath.API.Vector3.dot({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0})
      32.0
  """
  defdelegate dot(v1, v2), to: Vector3

  @doc """
  Compute the dot product of two 3D vectors (alias for dot/2).

  ## Examples

      iex> AriaMath.API.Vector3.dot_product({1.0, 2.0, 3.0}, {4.0, 5.0, 6.0})
      32.0
  """
  defdelegate dot_product(v1, v2), to: Vector3, as: :dot

  @doc """
  Compute the cross product of two 3D vectors.

  ## Examples

      iex> AriaMath.API.Vector3.cross({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0})
      {0.0, 0.0, 1.0}
  """
  defdelegate cross(v1, v2), to: Vector3

  @doc """
  Compute the cross product of two 3D vectors (alias for cross/2).

  ## Examples

      iex> AriaMath.API.Vector3.cross_product({1.0, 0.0, 0.0}, {0.0, 1.0, 0.0})
      {0.0, 0.0, 1.0}
  """
  defdelegate cross_product(v1, v2), to: Vector3, as: :cross

  @doc """
  Compute the length (magnitude) of a 3D vector.

  ## Examples

      iex> AriaMath.API.Vector3.length({3.0, 4.0, 0.0})
      5.0
  """
  defdelegate length(vector), to: Vector3

  @doc """
  Compute the length (magnitude) of a 3D vector (alias for length/1).

  ## Examples

      iex> AriaMath.API.Vector3.vector_length({3.0, 4.0, 0.0})
      5.0
  """
  defdelegate vector_length(vector), to: Vector3, as: :length

  @doc """
  Normalize a 3D vector to unit length.

  ## Examples

      iex> AriaMath.API.Vector3.normalize({3.0, 4.0, 0.0})
      {0.6, 0.8, 0.0}
  """
  def normalize(vector) do
    {normalized, _valid} = Vector3.normalize(vector)
    normalized
  end

  @doc """
  Normalize a 3D vector to unit length (alias for normalize/1).

  ## Examples

      iex> AriaMath.API.Vector3.normalize_vector({3.0, 4.0, 0.0})
      {{0.6, 0.8, 0.0}, true}
  """
  defdelegate normalize_vector(vector), to: Vector3, as: :normalize

  @doc """
  Compute distance between two 3D points.

  ## Examples

      iex> AriaMath.API.Vector3.distance({0.0, 0.0, 0.0}, {3.0, 4.0, 0.0})
      5.0
  """
  defdelegate distance(point1, point2), to: Vector3

  @doc """
  Linear interpolation between two 3D vectors.

  ## Examples

      iex> AriaMath.API.Vector3.lerp({0.0, 0.0, 0.0}, {1.0, 1.0, 1.0}, 0.5)
      {0.5, 0.5, 0.5}
  """
  defdelegate lerp(v1, v2, t), to: Vector3
end
