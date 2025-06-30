# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMath.Matrix4.Euler do
  @moduledoc """
  Euler angle operations for Matrix4.

  Contains functions for creating rotation matrices from Euler angles
  with support for all 6 Tait-Bryan rotation orders.
  """

  alias AriaMath.Matrix4

  @doc """
  Create rotation matrix from Euler angles.

  Creates a rotation matrix from Euler angles in radians. Supports all 6 Tait-Bryan rotation orders.
  Default order is XYZ (roll around X, pitch around Y, yaw around Z).

  ## Rotation Orders

  - `:xyz` - Roll (X), Pitch (Y), Yaw (Z) - Default
  - `:xzy` - Roll (X), Yaw (Z), Pitch (Y)
  - `:yxz` - Pitch (Y), Roll (X), Yaw (Z)
  - `:yzx` - Pitch (Y), Yaw (Z), Roll (X)
  - `:zxy` - Yaw (Z), Roll (X), Pitch (Y)
  - `:zyx` - Yaw (Z), Pitch (Y), Roll (X)
  """
  @spec from_euler(float(), float(), float()) :: Matrix4.t()
  def from_euler(x, y, z) when is_number(x) and is_number(y) and is_number(z) do
    from_euler(x, y, z, :xyz)
  end

  @spec from_euler(float(), float(), float(), atom()) :: Matrix4.t()
  def from_euler(x, y, z, order) when is_number(x) and is_number(y) and is_number(z) and is_atom(order) do
    # Calculate trigonometric values with epsilon cleanup
    cx = clean_float(:math.cos(x))
    sx = clean_float(:math.sin(x))
    cy = clean_float(:math.cos(y))
    sy = clean_float(:math.sin(y))
    cz = clean_float(:math.cos(z))
    sz = clean_float(:math.sin(z))

    case order do
      :xyz -> from_euler_xyz(cx, sx, cy, sy, cz, sz)
      :xzy -> from_euler_xzy(cx, sx, cy, sy, cz, sz)
      :yxz -> from_euler_yxz(cx, sx, cy, sy, cz, sz)
      :yzx -> from_euler_yzx(cx, sx, cy, sy, cz, sz)
      :zxy -> from_euler_zxy(cx, sx, cy, sy, cz, sz)
      :zyx -> from_euler_zyx(cx, sx, cy, sy, cz, sz)
      _ -> raise ArgumentError, "Invalid rotation order: #{order}. Valid orders are: :xyz, :xzy, :yxz, :yzx, :zxy, :zyx"
    end
  end

  # Clean up floating-point precision errors
  defp clean_float(value) when is_float(value) do
    epsilon = 1.0e-15
    cond do
      abs(value) < epsilon -> 0.0
      abs(value - 1.0) < epsilon -> 1.0
      abs(value + 1.0) < epsilon -> -1.0
      value == -0.0 -> 0.0  # Convert -0.0 to 0.0
      true -> value
    end
  end

  # XYZ rotation order: R = Rz(z) * Ry(y) * Rx(x)
  defp from_euler_xyz(cx, sx, cy, sy, cz, sz) do
    {
      clean_float(cy * cz), clean_float(sx * sy * cz + cx * sz), clean_float(-cx * sy * cz + sx * sz), 0.0,
      clean_float(-cy * sz), clean_float(-sx * sy * sz + cx * cz), clean_float(cx * sy * sz + sx * cz), 0.0,
      clean_float(sy), clean_float(-sx * cy), clean_float(cx * cy), 0.0,
      0.0, 0.0, 0.0, 1.0
    }
  end

  # XZY rotation order: R = Ry(y) * Rz(z) * Rx(x)
  defp from_euler_xzy(cx, sx, cy, sy, cz, sz) do
    {
      cy * cz, sx * sy + cx * cy * sz, cx * sy - sx * cy * sz, 0.0,
      -sz, cx * cz, sx * cz, 0.0,
      sy * cz, sx * cy - cx * sy * sz, cx * cy + sx * sy * sz, 0.0,
      0.0, 0.0, 0.0, 1.0
    }
  end

  # YXZ rotation order: R = Rz(z) * Rx(x) * Ry(y)
  defp from_euler_yxz(cx, sx, cy, sy, cz, sz) do
    {
      cy * cz + sy * sx * sz, cx * sz, -sy * cz + cy * sx * sz, 0.0,
      -cy * sz + sy * sx * cz, cx * cz, sy * sz + cy * sx * cz, 0.0,
      sy * cx, -sx, cy * cx, 0.0,
      0.0, 0.0, 0.0, 1.0
    }
  end

  # YZX rotation order: R = Rx(x) * Rz(z) * Ry(y)
  defp from_euler_yzx(cx, sx, cy, sy, cz, sz) do
    {
      cy * cz, sz, -sy * cz, 0.0,
      -cx * cy * sz + sx * sy, cx * cz, cx * sy * sz + sx * cy, 0.0,
      sx * cy * sz + cx * sy, -sx * cz, -sx * sy * sz + cx * cy, 0.0,
      0.0, 0.0, 0.0, 1.0
    }
  end

  # ZXY rotation order: R = Ry(y) * Rx(x) * Rz(z)
  defp from_euler_zxy(cx, sx, cy, sy, cz, sz) do
    {
      cy * cz - sy * sx * sz, cy * sz + sy * sx * cz, -sy * cx, 0.0,
      -cx * sz, cx * cz, sx, 0.0,
      sy * cz + cy * sx * sz, sy * sz - cy * sx * cz, cy * cx, 0.0,
      0.0, 0.0, 0.0, 1.0
    }
  end

  # ZYX rotation order: R = Rx(x) * Ry(y) * Rz(z)
  defp from_euler_zyx(cx, sx, cy, sy, cz, sz) do
    {
      clean_float(cy * cz), clean_float(cy * sz), clean_float(-sy), 0.0,
      clean_float(sx * sy * cz - cx * sz), clean_float(sx * sy * sz + cx * cz), clean_float(sx * cy), 0.0,
      clean_float(cx * sy * cz + sx * sz), clean_float(cx * sy * sz - sx * cz), clean_float(cx * cy), 0.0,
      0.0, 0.0, 0.0, 1.0
    }
  end
end
