# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Primitives do
  @moduledoc """
  Geometric primitive generation for basic 3D shapes.

  This module provides functions to generate common 3D geometric primitives
  like boxes, spheres, cylinders, planes, and triangles with vertex data,
  indices, normals, and UV coordinates.

  The implementation is split across focused modules:
  - `AriaMath.Primitives.Core` - Basic shapes (box, plane, triangle)
  - `AriaMath.Primitives.Sphere` - Sphere generation with icosphere subdivision
  - `AriaMath.Primitives.Cylinder` - Cylinder generation with configurable segments
  - `AriaMath.Primitives.Operations` - Transform, merge, and geometric operations
  - `AriaMath.Primitives.MathUtils` - Mathematical utility functions
  - `AriaMath.Primitives.Tensor` - Nx tensor-based operations for performance
  """

  alias AriaMath.{Matrix4}

  @type primitive :: %{
    vertices: [tuple()],
    indices: [non_neg_integer()],
    normals: [tuple()],
    uvs: [{float(), float()}]
  }

  # Core primitive generation functions

  @doc """
  Create a box primitive with default size (1, 1, 1).
  """
  @spec box() :: primitive()
  defdelegate box(), to: AriaMath.Primitives.Core

  @doc """
  Create a box primitive with specified size.
  """
  @spec box({float(), float(), float()}) :: primitive()
  defdelegate box(size), to: AriaMath.Primitives.Core

  @doc """
  Create a plane primitive with default size (1.0, 1.0).
  """
  @spec plane() :: primitive()
  defdelegate plane(), to: AriaMath.Primitives.Core

  @doc """
  Create a plane primitive with specified size lying on XZ plane.
  """
  @spec plane({float(), float()}) :: primitive()
  defdelegate plane(size), to: AriaMath.Primitives.Core

  @doc """
  Create a triangle primitive with default vertices.
  """
  @spec triangle() :: primitive()
  defdelegate triangle(), to: AriaMath.Primitives.Core

  @doc """
  Create a triangle primitive with specified vertices.
  """
  @spec triangle([tuple()]) :: primitive()
  defdelegate triangle(vertices), to: AriaMath.Primitives.Core

  # Complex primitive generation functions

  @doc """
  Create a sphere primitive with default radius 1.0 and 2 subdivisions.
  """
  @spec sphere() :: primitive()
  def sphere(), do: AriaMath.Primitives.Sphere.generate()

  @doc """
  Create a sphere primitive with specified radius and default 2 subdivisions.
  """
  @spec sphere(float()) :: primitive()
  def sphere(radius), do: AriaMath.Primitives.Sphere.generate(radius)

  @doc """
  Create a sphere primitive with specified radius and subdivisions.
  Uses icosphere generation for better topology.
  """
  @spec sphere(float(), non_neg_integer()) :: primitive()
  def sphere(radius, subdivisions), do: AriaMath.Primitives.Sphere.generate(radius, subdivisions)

  @doc """
  Create a cylinder primitive with default parameters (radius 1.0, height 2.0, 8 segments).
  """
  @spec cylinder() :: primitive()
  def cylinder(), do: AriaMath.Primitives.Cylinder.generate()

  @doc """
  Create a cylinder primitive with specified parameters.
  """
  @spec cylinder(float(), float(), non_neg_integer()) :: primitive()
  def cylinder(radius, height, segments), do: AriaMath.Primitives.Cylinder.generate(radius, height, segments)

  # Primitive operations

  @doc """
  Apply a transformation matrix to a primitive.
  """
  @spec transform(primitive(), Matrix4.t()) :: primitive()
  defdelegate transform(primitive, matrix), to: AriaMath.Primitives.Operations

  @doc """
  Merge two primitives into a single primitive.
  """
  @spec merge(primitive(), primitive()) :: primitive()
  defdelegate merge(prim1, prim2), to: AriaMath.Primitives.Operations

  # Mathematical utility functions

  @doc """
  Check if two floating-point numbers are approximately equal within default tolerance.
  """
  @spec approximately_equal(float(), float()) :: boolean()
  defdelegate approximately_equal(a, b), to: AriaMath.Primitives.MathUtils

  @doc """
  Check if two floating-point numbers are approximately equal within specified tolerance.
  """
  @spec approximately_equal(float(), float(), float()) :: boolean()
  defdelegate approximately_equal(a, b, tolerance), to: AriaMath.Primitives.MathUtils

  @doc """
  Clamp a value between minimum and maximum bounds.
  """
  @spec clamp(number(), number(), number()) :: number()
  defdelegate clamp(value, min_val, max_val), to: AriaMath.Primitives.MathUtils

  @doc """
  Linear interpolation between two values.
  """
  @spec lerp(float(), float(), float()) :: float()
  defdelegate lerp(a, b, t), to: AriaMath.Primitives.MathUtils

  @doc """
  Convert degrees to radians.
  """
  @spec deg_to_rad(float()) :: float()
  defdelegate deg_to_rad(degrees), to: AriaMath.Primitives.MathUtils

  @doc """
  Convert radians to degrees.
  """
  @spec rad_to_deg(float()) :: float()
  defdelegate rad_to_deg(radians), to: AriaMath.Primitives.MathUtils

  @doc """
  IEEE-754 positive infinity constant.
  """
  @spec inf() :: float()
  defdelegate inf(), to: AriaMath.Primitives.MathUtils

  @doc """
  Check if a float value is infinite (positive or negative).
  """
  @spec isinf_float(float() | atom()) :: boolean()
  defdelegate isinf_float(value), to: AriaMath.Primitives.MathUtils

  # Nx tensor integration functions

  @doc """
  Create a box primitive using Nx tensors with default size (1, 1, 1).

  ## Examples

      iex> box = AriaMath.Primitives.box_nx()
      iex> Nx.shape(box.vertices)
      {8, 3}
  """
  @spec box_nx() :: AriaMath.Primitives.Tensor.primitive_tensor()
  defdelegate box_nx(), to: AriaMath.Primitives.Tensor

  @doc """
  Create a box primitive using Nx tensors with specified size.

  ## Examples

      iex> box = AriaMath.Primitives.box_nx({2.0, 2.0, 2.0})
      iex> Nx.shape(box.vertices)
      {8, 3}
  """
  @spec box_nx({float(), float(), float()}) :: AriaMath.Primitives.Tensor.primitive_tensor()
  defdelegate box_nx(size), to: AriaMath.Primitives.Tensor

  @doc """
  Create a sphere primitive using Nx tensors with default radius 1.0 and 2 subdivisions.

  ## Examples

      iex> sphere = AriaMath.Primitives.sphere_nx()
      iex> {num_vertices, 3} = Nx.shape(sphere.vertices)
      iex> num_vertices > 12
      true
  """
  @spec sphere_nx() :: AriaMath.Primitives.Tensor.primitive_tensor()
  defdelegate sphere_nx(), to: AriaMath.Primitives.Tensor

  @doc """
  Create a sphere primitive using Nx tensors with specified radius and default 2 subdivisions.

  ## Examples

      iex> sphere = AriaMath.Primitives.sphere_nx(2.0)
      iex> {num_vertices, 3} = Nx.shape(sphere.vertices)
      iex> num_vertices > 12
      true
  """
  @spec sphere_nx(float()) :: AriaMath.Primitives.Tensor.primitive_tensor()
  defdelegate sphere_nx(radius), to: AriaMath.Primitives.Tensor

  @doc """
  Create a sphere primitive using Nx tensors with specified radius and subdivisions.

  ## Examples

      iex> sphere = AriaMath.Primitives.sphere_nx(1.0, 1)
      iex> Nx.shape(sphere.vertices)
      {42, 3}
  """
  @spec sphere_nx(float(), non_neg_integer()) :: AriaMath.Primitives.Tensor.primitive_tensor()
  defdelegate sphere_nx(radius, subdivisions), to: AriaMath.Primitives.Tensor

  @doc """
  Create a plane primitive using Nx tensors with default size (1.0, 1.0).

  ## Examples

      iex> plane = AriaMath.Primitives.plane_nx()
      iex> Nx.shape(plane.vertices)
      {4, 3}
  """
  @spec plane_nx() :: AriaMath.Primitives.Tensor.primitive_tensor()
  defdelegate plane_nx(), to: AriaMath.Primitives.Tensor

  @doc """
  Create a plane primitive using Nx tensors with specified size lying on XZ plane.

  ## Examples

      iex> plane = AriaMath.Primitives.plane_nx({2.0, 3.0})
      iex> Nx.shape(plane.vertices)
      {4, 3}
  """
  @spec plane_nx({float(), float()}) :: AriaMath.Primitives.Tensor.primitive_tensor()
  defdelegate plane_nx(size), to: AriaMath.Primitives.Tensor

  @doc """
  Apply a transformation matrix to a primitive using batch operations.

  ## Examples

      iex> prim = AriaMath.Primitives.box_nx()
      iex> transform = AriaMath.Matrix4.Tensor.translation_nx({1.0, 2.0, 3.0})
      iex> transformed = AriaMath.Primitives.transform_nx(prim, transform)
      iex> Nx.shape(transformed.vertices)
      {8, 3}
  """
  @spec transform_nx(AriaMath.Primitives.Tensor.primitive_tensor(), Nx.Tensor.t()) :: AriaMath.Primitives.Tensor.primitive_tensor()
  defdelegate transform_nx(primitive, matrix), to: AriaMath.Primitives.Tensor

  @doc """
  Merge two tensor primitives into a single primitive using efficient tensor operations.

  ## Examples

      iex> prim1 = AriaMath.Primitives.box_nx()
      iex> prim2 = AriaMath.Primitives.plane_nx()
      iex> merged = AriaMath.Primitives.merge_nx(prim1, prim2)
      iex> Nx.shape(merged.vertices)
      {12, 3}
  """
  @spec merge_nx(AriaMath.Primitives.Tensor.primitive_tensor(), AriaMath.Primitives.Tensor.primitive_tensor()) :: AriaMath.Primitives.Tensor.primitive_tensor()
  defdelegate merge_nx(prim1, prim2), to: AriaMath.Primitives.Tensor

  @doc """
  Convert a tuple-based primitive to tensor format.

  ## Examples

      iex> tuple_prim = AriaMath.Primitives.box()
      iex> tensor_prim = AriaMath.Primitives.from_tuple_primitive_nx(tuple_prim)
      iex> Nx.shape(tensor_prim.vertices)
      {8, 3}
  """
  @spec from_tuple_primitive_nx(primitive()) :: AriaMath.Primitives.Tensor.primitive_tensor()
  defdelegate from_tuple_primitive_nx(primitive), to: AriaMath.Primitives.Tensor, as: :from_tuple_primitive

  @doc """
  Convert a tensor-based primitive back to tuple format.

  ## Examples

      iex> tensor_prim = AriaMath.Primitives.box_nx()
      iex> tuple_prim = AriaMath.Primitives.to_tuple_primitive_nx(tensor_prim)
      iex> length(tuple_prim.vertices)
      8
  """
  @spec to_tuple_primitive_nx(AriaMath.Primitives.Tensor.primitive_tensor()) :: primitive()
  defdelegate to_tuple_primitive_nx(tensor_primitive), to: AriaMath.Primitives.Tensor, as: :to_tuple_primitive
end
