# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Quaternion do
  @moduledoc """
  Quaternion mathematical operations implementing glTF KHR Interactivity `float4` quaternion operations.

  All operations follow IEEE-754 standard for NaN, infinity, and special case handling
  as defined in the glTF KHR Interactivity specification.

  Quaternion is represented as a 4-tuple {x, y, z, w} using XYZW order where w is the scalar component.
  This follows glTF convention.
  """

  import Kernel, except: [length: 1]

  alias AriaMath.Quaternion.Core
  alias AriaMath.Quaternion.Conversions
  alias AriaMath.Quaternion.Operations
  alias AriaMath.Quaternion.Utilities
  alias AriaMath.Quaternion.Tensor

  @type t :: {float(), float(), float(), float()}

  # Core operations
  defdelegate new(x, y, z, w), to: Core
  defdelegate conjugate(quaternion), to: Core
  defdelegate multiply(q1, q2), to: Core
  defdelegate dot(q1, q2), to: Core
  defdelegate length(quaternion), to: Core
  defdelegate normalize(quaternion), to: Core

  # Conversion operations
  defdelegate angle_between(q1, q2), to: Conversions
  defdelegate from_axis_angle(axis, angle), to: Conversions
  defdelegate to_axis_angle(quaternion), to: Conversions
  defdelegate from_directions(a, b), to: Conversions
  defdelegate from_euler(yaw, pitch, roll), to: Conversions

  # Advanced operations
  defdelegate slerp(q1, q2, t), to: Operations
  defdelegate rotate_vector(quaternion, vector), to: Operations
  defdelegate rotate(quaternion, vector), to: Operations

  # Utility functions
  defdelegate identity(), to: Utilities
  defdelegate is_identity?(quaternion), to: Utilities
  defdelegate is_identity?(quaternion, tolerance), to: Utilities
  defdelegate approx_equal?(q1, q2), to: Utilities
  defdelegate approx_equal?(q1, q2, tolerance), to: Utilities
  defdelegate equal?(q1, q2), to: Utilities
  defdelegate equal?(q1, q2, tolerance), to: Utilities

  # Nx tensor operations
  defdelegate new_nx(x, y, z, w), to: Tensor, as: :new
  defdelegate from_tuple_nx(tuple), to: Tensor, as: :from_tuple
  defdelegate to_tuple_nx(tensor), to: Tensor, as: :to_tuple
  defdelegate identity_nx(), to: Tensor, as: :identity
  defdelegate length_nx(quaternion), to: Tensor, as: :length
  defdelegate normalize_nx(quaternion), to: Tensor, as: :normalize
  defdelegate dot_nx(q1, q2), to: Tensor, as: :dot
  defdelegate conjugate_nx(quaternion), to: Tensor, as: :conjugate
  defdelegate multiply_nx(q1, q2), to: Tensor, as: :multiply
  defdelegate slerp_nx(q1, q2, t), to: Tensor, as: :slerp
  defdelegate equal_nx?(q1, q2), to: Tensor, as: :equal?
  defdelegate equal_nx?(q1, q2, tolerance), to: Tensor, as: :equal?

  # Nx batch operations
  defdelegate length_batch(quaternions), to: Tensor
  defdelegate normalize_batch(quaternions), to: Tensor
  defdelegate dot_batch(q1_batch, q2_batch), to: Tensor
  defdelegate conjugate_batch(quaternions), to: Tensor
  defdelegate multiply_batch(q1_batch, q2_batch), to: Tensor
  defdelegate slerp_batch(q1_batch, q2_batch, t_batch), to: Tensor
  defdelegate equal_batch?(q1_batch, q2_batch), to: Tensor
  defdelegate equal_batch?(q1_batch, q2_batch, tolerance), to: Tensor
end
