# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaQcp.QCP do
  @moduledoc """
  Quaternion-based Characteristic Polynomial (QCP) algorithm for optimal superposition.

  This module implements the QCP algorithm for finding the optimal rotation and translation
  to align two sets of points. The algorithm is particularly useful for molecular structure
  alignment and other applications requiring optimal rigid body transformations.
  """

  alias AriaMath.{Vector3, Quaternion}
  alias AriaQcp.QCP.{Validation, State, SinglePoint, MultiPoint, Utils}

  @default_precision 1.0e-6

  @doc """
  Performs weighted superposition of two point sets using the QCP algorithm.

  ## Parameters

  - `moved`: List of 3D points to be transformed
  - `target`: List of 3D target points
  - `weights`: List of weights for each point pair (optional)
  - `translate`: Whether to include translation in the transformation
  - `precision`: Numerical precision for calculations (optional)

  ## Returns

  `{:ok, {rotation_quaternion, translation_vector}}` on success, or `{:error, reason}` on failure.

  ## Examples

      iex> moved = [{1.0, 0.0, 0.0}, {0.0, 1.0, 0.0}]
      iex> target = [{0.0, 1.0, 0.0}, {-1.0, 0.0, 0.0}]
      iex> weights = [1.0, 1.0]
      iex> {:ok, {rotation,_translation}} = AriaQcp.QCP.weighted_superpose(moved, target, weights, true)
      iex> # Verify rotation is normalized
      iex> {x, y, z, w} = rotation
      iex> magnitude = :math.sqrt(x*x + y*y + z*z + w*w)
      iex> abs(magnitude - 1.0) < 1.0e-10
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
  @spec weighted_superpose([Vector3.t()], [Vector3.t()], [float()], boolean(), float()) ::
          {:ok, {Quaternion.t(), Vector3.t()}} | {:error, term()}
  def weighted_superpose(moved, target, weights \\ [], translate \\ true, precision \\ @default_precision) do
    # Input validation
    with :ok <- Validation.validate_inputs(moved, target, weights),
         {:ok, qcp_state} <- State.initialize_qcp_state(moved, target, weights, translate, precision),
         {:ok, qcp_state_with_inner_product} <- State.calculate_inner_product(qcp_state),
         {:ok, rotation} <- calculate_rotation(qcp_state_with_inner_product),
         {:ok, translation} <- Utils.calculate_translation(qcp_state_with_inner_product, rotation) do
      {:ok, {rotation, translation}}
    end
  end

  # Calculate rotation quaternion
  defp calculate_rotation(qcp_state) do
    %{moved: moved, target: target} = qcp_state

    case {length(moved), length(target)} do
      {1, 1} ->
        # Single point case - use direct vector alignment
        [moved_point] = moved
        [target_point] = target

        # For single points, apply RMD flipping to match test expectations
        with {:ok, rotation} <- SinglePoint.calculate_single_point_rotation(moved_point, target_point) do
          final_rotation = Utils.apply_rmd_flipping_check(rotation)
          {:ok, final_rotation}
        end

      _ ->
        # Multi-point case - use full QCP algorithm with RMD flipping
        with {:ok, rotation} <- MultiPoint.calculate_multi_point_rotation(qcp_state) do
          final_rotation = Utils.apply_rmd_flipping_check(rotation)
          {:ok, final_rotation}
        end
    end
  end
end
