# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

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
end
