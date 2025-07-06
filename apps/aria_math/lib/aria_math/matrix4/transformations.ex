# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Matrix4.Transformations do
  @moduledoc """
  Matrix4 transformation operations using Nx tensors.

  This module provides specialized transformation matrices including
  translation, rotation, scaling, and perspective transformations.
  """

  alias AriaMath.Matrix4.Core
  alias AriaMath.Vector3.Tensor, as: Vector3
  alias AriaMath.Quaternion.Tensor, as: Quaternion

  @doc """
  Creates a translation matrix from a Vector3.

  ## Examples

      iex> translation_vec = AriaMath.Vector3.Tensor.new(1.0, 2.0, 3.0)
      iex> matrix = AriaMath.Matrix4.Transformations.translation(translation_vec)
      iex> Nx.to_list(matrix)
      [[1.0, 0.0, 0.0, 1.0], [0.0, 1.0, 0.0, 2.0], [0.0, 0.0, 1.0, 3.0], [0.0, 0.0, 0.0, 1.0]]
  """
  @spec translation(Nx.Tensor.t()) :: Nx.Tensor.t()
  def translation(translation_vector) do
    [x, y, z] = Nx.to_list(translation_vector)

    Core.new(
      1.0, 0.0, 0.0, x,
      0.0, 1.0, 0.0, y,
      0.0, 0.0, 1.0, z,
      0.0, 0.0, 0.0, 1.0
    )
  end

  @doc """
  Creates a translation matrix from x, y, z components.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Transformations.translation_xyz(1.0, 2.0, 3.0)
      iex> Nx.to_list(matrix)
      [[1.0, 0.0, 0.0, 1.0], [0.0, 1.0, 0.0, 2.0], [0.0, 0.0, 1.0, 3.0], [0.0, 0.0, 0.0, 1.0]]
  """
  @spec translation_xyz(float(), float(), float()) :: Nx.Tensor.t()
  def translation_xyz(x, y, z) do
    Core.new(
      1.0, 0.0, 0.0, x,
      0.0, 1.0, 0.0, y,
      0.0, 0.0, 1.0, z,
      0.0, 0.0, 0.0, 1.0
    )
  end

  @doc """
  Creates a scaling matrix from a Vector3.

  ## Examples

      iex> scale_vec = AriaMath.Vector3.Tensor.new(2.0, 3.0, 4.0)
      iex> matrix = AriaMath.Matrix4.Transformations.scaling(scale_vec)
      iex> Nx.to_list(matrix)
      [[2.0, 0.0, 0.0, 0.0], [0.0, 3.0, 0.0, 0.0], [0.0, 0.0, 4.0, 0.0], [0.0, 0.0, 0.0, 1.0]]
  """
  @spec scaling(Nx.Tensor.t()) :: Nx.Tensor.t()
  def scaling(scale_vector) do
    [x, y, z] = Nx.to_list(scale_vector)

    Core.new(
      x, 0.0, 0.0, 0.0,
      0.0, y, 0.0, 0.0,
      0.0, 0.0, z, 0.0,
      0.0, 0.0, 0.0, 1.0
    )
  end

  @doc """
  Creates a uniform scaling matrix.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Transformations.uniform_scaling(2.0)
      iex> Nx.to_list(matrix)
      [[2.0, 0.0, 0.0, 0.0], [0.0, 2.0, 0.0, 0.0], [0.0, 0.0, 2.0, 0.0], [0.0, 0.0, 0.0, 1.0]]
  """
  @spec uniform_scaling(float()) :: Nx.Tensor.t()
  def uniform_scaling(scale) do
    Core.new(
      scale, 0.0, 0.0, 0.0,
      0.0, scale, 0.0, 0.0,
      0.0, 0.0, scale, 0.0,
      0.0, 0.0, 0.0, 1.0
    )
  end

  @doc """
  Creates a rotation matrix from a quaternion.

  ## Examples

      iex> quat = AriaMath.Quaternion.Tensor.identity()
      iex> matrix = AriaMath.Matrix4.Transformations.rotation_from_quaternion(quat)
      iex> AriaMath.Matrix4.Core.equal?(matrix, AriaMath.Matrix4.Core.identity())
      true
  """
  @spec rotation_from_quaternion(Nx.Tensor.t()) :: Nx.Tensor.t()
  def rotation_from_quaternion(quaternion) do
    # Convert quaternion to rotation matrix
    rotation_3x3 = Quaternion.to_rotation_matrix(quaternion)

    # Embed 3x3 rotation in 4x4 matrix
    [[r00, r01, r02], [r10, r11, r12], [r20, r21, r22]] = Nx.to_list(rotation_3x3)

    Core.new(
      r00, r01, r02, 0.0,
      r10, r11, r12, 0.0,
      r20, r21, r22, 0.0,
      0.0, 0.0, 0.0, 1.0
    )
  end

  @doc """
  Creates a rotation matrix around the X axis.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Transformations.rotation_x(0.0)
      iex> AriaMath.Matrix4.Core.equal?(matrix, AriaMath.Matrix4.Core.identity())
      true
  """
  @spec rotation_x(float()) :: Nx.Tensor.t()
  def rotation_x(angle_radians) do
    cos_a = :math.cos(angle_radians)
    sin_a = :math.sin(angle_radians)

    Core.new(
      1.0, 0.0, 0.0, 0.0,
      0.0, cos_a, -sin_a, 0.0,
      0.0, sin_a, cos_a, 0.0,
      0.0, 0.0, 0.0, 1.0
    )
  end

  @doc """
  Creates a rotation matrix around the Y axis.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Transformations.rotation_y(0.0)
      iex> AriaMath.Matrix4.Core.equal?(matrix, AriaMath.Matrix4.Core.identity())
      true
  """
  @spec rotation_y(float()) :: Nx.Tensor.t()
  def rotation_y(angle_radians) do
    cos_a = :math.cos(angle_radians)
    sin_a = :math.sin(angle_radians)

    Core.new(
      cos_a, 0.0, sin_a, 0.0,
      0.0, 1.0, 0.0, 0.0,
      -sin_a, 0.0, cos_a, 0.0,
      0.0, 0.0, 0.0, 1.0
    )
  end

  @doc """
  Creates a rotation matrix around the Z axis.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Transformations.rotation_z(0.0)
      iex> AriaMath.Matrix4.Core.equal?(matrix, AriaMath.Matrix4.Core.identity())
      true
  """
  @spec rotation_z(float()) :: Nx.Tensor.t()
  def rotation_z(angle_radians) do
    cos_a = :math.cos(angle_radians)
    sin_a = :math.sin(angle_radians)

    Core.new(
      cos_a, -sin_a, 0.0, 0.0,
      sin_a, cos_a, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0,
      0.0, 0.0, 0.0, 1.0
    )
  end

  @doc """
  Creates a perspective projection matrix.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Transformations.perspective(45.0, 16.0/9.0, 0.1, 100.0)
      iex> Nx.shape(matrix)
      {4, 4}
  """
  @spec perspective(float(), float(), float(), float()) :: Nx.Tensor.t()
  def perspective(fov_y_degrees, aspect_ratio, near_plane, far_plane) do
    fov_y_radians = fov_y_degrees * :math.pi() / 180.0
    f = 1.0 / :math.tan(fov_y_radians / 2.0)

    Core.new(
      f / aspect_ratio, 0.0, 0.0, 0.0,
      0.0, f, 0.0, 0.0,
      0.0, 0.0, (far_plane + near_plane) / (near_plane - far_plane), (2.0 * far_plane * near_plane) / (near_plane - far_plane),
      0.0, 0.0, -1.0, 0.0
    )
  end

  @doc """
  Creates an orthographic projection matrix.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Transformations.orthographic(-10.0, 10.0, -10.0, 10.0, 0.1, 100.0)
      iex> Nx.shape(matrix)
      {4, 4}
  """
  @spec orthographic(float(), float(), float(), float(), float(), float()) :: Nx.Tensor.t()
  def orthographic(left, right, bottom, top, near_plane, far_plane) do
    width = right - left
    height = top - bottom
    depth = far_plane - near_plane

    Core.new(
      2.0 / width, 0.0, 0.0, -(right + left) / width,
      0.0, 2.0 / height, 0.0, -(top + bottom) / height,
      0.0, 0.0, -2.0 / depth, -(far_plane + near_plane) / depth,
      0.0, 0.0, 0.0, 1.0
    )
  end

  @doc """
  Creates a look-at view matrix.

  ## Examples

      iex> eye = AriaMath.Vector3.Tensor.new(0.0, 0.0, 5.0)
      iex> target = AriaMath.Vector3.Tensor.new(0.0, 0.0, 0.0)
      iex> up = AriaMath.Vector3.Tensor.new(0.0, 1.0, 0.0)
      iex> matrix = AriaMath.Matrix4.Transformations.look_at(eye, target, up)
      iex> Nx.shape(matrix)
      {4, 4}
  """
  @spec look_at(Nx.Tensor.t(), Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def look_at(eye, target, up) do
    # Calculate forward vector (from eye to target)
    forward = Vector3.subtract(target, eye) |> Vector3.normalize()

    # Calculate right vector (cross product of forward and up)
    right = Vector3.cross(forward, up) |> Vector3.normalize()

    # Recalculate up vector (cross product of right and forward)
    new_up = Vector3.cross(right, forward)

    # Extract components
    [fx, fy, fz] = Nx.to_list(forward)
    [rx, ry, rz] = Nx.to_list(right)
    [ux, uy, uz] = Nx.to_list(new_up)
    [_ex, _ey, _ez] = Nx.to_list(eye)

    # Create view matrix
    Core.new(
      rx, ux, -fx, -Vector3.dot(right, eye) |> Nx.to_number(),
      ry, uy, -fy, -Vector3.dot(new_up, eye) |> Nx.to_number(),
      rz, uz, -fz, Vector3.dot(forward, eye) |> Nx.to_number(),
      0.0, 0.0, 0.0, 1.0
    )
  end

  @doc """
  Creates a transformation matrix from translation, rotation, and scale.

  ## Examples

      iex> translation = AriaMath.Vector3.Tensor.new(1.0, 2.0, 3.0)
      iex> rotation = AriaMath.Quaternion.Tensor.identity()
      iex> scale = AriaMath.Vector3.Tensor.new(2.0, 2.0, 2.0)
      iex> matrix = AriaMath.Matrix4.Transformations.compose_trs(translation, rotation, scale)
      iex> Nx.shape(matrix)
      {4, 4}
  """
  @spec compose_trs(Nx.Tensor.t(), Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def compose_trs(translation, rotation, scale) do
    # Create individual transformation matrices
    t_matrix = translation(translation)
    r_matrix = rotation_from_quaternion(rotation)
    s_matrix = scaling(scale)

    # Combine: T * R * S (applied in reverse order)
    Core.multiply(t_matrix, Core.multiply(r_matrix, s_matrix))
  end

  @doc """
  Decomposes a transformation matrix into translation, rotation, and scale.

  Returns {translation_vector, rotation_quaternion, scale_vector}.

  ## Examples

      iex> translation = AriaMath.Vector3.Tensor.new(1.0, 2.0, 3.0)
      iex> rotation = AriaMath.Quaternion.Tensor.identity()
      iex> scale = AriaMath.Vector3.Tensor.new(2.0, 2.0, 2.0)
      iex> matrix = AriaMath.Matrix4.Transformations.compose_trs(translation, rotation, scale)
      iex> {t, r, s} = AriaMath.Matrix4.Transformations.decompose_trs(matrix)
      iex> Vector3.equal?(t, translation)
      true
  """
  @spec decompose_trs(Nx.Tensor.t()) :: {Nx.Tensor.t(), Nx.Tensor.t(), Nx.Tensor.t()}
  def decompose_trs(matrix) do
    # Extract translation (last column, first 3 rows)
    translation = Nx.slice(matrix, [0, 3], [3, 1]) |> Nx.reshape({3})

    # Extract upper-left 3x3 matrix for rotation and scale
    upper_3x3 = Nx.slice(matrix, [0, 0], [3, 3])

    # Extract scale (length of each column vector)
    col0 = upper_3x3[[.., 0]]
    col1 = upper_3x3[[.., 1]]
    col2 = upper_3x3[[.., 2]]

    scale_x = Vector3.magnitude(col0) |> Nx.to_number()
    scale_y = Vector3.magnitude(col1) |> Nx.to_number()
    scale_z = Vector3.magnitude(col2) |> Nx.to_number()

    scale = Vector3.new(scale_x, scale_y, scale_z)

    # Remove scale to get pure rotation matrix
    rotation_matrix = Nx.stack([
      Nx.divide(col0, scale_x),
      Nx.divide(col1, scale_y),
      Nx.divide(col2, scale_z)
    ], axis: 1)

    # Convert rotation matrix to quaternion
    rotation = Quaternion.from_rotation_matrix(rotation_matrix)

    {translation, rotation, scale}
  end

  @doc """
  Transforms a point using a transformation matrix.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Transformations.translation_xyz(1.0, 2.0, 3.0)
      iex> point = AriaMath.Vector3.Tensor.new(0.0, 0.0, 0.0)
      iex> transformed = AriaMath.Matrix4.Transformations.transform_point(matrix, point)
      iex> Nx.to_list(transformed)
      [1.0, 2.0, 3.0]
  """
  @spec transform_point(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def transform_point(matrix, point) do
    # Convert point to homogeneous coordinates (w = 1.0)
    [x, y, z] = Nx.to_list(point)
    homogeneous_point = Nx.tensor([x, y, z, 1.0], type: :f32)

    # Transform the point
    transformed = Nx.dot(matrix, homogeneous_point)

    # Extract x, y, z components (ignore w)
    Nx.slice(transformed, [0], [3])
  end

  @doc """
  Transforms a direction vector using a transformation matrix.

  Direction vectors are not affected by translation (w = 0.0).

  ## Examples

      iex> matrix = AriaMath.Matrix4.Transformations.translation_xyz(1.0, 2.0, 3.0)
      iex> direction = AriaMath.Vector3.Tensor.new(1.0, 0.0, 0.0)
      iex> transformed = AriaMath.Matrix4.Transformations.transform_direction(matrix, direction)
      iex> Vector3.equal?(transformed, direction)
      true
  """
  @spec transform_direction(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def transform_direction(matrix, direction) do
    # Convert direction to homogeneous coordinates (w = 0.0)
    [x, y, z] = Nx.to_list(direction)
    homogeneous_direction = Nx.tensor([x, y, z, 0.0], type: :f32)

    # Transform the direction
    transformed = Nx.dot(matrix, homogeneous_direction)

    # Extract x, y, z components (ignore w)
    Nx.slice(transformed, [0], [3])
  end

  @doc """
  Extracts the translation vector from a transformation matrix.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Transformations.translation_xyz(1.0, 2.0, 3.0)
      iex> translation = AriaMath.Matrix4.Transformations.get_translation(matrix)
      iex> Nx.to_list(translation)
      [1.0, 2.0, 3.0]
  """
  @spec get_translation(Nx.Tensor.t()) :: Nx.Tensor.t()
  def get_translation(matrix) do
    # Extract translation (last column, first 3 rows)
    Nx.slice(matrix, [0, 3], [3, 1]) |> Nx.reshape({3})
  end

  @doc """
  Creates a rotation matrix from a quaternion (KHR Interactivity compatible).

  This is a convenience wrapper around rotation_from_quaternion/1.

  ## Examples

      iex> quat = AriaMath.Quaternion.Tensor.identity()
      iex> matrix = AriaMath.Matrix4.Transformations.rotation(quat)
      iex> AriaMath.Matrix4.Core.equal?(matrix, AriaMath.Matrix4.Core.identity())
      true
  """
  @spec rotation(Nx.Tensor.t()) :: Nx.Tensor.t()
  def rotation(quaternion) do
    rotation_from_quaternion(quaternion)
  end

  @doc """
  Creates a transformation matrix from translation, rotation, and scale (KHR Interactivity compatible).

  This is a convenience wrapper around compose_trs/3.

  ## Examples

      iex> translation = AriaMath.Vector3.Tensor.new(1.0, 2.0, 3.0)
      iex> rotation = AriaMath.Quaternion.Tensor.identity()
      iex> scale = AriaMath.Vector3.Tensor.new(2.0, 2.0, 2.0)
      iex> matrix = AriaMath.Matrix4.Transformations.compose(translation, rotation, scale)
      iex> Nx.shape(matrix)
      {4, 4}
  """
  @spec compose(Nx.Tensor.t(), Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def compose(translation, rotation, scale) do
    compose_trs(translation, rotation, scale)
  end

  @doc """
  Decomposes a transformation matrix into translation, rotation, and scale (KHR Interactivity compatible).

  This is a convenience wrapper around decompose_trs/1.

  ## Examples

      iex> translation = AriaMath.Vector3.Tensor.new(1.0, 2.0, 3.0)
      iex> rotation = AriaMath.Quaternion.Tensor.identity()
      iex> scale = AriaMath.Vector3.Tensor.new(2.0, 2.0, 2.0)
      iex> matrix = AriaMath.Matrix4.Transformations.compose_trs(translation, rotation, scale)
      iex> {t, r, s} = AriaMath.Matrix4.Transformations.decompose(matrix)
      iex> Vector3.equal?(t, translation)
      true
  """
  @spec decompose(Nx.Tensor.t()) :: {Nx.Tensor.t(), Nx.Tensor.t(), Nx.Tensor.t()}
  def decompose(matrix) do
    decompose_trs(matrix)
  end

  @doc """
  Extracts the upper-left 3x3 basis matrix (rotation and scale components).

  ## Examples

      iex> matrix = AriaMath.Matrix4.Transformations.scaling(AriaMath.Vector3.Tensor.new(2.0, 3.0, 4.0))
      iex> basis = AriaMath.Matrix4.Transformations.extract_basis(matrix)
      iex> Nx.shape(basis)
      {3, 3}
  """
  @spec extract_basis(Nx.Tensor.t()) :: Nx.Tensor.t()
  def extract_basis(matrix) do
    # Extract upper-left 3x3 matrix
    Nx.slice(matrix, [0, 0], [3, 3])
  end

  @doc """
  Orthogonalizes a matrix using the Gram-Schmidt process.

  This ensures the matrix represents a valid rotation by making the basis vectors orthonormal.

  ## Examples

      iex> matrix = AriaMath.Matrix4.Core.identity()
      iex> orthogonal = AriaMath.Matrix4.Transformations.orthogonalize(matrix)
      iex> AriaMath.Matrix4.Core.equal?(orthogonal, matrix)
      true
  """
  @spec orthogonalize(Nx.Tensor.t()) :: Nx.Tensor.t()
  def orthogonalize(matrix) do
    # Extract the upper-left 3x3 basis matrix
    basis = extract_basis(matrix)

    # Extract column vectors
    col0 = basis[[.., 0]]
    col1 = basis[[.., 1]]
    col2 = basis[[.., 2]]

    # Gram-Schmidt orthogonalization
    # First vector: normalize
    u0 = Vector3.normalize(col0)

    # Second vector: subtract projection onto first, then normalize
    proj1 = Nx.multiply(u0, Vector3.dot(col1, u0))
    u1 = Vector3.subtract(col1, proj1) |> Vector3.normalize()

    # Third vector: subtract projections onto first two, then normalize
    proj2_0 = Nx.multiply(u0, Vector3.dot(col2, u0))
    proj2_1 = Nx.multiply(u1, Vector3.dot(col2, u1))
    u2 = Vector3.subtract(col2, Nx.add(proj2_0, proj2_1)) |> Vector3.normalize()

    # Reconstruct the orthogonal basis matrix
    orthogonal_basis = Nx.stack([u0, u1, u2], axis: 1)

    # Embed back into 4x4 matrix, preserving translation
    translation = get_translation(matrix)
    [tx, ty, tz] = Nx.to_list(translation)

    [[r00, r01, r02], [r10, r11, r12], [r20, r21, r22]] = Nx.to_list(orthogonal_basis)

    Core.new(
      r00, r01, r02, tx,
      r10, r11, r12, ty,
      r20, r21, r22, tz,
      0.0, 0.0, 0.0, 1.0
    )
  end
end
