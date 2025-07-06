# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Primitives.Core do
  @moduledoc """
  Core geometric primitive generation for basic 3D shapes.

  This module provides functions to generate simple 3D geometric primitives
  like boxes, planes, and triangles with vertex data, indices, normals, and UV coordinates.
  """

  alias AriaMath.Vector3

  @type primitive :: %{
    vertices: [Vector3.t()],
    indices: [non_neg_integer()],
    normals: [Vector3.t()],
    uvs: [{float(), float()}]
  }

  @doc """
  Create a box primitive with default size (1, 1, 1).
  """
  @spec box() :: primitive()
  def box(), do: box({1.0, 1.0, 1.0})

  @doc """
  Create a box primitive with specified size.
  """
  @spec box({float(), float(), float()}) :: primitive()
  def box({width, height, depth}) do
    half_w = width / 2.0
    half_h = height / 2.0
    half_d = depth / 2.0

    vertices = [
      # Front face
      {-half_w, -half_h, half_d},   # 0
      {half_w, -half_h, half_d},    # 1
      {half_w, half_h, half_d},     # 2
      {-half_w, half_h, half_d},    # 3
      # Back face
      {-half_w, -half_h, -half_d},  # 4
      {half_w, -half_h, -half_d},   # 5
      {half_w, half_h, -half_d},    # 6
      {-half_w, half_h, -half_d}    # 7
    ]

    indices = [
      # Front face
      0, 1, 2, 0, 2, 3,
      # Back face
      4, 6, 5, 4, 7, 6,
      # Left face
      4, 0, 3, 4, 3, 7,
      # Right face
      1, 5, 6, 1, 6, 2,
      # Top face
      3, 2, 6, 3, 6, 7,
      # Bottom face
      4, 5, 1, 4, 1, 0
    ]

    normals = [
      # Front
      {0.0, 0.0, 1.0}, {0.0, 0.0, 1.0}, {0.0, 0.0, 1.0}, {0.0, 0.0, 1.0},
      # Back
      {0.0, 0.0, -1.0}, {0.0, 0.0, -1.0}, {0.0, 0.0, -1.0}, {0.0, 0.0, -1.0}
    ]

    uvs = [
      {0.0, 0.0}, {1.0, 0.0}, {1.0, 1.0}, {0.0, 1.0},
      {1.0, 0.0}, {0.0, 0.0}, {0.0, 1.0}, {1.0, 1.0}
    ]

    %{vertices: vertices, indices: indices, normals: normals, uvs: uvs}
  end

  @doc """
  Create a plane primitive with default size (1.0, 1.0).
  """
  @spec plane() :: primitive()
  def plane(), do: plane({1.0, 1.0})

  @doc """
  Create a plane primitive with specified size lying on XZ plane.
  """
  @spec plane({float(), float()}) :: primitive()
  def plane({width, depth}) do
    half_w = width / 2.0
    half_d = depth / 2.0

    vertices = [
      {-half_w, 0.0, -half_d},  # 0
      {half_w, 0.0, -half_d},   # 1
      {half_w, 0.0, half_d},    # 2
      {-half_w, 0.0, half_d}    # 3
    ]

    indices = [0, 1, 2, 0, 2, 3]

    normals = List.duplicate({0.0, 1.0, 0.0}, 4)

    uvs = [{0.0, 0.0}, {1.0, 0.0}, {1.0, 1.0}, {0.0, 1.0}]

    %{vertices: vertices, indices: indices, normals: normals, uvs: uvs}
  end

  @doc """
  Create a triangle primitive with default vertices.
  """
  @spec triangle() :: primitive()
  def triangle() do
    triangle([{0.0, 0.0, 0.0}, {1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}])
  end

  @doc """
  Create a triangle primitive with specified vertices.
  """
  @spec triangle([Vector3.t()]) :: primitive()
  def triangle(vertices) when length(vertices) == 3 do
    [v1, v2, v3] = vertices

    # Calculate normal using cross product
    edge1 = Vector3.sub(v2, v1)
    edge2 = Vector3.sub(v3, v1)
    {normal, _} = Vector3.normalize(Vector3.cross(edge1, edge2))

    indices = [0, 1, 2]
    normals = [normal, normal, normal]
    uvs = [{0.0, 0.0}, {1.0, 0.0}, {0.5, 1.0}]

    %{vertices: vertices, indices: indices, normals: normals, uvs: uvs}
  end
end
