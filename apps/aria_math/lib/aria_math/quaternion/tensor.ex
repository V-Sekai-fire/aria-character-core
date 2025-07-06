# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Quaternion.Tensor do
  @moduledoc """
  Nx tensor-based Quaternion operations.

  This module provides the same API as Quaternion core modules but uses Nx tensors
  for optimized numerical computing and potential GPU acceleration.

  Quaternions are represented as Nx tensors with shape [4] in [x, y, z, w] order.
  """

  @type quaternion_tensor :: Nx.Tensor.t()
  @type quaternion_tuple :: {float(), float(), float(), float()}

  @doc """
  Creates a new Quaternion tensor from x, y, z, w components.

  ## Examples

      iex> AriaMath.Quaternion.Tensor.new(0.0, 0.0, 0.0, 1.0)
      #Nx.Tensor<
        f32[4]
        [0.0, 0.0, 0.0, 1.0]
      >
  """
  @spec new(float(), float(), float(), float()) :: quaternion_tensor()
  def new(x, y, z, w) when is_number(x) and is_number(y) and is_number(z) and is_number(w) do
    Nx.tensor([x, y, z, w], type: :f32)
  end

  @doc """
  Creates a Quaternion tensor from a 4-tuple.

  ## Examples

      iex> tuple = {0.0, 0.0, 0.0, 1.0}
      iex> AriaMath.Quaternion.Tensor.from_tuple(tuple)
      #Nx.Tensor<
        f32[4]
        [0.0, 0.0, 0.0, 1.0]
      >
  """
  @spec from_tuple(quaternion_tuple()) :: quaternion_tensor()
  def from_tuple({x, y, z, w}) do
    new(x, y, z, w)
  end

  @doc """
  Converts a Quaternion tensor to a 4-tuple.

  ## Examples

      iex> quat = AriaMath.Quaternion.Tensor.identity()
      iex> AriaMath.Quaternion.Tensor.to_tuple(quat)
      {0.0, 0.0, 0.0, 1.0}
  """
  @spec to_tuple(quaternion_tensor()) :: quaternion_tuple()
  def to_tuple(tensor) do
    [x, y, z, w] = Nx.to_list(tensor)
    {x, y, z, w}
  end

  @doc """
  Creates an identity quaternion using Nx operations.

  ## Examples

      iex> AriaMath.Quaternion.Tensor.identity()
      #Nx.Tensor<
        f32[4]
        [0.0, 0.0, 0.0, 1.0]
      >
  """
  @spec identity() :: quaternion_tensor()
  def identity do
    Nx.tensor([0.0, 0.0, 0.0, 1.0], type: :f32)
  end

  @doc """
  Quaternion length (magnitude) using Nx operations.

  ## Examples

      iex> quat = AriaMath.Quaternion.Tensor.identity()
      iex> AriaMath.Quaternion.Tensor.length(quat)
      1.0
  """
  @spec length(quaternion_tensor()) :: float()
  def length(quaternion) do
    Nx.LinAlg.norm(quaternion) |> Nx.to_number()
  end

  @doc """
  Batch quaternion length calculation for multiple quaternions.

  ## Examples

      iex> quats = Nx.stack([AriaMath.Quaternion.Tensor.identity(), AriaMath.Quaternion.Tensor.identity()])
      iex> lengths = AriaMath.Quaternion.Tensor.length_batch(quats)
      iex> Nx.to_list(lengths)
      [1.0, 1.0]
  """
  @spec length_batch(Nx.Tensor.t()) :: Nx.Tensor.t()
  def length_batch(quaternions) do
    Nx.LinAlg.norm(quaternions, axis: 1)
  end

  @doc """
  Quaternion normalization using Nx operations.

  ## Examples

      iex> quat = AriaMath.Quaternion.Tensor.new(1.0, 1.0, 1.0, 1.0)
      iex> normalized = AriaMath.Quaternion.Tensor.normalize(quat)
      iex> AriaMath.Quaternion.Tensor.length(normalized)
      1.0
  """
  @spec normalize(quaternion_tensor()) :: quaternion_tensor()
  def normalize(quaternion) do
    norm = Nx.LinAlg.norm(quaternion)

    # Handle zero-length quaternion
    case Nx.to_number(norm) do
      n when n < 1.0e-10 -> identity()
      _ -> Nx.divide(quaternion, norm)
    end
  end

  @doc """
  Batch quaternion normalization for multiple quaternions.

  ## Examples

      iex> quats = Nx.stack([
      ...>   AriaMath.Quaternion.Tensor.new(1.0, 1.0, 1.0, 1.0),
      ...>   AriaMath.Quaternion.Tensor.new(2.0, 0.0, 0.0, 0.0)
      ...> ])
      iex> normalized = AriaMath.Quaternion.Tensor.normalize_batch(quats)
      iex> lengths = AriaMath.Quaternion.Tensor.length_batch(normalized)
      iex> Nx.all_close(lengths, Nx.tensor([1.0, 1.0]))
      true
  """
  @spec normalize_batch(Nx.Tensor.t()) :: Nx.Tensor.t()
  def normalize_batch(quaternions) do
    norms = Nx.LinAlg.norm(quaternions, axis: 1)

    # Create identity quaternions for zero-length cases
    identity_batch = Nx.broadcast(identity(), Nx.shape(quaternions))

    # Check for zero-length quaternions
    valid_mask = Nx.greater(norms, 1.0e-10)

    # Normalize valid quaternions
    normalized = Nx.divide(quaternions, Nx.new_axis(norms, -1))

    # Replace invalid quaternions with identity
    Nx.select(
      Nx.new_axis(valid_mask, -1),
      normalized,
      identity_batch
    )
  end

  @doc """
  Dot product of two quaternions using Nx operations.

  ## Examples

      iex> q1 = AriaMath.Quaternion.Tensor.identity()
      iex> q2 = AriaMath.Quaternion.Tensor.identity()
      iex> AriaMath.Quaternion.Tensor.dot(q1, q2)
      1.0
  """
  @spec dot(quaternion_tensor(), quaternion_tensor()) :: float()
  def dot(q1, q2) do
    Nx.dot(q1, q2) |> Nx.to_number()
  end

  @doc """
  Batch dot product for multiple quaternion pairs.

  ## Examples

      iex> q1_batch = Nx.stack([AriaMath.Quaternion.Tensor.identity(), AriaMath.Quaternion.Tensor.identity()])
      iex> q2_batch = Nx.stack([AriaMath.Quaternion.Tensor.identity(), AriaMath.Quaternion.Tensor.identity()])
      iex> dots = AriaMath.Quaternion.Tensor.dot_batch(q1_batch, q2_batch)
      iex> Nx.to_list(dots)
      [1.0, 1.0]
  """
  @spec dot_batch(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def dot_batch(q1_batch, q2_batch) do
    Nx.sum(Nx.multiply(q1_batch, q2_batch), axes: [1])
  end

  @doc """
  Quaternion conjugate using Nx operations.

  ## Examples

      iex> quat = AriaMath.Quaternion.Tensor.new(1.0, 2.0, 3.0, 4.0)
      iex> conj = AriaMath.Quaternion.Tensor.conjugate(quat)
      iex> AriaMath.Quaternion.Tensor.to_tuple(conj)
      {-1.0, -2.0, -3.0, 4.0}
  """
  @spec conjugate(quaternion_tensor()) :: quaternion_tensor()
  def conjugate(quaternion) do
    # Negate x, y, z components, keep w
    conjugate_mask = Nx.tensor([-1.0, -1.0, -1.0, 1.0], type: :f32)
    Nx.multiply(quaternion, conjugate_mask)
  end

  @doc """
  Batch quaternion conjugate for multiple quaternions.

  ## Examples

      iex> quats = Nx.stack([
      ...>   AriaMath.Quaternion.Tensor.new(1.0, 2.0, 3.0, 4.0),
      ...>   AriaMath.Quaternion.Tensor.new(5.0, 6.0, 7.0, 8.0)
      ...> ])
      iex> conj = AriaMath.Quaternion.Tensor.conjugate_batch(quats)
      iex> Nx.to_list(conj)
      [[-1.0, -2.0, -3.0, 4.0], [-5.0, -6.0, -7.0, 8.0]]
  """
  @spec conjugate_batch(Nx.Tensor.t()) :: Nx.Tensor.t()
  def conjugate_batch(quaternions) do
    conjugate_mask = Nx.tensor([-1.0, -1.0, -1.0, 1.0], type: :f32)
    Nx.multiply(quaternions, conjugate_mask)
  end

  @doc """
  Quaternion multiplication using Nx operations.

  ## Examples

      iex> q1 = AriaMath.Quaternion.Tensor.identity()
      iex> q2 = AriaMath.Quaternion.Tensor.identity()
      iex> result = AriaMath.Quaternion.Tensor.multiply(q1, q2)
      iex> AriaMath.Quaternion.Tensor.to_tuple(result)
      {0.0, 0.0, 0.0, 1.0}
  """
  @spec multiply(quaternion_tensor(), quaternion_tensor()) :: quaternion_tensor()
  def multiply(q1, q2) do
    [x1, y1, z1, w1] = Nx.to_list(q1)
    [x2, y2, z2, w2] = Nx.to_list(q2)

    # Quaternion multiplication formula
    x = w1 * x2 + x1 * w2 + y1 * z2 - z1 * y2
    y = w1 * y2 - x1 * z2 + y1 * w2 + z1 * x2
    z = w1 * z2 + x1 * y2 - y1 * x2 + z1 * w2
    w = w1 * w2 - x1 * x2 - y1 * y2 - z1 * z2

    new(x, y, z, w)
  end

  @doc """
  Batch quaternion multiplication for multiple quaternion pairs.

  ## Examples

      iex> q1_batch = Nx.stack([AriaMath.Quaternion.Tensor.identity(), AriaMath.Quaternion.Tensor.identity()])
      iex> q2_batch = Nx.stack([AriaMath.Quaternion.Tensor.identity(), AriaMath.Quaternion.Tensor.identity()])
      iex> results = AriaMath.Quaternion.Tensor.multiply_batch(q1_batch, q2_batch)
      iex> Nx.shape(results)
      {2, 4}
  """
  @spec multiply_batch(Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def multiply_batch(q1_batch, q2_batch) do
    # Extract components
    x1 = Nx.slice_along_axis(q1_batch, 0, 1, axis: 1) |> Nx.squeeze(axes: [1])
    y1 = Nx.slice_along_axis(q1_batch, 1, 1, axis: 1) |> Nx.squeeze(axes: [1])
    z1 = Nx.slice_along_axis(q1_batch, 2, 1, axis: 1) |> Nx.squeeze(axes: [1])
    w1 = Nx.slice_along_axis(q1_batch, 3, 1, axis: 1) |> Nx.squeeze(axes: [1])

    x2 = Nx.slice_along_axis(q2_batch, 0, 1, axis: 1) |> Nx.squeeze(axes: [1])
    y2 = Nx.slice_along_axis(q2_batch, 1, 1, axis: 1) |> Nx.squeeze(axes: [1])
    z2 = Nx.slice_along_axis(q2_batch, 2, 1, axis: 1) |> Nx.squeeze(axes: [1])
    w2 = Nx.slice_along_axis(q2_batch, 3, 1, axis: 1) |> Nx.squeeze(axes: [1])

    # Quaternion multiplication formula
    x = Nx.add(Nx.add(Nx.add(Nx.multiply(w1, x2), Nx.multiply(x1, w2)), Nx.multiply(y1, z2)), Nx.multiply(z1, y2) |> Nx.negate())
    y = Nx.add(Nx.add(Nx.add(Nx.multiply(w1, y2), Nx.multiply(x1, z2) |> Nx.negate()), Nx.multiply(y1, w2)), Nx.multiply(z1, x2))
    z = Nx.add(Nx.add(Nx.add(Nx.multiply(w1, z2), Nx.multiply(x1, y2)), Nx.multiply(y1, x2) |> Nx.negate()), Nx.multiply(z1, w2))
    w = Nx.subtract(Nx.subtract(Nx.subtract(Nx.multiply(w1, w2), Nx.multiply(x1, x2)), Nx.multiply(y1, y2)), Nx.multiply(z1, z2))

    # Stack components back into quaternions
    Nx.stack([x, y, z, w], axis: 1)
  end

  @doc """
  Spherical linear interpolation (SLERP) between two quaternions using Nx operations.

  ## Examples

      iex> q1 = AriaMath.Quaternion.Tensor.identity()
      iex> q2 = AriaMath.Quaternion.Tensor.new(0.0, 0.0, 0.707, 0.707)
      iex> result = AriaMath.Quaternion.Tensor.slerp(q1, q2, 0.5)
      iex> AriaMath.Quaternion.Tensor.length(result)
      1.0
  """
  @spec slerp(quaternion_tensor(), quaternion_tensor(), float()) :: quaternion_tensor()
  def slerp(q1, q2, t) when is_number(t) do
    # Normalize quaternions
    q1_norm = normalize(q1)
    q2_norm = normalize(q2)

    # Compute dot product
    dot_product = dot(q1_norm, q2_norm)

    # If dot product is negative, negate one quaternion to take shorter path
    {q1_final, q2_final, dot_final} =
      if dot_product < 0.0 do
        {q1_norm, Nx.negate(q2_norm), -dot_product}
      else
        {q1_norm, q2_norm, dot_product}
      end

    # Clamp dot product to avoid numerical issues
    dot_clamped = max(-1.0, min(1.0, dot_final))

    # If quaternions are very close, use linear interpolation
    if abs(dot_clamped) > 0.9995 do
      # Linear interpolation
      result = Nx.add(
        Nx.multiply(q1_final, 1.0 - t),
        Nx.multiply(q2_final, t)
      )
      normalize(result)
    else
      # Spherical interpolation
      theta = :math.acos(abs(dot_clamped))
      sin_theta = :math.sin(theta)

      factor1 = :math.sin((1.0 - t) * theta) / sin_theta
      factor2 = :math.sin(t * theta) / sin_theta

      result = Nx.add(
        Nx.multiply(q1_final, factor1),
        Nx.multiply(q2_final, factor2)
      )
      result
    end
  end

  @doc """
  Batch SLERP for multiple quaternion pairs.

  ## Examples

      iex> q1_batch = Nx.stack([AriaMath.Quaternion.Tensor.identity(), AriaMath.Quaternion.Tensor.identity()])
      iex> q2_batch = Nx.stack([AriaMath.Quaternion.Tensor.new(0.0, 0.0, 0.707, 0.707), AriaMath.Quaternion.Tensor.new(0.707, 0.0, 0.0, 0.707)])
      iex> t_values = Nx.tensor([0.5, 0.5])
      iex> results = AriaMath.Quaternion.Tensor.slerp_batch(q1_batch, q2_batch, t_values)
      iex> Nx.shape(results)
      {2, 4}
  """
  @spec slerp_batch(Nx.Tensor.t(), Nx.Tensor.t(), Nx.Tensor.t()) :: Nx.Tensor.t()
  def slerp_batch(q1_batch, q2_batch, t_batch) do
    # Normalize quaternions
    q1_norm = normalize_batch(q1_batch)
    q2_norm = normalize_batch(q2_batch)

    # Compute dot products
    dot_products = dot_batch(q1_norm, q2_norm)

    # Handle negative dot products (take shorter path)
    negative_mask = Nx.less(dot_products, 0.0)
    q2_adjusted = Nx.select(
      Nx.new_axis(negative_mask, -1),
      Nx.negate(q2_norm),
      q2_norm
    )
    dot_adjusted = Nx.select(negative_mask, Nx.negate(dot_products), dot_products)

    # Clamp dot products
    dot_clamped = Nx.clip(dot_adjusted, -1.0, 1.0)

    # Check for very close quaternions (use linear interpolation)
    close_mask = Nx.greater(Nx.abs(dot_clamped), 0.9995)

    # Linear interpolation
    linear_result = normalize_batch(
      Nx.add(
        Nx.multiply(q1_norm, Nx.new_axis(Nx.subtract(1.0, t_batch), -1)),
        Nx.multiply(q2_adjusted, Nx.new_axis(t_batch, -1))
      )
    )

    # Spherical interpolation
    theta = Nx.acos(Nx.abs(dot_clamped))
    sin_theta = Nx.sin(theta)

    factor1 = Nx.divide(Nx.sin(Nx.multiply(Nx.subtract(1.0, t_batch), theta)), sin_theta)
    factor2 = Nx.divide(Nx.sin(Nx.multiply(t_batch, theta)), sin_theta)

    spherical_result = Nx.add(
      Nx.multiply(q1_norm, Nx.new_axis(factor1, -1)),
      Nx.multiply(q2_adjusted, Nx.new_axis(factor2, -1))
    )

    # Select between linear and spherical interpolation
    Nx.select(
      Nx.new_axis(close_mask, -1),
      linear_result,
      spherical_result
    )
  end

  @doc """
  Checks if two quaternions are approximately equal within a tolerance.

  ## Examples

      iex> q1 = AriaMath.Quaternion.Tensor.identity()
      iex> q2 = AriaMath.Quaternion.Tensor.identity()
      iex> AriaMath.Quaternion.Tensor.equal?(q1, q2)
      true
  """
  @spec equal?(quaternion_tensor(), quaternion_tensor(), float()) :: boolean()
  def equal?(q1, q2, tolerance \\ 1.0e-6) do
    diff = Nx.subtract(q1, q2)
    max_diff = Nx.abs(diff) |> Nx.reduce_max() |> Nx.to_number()
    max_diff <= tolerance
  end

  @doc """
  Batch equality check for multiple quaternion pairs.

  ## Examples

      iex> q1_batch = Nx.stack([AriaMath.Quaternion.Tensor.identity(), AriaMath.Quaternion.Tensor.identity()])
      iex> q2_batch = Nx.stack([AriaMath.Quaternion.Tensor.identity(), AriaMath.Quaternion.Tensor.identity()])
      iex> results = AriaMath.Quaternion.Tensor.equal_batch?(q1_batch, q2_batch)
      iex> Nx.to_list(results)
      [1, 1]  # Both pairs are equal
  """
  @spec equal_batch?(Nx.Tensor.t(), Nx.Tensor.t(), float()) :: Nx.Tensor.t()
  def equal_batch?(q1_batch, q2_batch, tolerance \\ 1.0e-6) do
    diff = Nx.subtract(q1_batch, q2_batch)
    max_diff_per_quat = Nx.abs(diff) |> Nx.reduce_max(axes: [1])
    Nx.less_equal(max_diff_per_quat, tolerance)
  end

  @doc """
  Converts a quaternion to a 3x3 rotation matrix.

  Implements the standard quaternion to rotation matrix conversion formula.
  The quaternion is assumed to be normalized.

  ## Examples

      iex> quat = AriaMath.Quaternion.Tensor.identity()
      iex> matrix = AriaMath.Quaternion.Tensor.to_rotation_matrix(quat)
      iex> Nx.shape(matrix)
      {3, 3}
  """
  @spec to_rotation_matrix(quaternion_tensor()) :: Nx.Tensor.t()
  def to_rotation_matrix(quaternion) do
    # Normalize the quaternion to ensure it's a unit quaternion
    q = normalize(quaternion)
    [x, y, z, w] = Nx.to_list(q)

    # Precompute repeated values
    x2 = x + x
    y2 = y + y
    z2 = z + z
    xx = x * x2
    xy = x * y2
    xz = x * z2
    yy = y * y2
    yz = y * z2
    zz = z * z2
    wx = w * x2
    wy = w * y2
    wz = w * z2

    # Build the 3x3 rotation matrix
    Nx.tensor([
      [1.0 - (yy + zz), xy - wz, xz + wy],
      [xy + wz, 1.0 - (xx + zz), yz - wx],
      [xz - wy, yz + wx, 1.0 - (xx + yy)]
    ], type: :f32)
  end

  @doc """
  Converts a 3x3 rotation matrix to a quaternion.

  Uses Shepperd's method for numerical stability.
  The input matrix is assumed to be a valid rotation matrix.

  ## Examples

      iex> matrix = Nx.eye(3, type: :f32)
      iex> quat = AriaMath.Quaternion.Tensor.from_rotation_matrix(matrix)
      iex> AriaMath.Quaternion.Tensor.equal?(quat, AriaMath.Quaternion.Tensor.identity())
      true
  """
  @spec from_rotation_matrix(Nx.Tensor.t()) :: quaternion_tensor()
  def from_rotation_matrix(matrix) do
    # Extract matrix elements
    [[m00, m01, m02], [m10, m11, m12], [m20, m21, m22]] = Nx.to_list(matrix)

    # Compute the trace
    trace = m00 + m11 + m22

    cond do
      # Case 1: trace > 0 (most common case)
      trace > 0.0 ->
        s = :math.sqrt(trace + 1.0) * 2.0  # s = 4 * w
        w = 0.25 * s
        x = (m21 - m12) / s
        y = (m02 - m20) / s
        z = (m10 - m01) / s
        new(x, y, z, w)

      # Case 2: m00 > m11 && m00 > m22
      m00 > m11 and m00 > m22 ->
        s = :math.sqrt(1.0 + m00 - m11 - m22) * 2.0  # s = 4 * x
        w = (m21 - m12) / s
        x = 0.25 * s
        y = (m01 + m10) / s
        z = (m02 + m20) / s
        new(x, y, z, w)

      # Case 3: m11 > m22
      m11 > m22 ->
        s = :math.sqrt(1.0 + m11 - m00 - m22) * 2.0  # s = 4 * y
        w = (m02 - m20) / s
        x = (m01 + m10) / s
        y = 0.25 * s
        z = (m12 + m21) / s
        new(x, y, z, w)

      # Case 4: default (m22 is largest)
      true ->
        s = :math.sqrt(1.0 + m22 - m00 - m11) * 2.0  # s = 4 * z
        w = (m10 - m01) / s
        x = (m02 + m20) / s
        y = (m12 + m21) / s
        z = 0.25 * s
        new(x, y, z, w)
    end
  end
end
