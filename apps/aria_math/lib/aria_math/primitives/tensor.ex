# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Primitives.Tensor do
  @moduledoc """
  Nx tensor-based geometric primitive generation.

  This module provides the same API as Primitives core module but uses Nx tensors
  for optimized numerical computing and batch operations on vertex data.

  Primitives are represented as maps with Nx tensors:
  - vertices: Nx.tensor with shape [num_vertices, 3]
  - normals: Nx.tensor with shape [num_vertices, 3]
  - indices: Nx.tensor with shape [num_triangles * 3] (u32)
  - uvs: Nx.tensor with shape [num_vertices, 2]

  This module delegates to specialized sub-modules:
  - `Core` - Conversion and utility functions
  - `Shapes` - Basic shape generation (box, sphere, plane)
  - `Operations` - Transformation and manipulation operations
  """

  alias AriaMath.Primitives.Tensor.{Core, Shapes, Operations}

  @type primitive_tensor :: Core.primitive_tensor()

  # Conversion functions - delegate to Core module
  defdelegate from_tuple_primitive(primitive), to: Core
  defdelegate to_tuple_primitive(tensor_primitive), to: Core
  defdelegate bounding_box_nx(primitive), to: Core

  # Shape generation functions - delegate to Shapes module
  defdelegate box_nx(), to: Shapes
  defdelegate box_nx(size), to: Shapes
  defdelegate sphere_nx(), to: Shapes
  defdelegate sphere_nx(radius), to: Shapes
  defdelegate sphere_nx(radius, subdivisions), to: Shapes
  defdelegate plane_nx(), to: Shapes
  defdelegate plane_nx(size), to: Shapes

  # Operation functions - delegate to Operations module
  defdelegate transform_nx(primitive, matrix), to: Operations
  defdelegate merge_nx(prim1, prim2), to: Operations
  defdelegate scale_nx(primitive, factor), to: Operations
  defdelegate translate_nx(primitive, offset), to: Operations

end
