# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMath.QCP do
  @moduledoc """
  Implementation of the Quaternion-Based Characteristic Polynomial algorithm
  for RMSD and Superposition calculations.

  This module ports the C++ QCP algorithm from the many_bone_ik project to Elixir,
  providing optimal rotation quaternion calculation for aligning two point sets.

  ## Usage

  1. Create point sets as lists of Vector3 structs
  2. Optionally provide weighting factors [0.0 - 1.0] for each point
  3. Call `weighted_superpose/4` to get optimal rotation and translation

  ## Examples

      iex> moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
      iex> target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}]
      iex> weights = [1.0, 1.0]
      iex> {:ok, {rotation, translation}} = AriaMath.QCP.weighted_superpose(moved, target, weights, true)
      iex> {_, _, _, w} = rotation
      iex> abs(w - 0.7071067811865476) < 1.0e-10
      true

  ## Citations

  - Liu P, Agrafiotis DK, & Theobald DL (2011) Reply to comment on: "Fast determination of the optimal rotation matrix for macromolecular superpositions." Journal of Computational Chemistry 32(1):185-186.
  - Liu P, Agrafiotis DK, & Theobald DL (2010) "Fast determination of the optimal rotation matrix for macromolecular superpositions." Journal of Computational Chemistry 31(7):1561-1563.
  - Douglas L Theobald (2005) "Rapid calculation of RMSDs using a quaternion-based characteristic polynomial." Acta Crystallogr A 61(4):478-480.

  This is a port of the original C code QCProt 1.4 (2012, October 10) to Elixir.
  Original C source code available from http://theobald.brandeis.edu/qcp/

  Authors of original implementation:
  - Douglas L. Theobald, Department of Biochemistry, Brandeis University
  - Pu Liu, Johnson & Johnson Pharmaceutical Research and Development, L.L.C.
  - Peter Rose (adapted to Java)
  - Aleix Lafita (adapted to Java)
  - Eron Gjoni (adapted to EWB IK)
  - K. S. Ernest (iFire) Lee (adapted to ManyBoneIK)
  """

  alias AriaMath.{Vector3, Quaternion}
  alias AriaMath.QCP.{Validation, State, Rotation}

  @default_precision 1.0e-6

  @type point_set :: [Vector3.t()]
  @type weights :: [float()]
  @type qcp_result :: {:ok, {Quaternion.t(), Vector3.t()}} | {:error, term()}
  @type validation_error ::
    :empty_point_sets |
    :mismatched_point_set_sizes |
    :mismatched_weight_count |
    :negative_weights |
    :too_many_points |
    :invalid_weights |
    :degenerate_points |
    :numerical_instability

  @doc """
  Calculate optimal rotation and translation to align two point sets using QCP algorithm.

  ## Parameters

  - `moved` - List of Vector3 points to be transformed
  - `target` - List of Vector3 target points to align to
  - `weights` - List of weights for each point pair (or empty list for equal weights)
  - `translate` - Whether to calculate translation in addition to rotation

  ## Returns

  `{:ok, {rotation_quaternion, translation_vector}}` on success
  `{:error, reason}` on failure

  ## Examples

      iex> moved = [{1.0, 0.0, 0.0}]
      iex> target = [{0.0, 1.0, 0.0}]
      iex> {:ok, {rotation, _translation}} = AriaMath.QCP.weighted_superpose(moved, target, [], false)
      iex> {_, _, _, w} = rotation
      iex> abs(w - 0.7071067811865476) < 1.0e-10
      true

  """
  @spec weighted_superpose(point_set(), point_set(), weights(), boolean(), float()) :: qcp_result()
  def weighted_superpose(moved, target, weights \\ [], translate \\ true, precision \\ @default_precision) do
    with :ok <- Validation.validate_inputs(moved, target, weights),
         {:ok, qcp_state} <- State.initialize(moved, target, weights, translate, precision),
         {:ok, qcp_state} <- State.calculate_inner_product(qcp_state),
         {:ok, rotation} <- Rotation.calculate(qcp_state),
         {:ok, translation} <- State.calculate_translation(qcp_state, rotation) do
      {:ok, {rotation, translation}}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
