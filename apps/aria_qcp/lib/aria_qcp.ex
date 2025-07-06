# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

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

  ### Basic Rotation-Only Alignment

      iex> moved = [{1.0, 0.0, 0.0}]
      iex> target = [{0.0, 1.0, 0.0}]
      iex> {:ok, {_rotation, translation}} = AriaQcp.rotation_only(moved, target)
      iex> translation
      {0.0, 0.0, 0.0}

  ### Medical Robotics: Tool Orientation Without Position Change

      iex> # Rotate surgical tool orientation while keeping position fixed
      iex> tool_tip = [{0.0, 0.0, 5.0}]  # 5cm tool length
      iex> desired_orientation = [{3.536, 0.0, 3.536}]  # 45° rotation
      iex> {:ok, {rotation, translation}} = AriaQcp.rotation_only(tool_tip, desired_orientation)
      iex> # Verify no translation applied
      iex> {tx, ty, tz} = translation
      iex> abs(tx) < 1.0e-10 and abs(ty) < 1.0e-10 and abs(tz) < 1.0e-10
      true
      iex> # Verify rotation is normalized
      iex> {x, y, z, w} = rotation
      iex> magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      iex> abs(magnitude - 1.0) < 1.0e-10
      true

  ### Molecular Biology: Backbone Orientation Alignment

      iex> # Align protein backbone direction without changing center of mass
      iex> backbone_vector = [{0.0, 1.0, 0.0}]
      iex> target_direction = [{0.707, 0.707, 0.0}]  # 45° rotation in XY plane
      iex> {:ok, {rotation, translation}} = AriaQcp.rotation_only(backbone_vector, target_direction)
      iex> # Translation should be zero for rotation-only
      iex> translation
      {0.0, 0.0, 0.0}
      iex> # Verify rotation magnitude
      iex> {rx, ry, rz, rw} = rotation
      iex> magnitude = :math.sqrt(rx*rx + ry*ry + rz*rz + rw*rw)
      iex> abs(magnitude - 1.0) < 1.0e-10
      true

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

  # Nx tensor integration functions

  @doc """
  Convert multiple point clouds to tensor format for batch processing.

  ## Examples

      moved_clouds = [
        [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}],
        [{2.0, 0.0, 0.0}, {0.0, 2.0, 0.0}]
      ]
      target_clouds = [
        [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}],
        [{0.0, 2.0, 0.0}, {-2.0, 0.0, 0.0}]
      ]
      {moved_tensor, target_tensor} = AriaQcp.point_clouds_to_tensors_nx(moved_clouds, target_clouds)
  """
  defdelegate point_clouds_to_tensors_nx(moved_clouds, target_clouds), to: AriaQcp.Tensor, as: :point_clouds_to_tensors

  @doc """
  Convert tensor results back to list format.

  ## Examples

      {rotations_list, translations_list} = AriaQcp.tensors_to_results_nx(rotations, translations)
  """
  defdelegate tensors_to_results_nx(rotations, translations), to: AriaQcp.Tensor, as: :tensors_to_results

  @doc """
  Perform batch superposition of multiple point cloud pairs.

  ## Examples

      # Process 100 protein structures simultaneously
      results = AriaQcp.batch_superpose_nx(moved_tensor, target_tensor)
  """
  defdelegate batch_superpose_nx(moved_tensor, target_tensor, opts \\ []), to: AriaQcp.Tensor, as: :batch_superpose

  @doc """
  Apply rotations and translations to multiple point clouds.

  ## Examples

      transformed_clouds = AriaQcp.apply_transformations_batch_nx(point_clouds, rotations, translations)
  """
  defdelegate apply_transformations_batch_nx(point_clouds, rotations, translations), to: AriaQcp.Tensor, as: :apply_transformations_batch

  @doc """
  Calculate RMSD (Root Mean Square Deviation) for multiple alignments.

  ## Examples

      rmsd_values = AriaQcp.calculate_rmsd_batch_nx(moved, target, rotations)
  """
  defdelegate calculate_rmsd_batch_nx(moved_points, target_points, rotations), to: AriaQcp.Tensor, as: :calculate_rmsd_batch

  @doc """
  Generate multiple random point cloud pairs for testing.

  ## Examples

      {moved_clouds, target_clouds} = AriaQcp.generate_test_data_nx(10, 50)
      # 10 pairs of point clouds, each with 50 points
  """
  defdelegate generate_test_data_nx(num_pairs, points_per_cloud, opts \\ []), to: AriaQcp.Tensor, as: :generate_test_data

  @doc """
  Validate batch processing results.

  ## Examples

      validation_results = AriaQcp.validate_batch_results_nx(results)
  """
  defdelegate validate_batch_results_nx(results), to: AriaQcp.Tensor, as: :validate_batch_results

  @doc """
  Batch process weights for multiple point cloud pairs.

  ## Examples

      weighted_clouds = AriaQcp.apply_weights_batch_nx(point_clouds, weights)
  """
  defdelegate apply_weights_batch_nx(point_clouds, weights), to: AriaQcp.Tensor, as: :apply_weights_batch

  @doc """
  Calculate characteristic polynomial eigenvalues for batch QCP processing.

  ## Examples

      eigenvalues = AriaQcp.calculate_eigenvalues_batch_nx(covariance_matrices)
  """
  defdelegate calculate_eigenvalues_batch_nx(covariance_matrices), to: AriaQcp.Tensor, as: :calculate_eigenvalues_batch
end
