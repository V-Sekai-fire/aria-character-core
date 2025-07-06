# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Primitives.Tensor.Core do
  @moduledoc """
  Core tensor primitive conversion and utility functions.

  This module handles conversion between tuple-based and tensor-based primitive formats,
  providing the foundation for tensor-based geometric operations.
  """

  @type primitive_tensor :: %{
    vertices: Nx.Tensor.t(),
    indices: Nx.Tensor.t(),
    normals: Nx.Tensor.t(),
    uvs: Nx.Tensor.t()
  }

  @doc """
  Convert a tuple-based primitive to tensor format.

  ## Examples

      iex> tuple_prim = AriaMath.Primitives.box()
      iex> tensor_prim = AriaMath.Primitives.Tensor.Core.from_tuple_primitive(tuple_prim)
      iex> Nx.shape(tensor_prim.vertices)
      {8, 3}
  """
  @spec from_tuple_primitive(AriaMath.Primitives.primitive()) :: primitive_tensor()
  def from_tuple_primitive(primitive) do
    vertices_tensor = primitive.vertices
                      |> Enum.map(&Tuple.to_list/1)
                      |> Nx.tensor(type: :f32)

    normals_tensor = primitive.normals
                     |> Enum.map(&Tuple.to_list/1)
                     |> Nx.tensor(type: :f32)

    indices_tensor = Nx.tensor(primitive.indices, type: :u32)

    uvs_tensor = primitive.uvs
                 |> Enum.map(&Tuple.to_list/1)
                 |> Nx.tensor(type: :f32)

    %{
      vertices: vertices_tensor,
      indices: indices_tensor,
      normals: normals_tensor,
      uvs: uvs_tensor
    }
  end

  @doc """
  Convert a tensor-based primitive back to tuple format.

  ## Examples

      iex> tensor_prim = AriaMath.Primitives.Tensor.Shapes.box_nx()
      iex> tuple_prim = AriaMath.Primitives.Tensor.Core.to_tuple_primitive(tensor_prim)
      iex> length(tuple_prim.vertices)
      8
  """
  @spec to_tuple_primitive(primitive_tensor()) :: AriaMath.Primitives.primitive()
  def to_tuple_primitive(tensor_primitive) do
    vertices = tensor_primitive.vertices
               |> Nx.to_list()
               |> Enum.map(&List.to_tuple/1)

    normals = tensor_primitive.normals
              |> Nx.to_list()
              |> Enum.map(&List.to_tuple/1)

    indices = Nx.to_list(tensor_primitive.indices)

    uvs = tensor_primitive.uvs
          |> Nx.to_list()
          |> Enum.map(&List.to_tuple/1)

    %{
      vertices: vertices,
      indices: indices,
      normals: normals,
      uvs: uvs
    }
  end

  @doc """
  Calculate bounding box of a primitive using Nx reduction operations.

  ## Examples

      iex> prim = AriaMath.Primitives.Tensor.Shapes.box_nx()
      iex> {min_coords, max_coords} = AriaMath.Primitives.Tensor.Core.bounding_box_nx(prim)
      iex> Nx.shape(min_coords)
      {3}
  """
  @spec bounding_box_nx(primitive_tensor()) :: {Nx.Tensor.t(), Nx.Tensor.t()}
  def bounding_box_nx(primitive) do
    min_coords = Nx.reduce_min(primitive.vertices, axes: [0])
    max_coords = Nx.reduce_max(primitive.vertices, axes: [0])
    {min_coords, max_coords}
  end
end
