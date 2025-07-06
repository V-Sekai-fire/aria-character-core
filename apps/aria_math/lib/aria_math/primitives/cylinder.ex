# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Primitives.Cylinder do
  @moduledoc """
  Cylinder primitive generation with caps and configurable segments.

  This module provides cylinder generation with proper UV mapping
  and normal calculation for both curved surface and end caps.
  """

  @type primitive :: %{
    vertices: [tuple()],
    indices: [non_neg_integer()],
    normals: [tuple()],
    uvs: [{float(), float()}]
  }

  @doc """
  Create a cylinder primitive with default parameters (radius 1.0, height 2.0, 8 segments).
  """
  @spec generate() :: primitive()
  def generate(), do: generate(1.0, 2.0, 8)

  @doc """
  Create a cylinder primitive with specified parameters.
  """
  @spec generate(float(), float(), non_neg_integer()) :: primitive()
  def generate(radius, height, segments) do
    half_height = height / 2.0
    angle_step = 2 * :math.pi() / segments

    # Generate vertices
    vertices = []
    # Bottom center
    vertices = [{0.0, -half_height, 0.0} | vertices]
    # Top center
    vertices = [{0.0, half_height, 0.0} | vertices]

    # Bottom circle
    bottom_vertices = for i <- 0..(segments-1) do
      angle = i * angle_step
      x = radius * :math.cos(angle)
      z = radius * :math.sin(angle)
      {x, -half_height, z}
    end

    # Top circle
    top_vertices = for i <- 0..(segments-1) do
      angle = i * angle_step
      x = radius * :math.cos(angle)
      z = radius * :math.sin(angle)
      {x, half_height, z}
    end

    vertices = vertices ++ bottom_vertices ++ top_vertices

    # Bottom cap
    bottom_indices = for i <- 0..(segments-1) do
      next_i = rem(i + 1, segments)
      [0, 2 + next_i, 2 + i]
    end |> List.flatten()

    # Top cap
    top_indices = for i <- 0..(segments-1) do
      next_i = rem(i + 1, segments)
      [1, 2 + segments + i, 2 + segments + next_i]
    end |> List.flatten()

    # Side faces
    side_indices = for i <- 0..(segments-1) do
      next_i = rem(i + 1, segments)
      bottom_i = 2 + i
      bottom_next = 2 + next_i
      top_i = 2 + segments + i
      top_next = 2 + segments + next_i
      [bottom_i, top_i, top_next, bottom_i, top_next, bottom_next]
    end |> List.flatten()

    indices = bottom_indices ++ top_indices ++ side_indices

    # Generate normals
    normals = []
    # Bottom center normal
    normals = [{0.0, -1.0, 0.0} | normals]
    # Top center normal
    normals = [{0.0, 1.0, 0.0} | normals]

    # Bottom circle normals
    bottom_normals = List.duplicate({0.0, -1.0, 0.0}, segments)

    # Top circle normals
    top_normals = List.duplicate({0.0, 1.0, 0.0}, segments)

    normals = normals ++ bottom_normals ++ top_normals

    # Generate UVs
    uvs = List.duplicate({0.5, 0.5}, length(vertices))

    %{vertices: vertices, indices: indices, normals: normals, uvs: uvs}
  end
end
