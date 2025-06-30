# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQcp do
  @moduledoc """
  Quaternion-Based Characteristic Polynomial (QCP) algorithm for optimal
  rotation and translation calculation between point sets.

  This app provides the QCP algorithm implementation for RMSD and superposition
  calculations, ported from the C++ QCP algorithm from the many_bone_ik project.

  ## Usage

  1. Create point sets as lists of Vector3 structs
  2. Optionally provide weighting factors [0.0 - 1.0] for each point
  3. Call `weighted_superpose/5` to get optimal rotation and translation

  ## Examples

      iex> moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
      iex> target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}]
      iex> weights = [1.0, 1.0]
      iex> {:ok, {rotation, translation}} = AriaQcp.weighted_superpose(moved, target, weights, true, 1.0e-6)
      iex> {_, _, _, w} = rotation
      iex> abs(w - 0.7071067811865476) < 1.0e-10
      true

  ## Citations

  - Liu P, Agrafiotis DK, & Theobald DL (2011) Reply to comment on: "Fast determination of the optimal rotation matrix for macromolecular superpositions." Journal of Computational Chemistry 32(1):185-186.
  - Liu P, Agrafiotis DK, & Theobald DL (2010) "Fast determination of the optimal rotation matrix for macromolecular superpositions." Journal of Computational Chemistry 31(7):1561-1563.
  - Douglas L Theobald (2005) "Rapid calculation of RMSDs using a quaternion-based characteristic polynomial." Acta Crystallogr A 61(4):478-480.
  """

  alias AriaMath.{Vector3, Quaternion}

  @type point_set :: [Vector3.t()]
  @type weights :: [float()]
  @type qcp_result :: {:ok, {Quaternion.t(), Vector3.t()}} | {:error, term()}

  @doc """
  Calculate optimal rotation and translation to align two point sets using QCP algorithm.

  ## Parameters

  - `moved` - List of Vector3 points to be transformed
  - `target` - List of Vector3 target points to align to
  - `weights` - List of weights for each point pair (or empty list for equal weights)
  - `translate` - Whether to calculate translation in addition to rotation
  - `precision` - Numerical precision for eigenvalue convergence

  ## Returns

  `{:ok, {rotation_quaternion, translation_vector}}` on success
  `{:error, reason}` on failure
  """
  @spec weighted_superpose(point_set(), point_set(), weights(), boolean(), float()) :: qcp_result()
  defdelegate weighted_superpose(moved, target, weights, translate, precision),
              to: AriaQcp.Core

  @doc """
  Calculate optimal rotation and translation between two point sets.

  Simplified interface that returns the rotation quaternion and translation vector.
  """
  @spec calculate(point_set(), point_set()) :: {:ok, {Quaternion.t(), Vector3.t(), float()}} | {:error, term()}
  defdelegate calculate(moved, target), to: AriaQcp.Core

  @doc """
  Apply rotation and translation transformation to a list of points.
  """
  @spec apply_transformation(point_set(), Quaternion.t(), Vector3.t()) :: point_set()
  defdelegate apply_transformation(points, rotation, translation), to: AriaQcp.Core

  @doc """
  Calculate the Root Mean Square Deviation (RMSD) between two point sets.
  """
  @spec rmsd(point_set(), point_set()) :: {:ok, float()} | {:error, term()}
  defdelegate rmsd(points_a, points_b), to: AriaQcp.Core
end
