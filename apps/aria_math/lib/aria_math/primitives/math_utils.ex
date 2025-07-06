# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaMath.Primitives.MathUtils do
  @moduledoc """
  Mathematical utility functions for geometric primitive operations.

  This module provides common mathematical operations used in geometric
  calculations, including floating-point comparisons, clamping, interpolation,
  and angle conversions.
  """

  @doc """
  Check if two floating-point numbers are approximately equal within default tolerance.
  """
  @spec approximately_equal(float(), float()) :: boolean()
  def approximately_equal(a, b) do
    approximately_equal(a, b, 1.0e-6)
  end

  @doc """
  Check if two floating-point numbers are approximately equal within specified tolerance.
  """
  @spec approximately_equal(float(), float(), float()) :: boolean()
  def approximately_equal(a, b, tolerance) when is_number(a) and is_number(b) and is_number(tolerance) do
    abs(a - b) <= tolerance
  end

  @doc """
  Clamp a value between minimum and maximum bounds.
  """
  @spec clamp(number(), number(), number()) :: number()
  def clamp(value, min_val, max_val) when is_number(value) and is_number(min_val) and is_number(max_val) do
    cond do
      value < min_val -> min_val
      value > max_val -> max_val
      true -> value
    end
  end

  @doc """
  Linear interpolation between two values.
  """
  @spec lerp(float(), float(), float()) :: float()
  def lerp(a, b, t) when is_number(a) and is_number(b) and is_number(t) do
    a + (b - a) * t
  end

  @doc """
  Convert degrees to radians.
  """
  @spec deg_to_rad(float()) :: float()
  def deg_to_rad(degrees) when is_number(degrees) do
    degrees * :math.pi() / 180.0
  end

  @doc """
  Convert radians to degrees.
  """
  @spec rad_to_deg(float()) :: float()
  def rad_to_deg(radians) when is_number(radians) do
    radians * 180.0 / :math.pi()
  end

  @doc """
  IEEE-754 positive infinity constant.
  """
  @spec inf() :: float()
  def inf do
    :positive_infinity
  end

  @doc """
  Check if a float value is infinite (positive or negative).
  """
  @spec isinf_float(float() | atom()) :: boolean()
  def isinf_float(value) do
    value == :positive_infinity or value == :negative_infinity or
    (is_float(value) and not is_finite(value))
  end

  # Helper function to check if a float is finite
  defp is_finite(value) when is_float(value) do
    value == value and value != :positive_infinity and value != :negative_infinity
  end
  defp is_finite(_), do: true
end
