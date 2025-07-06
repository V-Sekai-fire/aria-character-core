# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.API.Primitives do
  @moduledoc """
  Primitive operations for the AriaMath external API.

  This module contains all primitive mathematical operations and utilities
  for the AriaMath external API, keeping the main API module focused.
  """

  alias AriaMath.Primitives

  @doc """
  Compute the absolute value of a float.

  ## Examples

      iex> AriaMath.API.Primitives.abs_float(-5.0)
      5.0
  """
  def abs_float(x) when is_number(x), do: abs(x)

  @doc """
  Clamp a float value between minimum and maximum bounds.

  ## Examples

      iex> AriaMath.API.Primitives.clamp_float(5.0, 0.0, 10.0)
      5.0

      iex> AriaMath.API.Primitives.clamp_float(-1.0, 0.0, 10.0)
      0.0

      iex> AriaMath.API.Primitives.clamp_float(15.0, 0.0, 10.0)
      10.0
  """
  def clamp_float(value, min_val, max_val) when is_number(value) and is_number(min_val) and is_number(max_val) do
    cond do
      value < min_val -> min_val
      value > max_val -> max_val
      true -> value
    end
  end

  @doc """
  Check if two floating-point numbers are approximately equal.

  ## Examples

      iex> AriaMath.API.Primitives.approximately_equal(1.0, 1.0000001)
      true

      iex> AriaMath.API.Primitives.approximately_equal(1.0, 1.1)
      false
  """
  defdelegate approximately_equal(a, b), to: Primitives

  @doc """
  Check if two floating-point numbers are approximately equal with custom tolerance.

  ## Examples

      iex> AriaMath.API.Primitives.approximately_equal(1.0, 1.01, 0.1)
      true

      iex> AriaMath.API.Primitives.approximately_equal(1.0, 1.01, 0.001)
      false
  """
  defdelegate approximately_equal(a, b, tolerance), to: Primitives

  @doc """
  Clamp a value between minimum and maximum bounds.

  ## Examples

      iex> AriaMath.API.Primitives.clamp(5.0, 0.0, 10.0)
      5.0

      iex> AriaMath.API.Primitives.clamp(-1.0, 0.0, 10.0)
      0.0

      iex> AriaMath.API.Primitives.clamp(15.0, 0.0, 10.0)
      10.0
  """
  defdelegate clamp(value, min, max), to: Primitives

  @doc """
  Linear interpolation between two values.

  ## Examples

      iex> AriaMath.API.Primitives.lerp_scalar(0.0, 10.0, 0.5)
      5.0

      iex> AriaMath.API.Primitives.lerp_scalar(0.0, 10.0, 0.25)
      2.5
  """
  defdelegate lerp_scalar(a, b, t), to: Primitives, as: :lerp

  @doc """
  Convert degrees to radians.

  ## Examples

      iex> AriaMath.API.Primitives.deg_to_rad(180.0)
      3.141592653589793

      iex> AriaMath.API.Primitives.deg_to_rad(90.0)
      1.5707963267948966
  """
  defdelegate deg_to_rad(degrees), to: Primitives

  @doc """
  Convert radians to degrees.

  ## Examples

      iex> AriaMath.API.Primitives.rad_to_deg(:math.pi)
      180.0

      iex> AriaMath.API.Primitives.rad_to_deg(:math.pi / 2)
      90.0
  """
  defdelegate rad_to_deg(radians), to: Primitives

  @doc """
  Create a joint with the given options.

  ## Examples

      joint = AriaMath.API.Primitives.create_joint(%{})
  """
  def create_joint(_opts) do
    # Basic joint implementation - should be moved to AriaJoint app
    alias AriaMath.Matrix4
    %{
      id: make_ref(),
      transform: Matrix4.identity(),
      parent: nil,
      children: []
    }
  end
end
