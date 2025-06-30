defmodule AriaQcp do
  @moduledoc """
  Quaternion-Based Characteristic Polynomial (QCP) algorithm for optimal superposition.

  This module provides a clean external API for the QCP algorithm implementation,
  which calculates optimal rotation and translation to align two point sets.

  ## Usage

  The primary function is `weighted_superpose/5` which takes two point sets
  and returns the optimal rotation quaternion and translation vector.

  ## Examples

      iex> moved = [{1.0, 0.0, 0.0}]
      iex> target = [{0.0, 1.0, 0.0}]
      iex> {:ok, {rotation, translation}} = AriaQcp.weighted_superpose(moved, target)
      iex> # Verify rotation is normalized
      iex> {x, y, z, w} = rotation
      iex> magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      iex> abs(magnitude - 1.0) < 1.0e-10
      true
      iex> # Verify transformation aligns the points
      iex> alias AriaMath.{Vector3, Quaternion}
      iex> rotated = Quaternion.rotate_vector(rotation, hd(moved))
      iex> transformed = Vector3.add(rotated, translation)
      iex> {tx, ty, tz} = transformed
      iex> {gx, gy, gz} = hd(target)
      iex> abs(tx - gx) < 1.0e-10 and abs(ty - gy) < 1.0e-10 and abs(tz - gz) < 1.0e-10
      true

  """

  alias AriaQcp.QCP

  @doc """
  Calculate optimal rotation and translation to align two point sets using QCP algorithm.

  ## Parameters

  - `moved` - List of Vector3 points to be transformed
  - `target` - List of Vector3 target points to align to
  - `weights` - List of weights for each point pair (or empty list for equal weights)
  - `translate` - Whether to calculate translation in addition to rotation
  - `precision` - Numerical precision for calculations

  ## Returns

  `{:ok, {rotation_quaternion, translation_vector}}` on success
  `{:error, reason}` on failure

  ## Examples

      iex> moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
      iex> target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}]
      iex> weights = [1.0, 1.0]
      iex> {:ok, {rotation, _translation}} = AriaQcp.weighted_superpose(moved, target, weights, true)
      iex> # Verify rotation is normalized
      iex> {x, y, z, w} = rotation
      iex> magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      iex> abs(magnitude - 1.0) < 1.0e-10
      true

  """
  defdelegate weighted_superpose(moved, target, weights \\ [], translate \\ true, precision \\ 1.0e-6), to: QCP

  @doc """
  Calculate optimal rotation to align two point sets (no translation).

  Convenience function that calls `weighted_superpose/5` with `translate: false`.

  ## Examples

      iex> moved = [{1.0, 0.0, 0.0}]
      iex> target = [{0.0, 1.0, 0.0}]
      iex> {:ok, {_rotation, translation}} = AriaQcp.rotation_only(moved, target)
      iex> translation
      {0.0, 0.0, 0.0}

  """
  def rotation_only(moved, target, weights \\ [], precision \\ 1.0e-6) do
    weighted_superpose(moved, target, weights, false, precision)
  end

  @doc """
  Calculate optimal rotation and translation with equal weights for all points.

  Convenience function that calls `weighted_superpose/5` with empty weights list.

  ## Examples

      iex> moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
      iex> target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}]
      iex> {:ok, {rotation, _translation}} = AriaQcp.superpose(moved, target)
      iex> # Verify rotation is normalized
      iex> {x, y, z, w} = rotation
      iex> magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      iex> abs(magnitude - 1.0) < 1.0e-10
      true

  """
  def superpose(moved, target, translate \\ true, precision \\ 1.0e-6) do
    weighted_superpose(moved, target, [], translate, precision)
  end
end
