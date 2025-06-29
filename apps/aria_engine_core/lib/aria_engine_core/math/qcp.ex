defmodule AriaEngineCore.Math.QCP do
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
      iex> {:ok, {rotation, translation}} = AriaEngineCore.Math.QCP.weighted_superpose(moved, target, weights, true)
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

  alias AriaEngineCore.Math.{Vector3, Quaternion}

  @default_precision 1.0e-6
  @max_points 10_000
  @min_weight 1.0e-12
  @max_weight 1.0e12

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
      iex> {:ok, {rotation, _translation}} = AriaEngineCore.Math.QCP.weighted_superpose(moved, target, [], false)
      iex> {_, _, _, w} = rotation
      iex> abs(w - 0.7071067811865476) < 1.0e-10
      true

  """
  @spec weighted_superpose(point_set(), point_set(), weights(), boolean(), float()) :: qcp_result()
  def weighted_superpose(moved, target, weights \\ [], translate \\ true, precision \\ @default_precision) do
    with :ok <- validate_inputs(moved, target, weights),
         {:ok, qcp_state} <- initialize_qcp_state(moved, target, weights, translate, precision),
         {:ok, qcp_state} <- calculate_inner_product(qcp_state),
         {:ok, rotation} <- calculate_rotation(qcp_state),
         {:ok, translation} <- calculate_translation(qcp_state, rotation) do
      {:ok, {rotation, translation}}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Private functions for QCP algorithm implementation

  @spec validate_inputs(point_set(), point_set(), weights()) :: :ok | {:error, validation_error()}
  defp validate_inputs(moved, target, weights) do
    with :ok <- validate_point_sets(moved, target),
         :ok <- validate_weights(weights, length(moved)),
         :ok <- validate_numerical_stability(moved, target) do
      :ok
    end
  end

  @spec validate_point_sets(point_set(), point_set()) :: :ok | {:error, validation_error()}
  defp validate_point_sets(moved, target) do
    cond do
      length(moved) == 0 or length(target) == 0 ->
        {:error, :empty_point_sets}

      length(moved) != length(target) ->
        {:error, :mismatched_point_set_sizes}

      length(moved) > @max_points ->
        {:error, :too_many_points}

      not all_valid_vectors?(moved) or not all_valid_vectors?(target) ->
        {:error, :degenerate_points}

      true ->
        :ok
    end
  end

  @spec validate_weights(weights(), non_neg_integer()) :: :ok | {:error, validation_error()}
  defp validate_weights(weights, point_count) do
    cond do
      length(weights) > 0 and length(weights) != point_count ->
        {:error, :mismatched_weight_count}

      Enum.any?(weights, fn w -> w < 0.0 end) ->
        {:error, :negative_weights}

      Enum.any?(weights, fn w -> not is_finite_number?(w) end) ->
        {:error, :invalid_weights}

      Enum.any?(weights, fn w -> w > @max_weight end) ->
        {:error, :invalid_weights}

      Enum.all?(weights, fn w -> w < @min_weight end) and length(weights) > 0 ->
        {:error, :invalid_weights}

      true ->
        :ok
    end
  end

  @spec validate_numerical_stability(point_set(), point_set()) :: :ok | {:error, validation_error()}
  defp validate_numerical_stability(moved, target) do
    # Check for degenerate cases that could cause numerical instability
    moved_span = calculate_point_span(moved)
    target_span = calculate_point_span(target)

    cond do
      moved_span < 1.0e-12 and length(moved) > 1 ->
        {:error, :degenerate_points}

      target_span < 1.0e-12 and length(target) > 1 ->
        {:error, :degenerate_points}

      true ->
        :ok
    end
  end

  @spec all_valid_vectors?(point_set()) :: boolean()
  defp all_valid_vectors?(points) do
    Enum.all?(points, fn {x, y, z} ->
      is_finite_number?(x) and is_finite_number?(y) and is_finite_number?(z)
    end)
  end

  @spec is_finite_number?(number()) :: boolean()
  defp is_finite_number?(x) when is_number(x) do
    not (x != x or x == :infinity or x == :neg_infinity)
  end
  defp is_finite_number?(_), do: false

  @spec calculate_point_span(point_set()) :: float()
  defp calculate_point_span(points) when length(points) <= 1, do: 0.0
  defp calculate_point_span(points) do
    {min_x, max_x} = points |> Enum.map(fn {x, _, _} -> x end) |> Enum.min_max()
    {min_y, max_y} = points |> Enum.map(fn {_, y, _} -> y end) |> Enum.min_max()
    {min_z, max_z} = points |> Enum.map(fn {_, _, z} -> z end) |> Enum.min_max()

    max(max_x - min_x, max(max_y - min_y, max_z - min_z))
  end

  @spec initialize_qcp_state(point_set(), point_set(), weights(), boolean(), float()) ::
          {:ok, map()} | {:error, term()}
  defp initialize_qcp_state(moved, target, weights, translate, precision) do
    try do
      weights_normalized = normalize_weights(weights, length(moved))

      qcp_state = %{
        moved: moved,
        target: target,
        weights: weights_normalized,
        translate: translate,
        precision: max(precision, 1.0e-15),  # Ensure minimum precision
        moved_center: {0.0, 0.0, 0.0},
        target_center: {0.0, 0.0, 0.0},
        w_sum: 0.0,
        # Inner product matrix components
        sum_xx: 0.0, sum_xy: 0.0, sum_xz: 0.0,
        sum_yx: 0.0, sum_yy: 0.0, sum_yz: 0.0,
        sum_zx: 0.0, sum_zy: 0.0, sum_zz: 0.0,
        # Derived sums for characteristic polynomial
        sum_xx_plus_yy: 0.0, sum_xx_minus_yy: 0.0,
        sum_xy_plus_yx: 0.0, sum_xy_minus_yx: 0.0,
        sum_xz_plus_zx: 0.0, sum_xz_minus_zx: 0.0,
        sum_yz_plus_zy: 0.0, sum_yz_minus_zy: 0.0,
        max_eigenvalue: 0.0,
        # Robustness tracking
        numerical_warnings: []
      }

      if translate do
        {:ok, center_and_translate_points(qcp_state)}
      else
        w_sum = Enum.sum(weights_normalized)
        {:ok, %{qcp_state | w_sum: w_sum}}
      end
    rescue
      error -> {:error, {:initialization_failed, error}}
    end
  end

  @spec normalize_weights(weights(), non_neg_integer()) :: weights()
  defp normalize_weights([], point_count), do: List.duplicate(1.0, point_count)
  defp normalize_weights(weights, _point_count) do
    # Clamp weights to prevent numerical issues
    Enum.map(weights, fn w ->
      cond do
        w < @min_weight -> @min_weight
        w > @max_weight -> @max_weight
        true -> w
      end
    end)
  end

  @spec center_and_translate_points(map()) :: map()
  defp center_and_translate_points(qcp_state) do
    %{moved: moved, target: target, weights: weights} = qcp_state

    moved_center = calculate_weighted_center(moved, weights)
    target_center = calculate_weighted_center(target, weights)

    # Translate points to center around origin
    moved_centered = Enum.map(moved, fn point -> Vector3.sub(point, moved_center) end)
    target_centered = Enum.map(target, fn point -> Vector3.sub(point, target_center) end)

    w_sum = Enum.sum(weights)

    %{qcp_state |
      moved: moved_centered,
      target: target_centered,
      moved_center: moved_center,
      target_center: target_center,
      w_sum: w_sum
    }
  end

  @spec calculate_weighted_center([Vector3.t()], [float()]) :: Vector3.t()
  defp calculate_weighted_center(points, weights) do
    total_weight = Enum.sum(weights)

    if total_weight > @min_weight do
      weighted_sum = points
                     |> Enum.zip(weights)
                     |> Enum.reduce({0.0, 0.0, 0.0}, fn {point, weight}, acc ->
                       # Use robust addition to prevent overflow
                       scaled_point = Vector3.scale(point, weight)
                       Vector3.add(acc, scaled_point)
                     end)

      # Safeguard against division by very small numbers
      scale_factor = 1.0 / total_weight
      if abs(scale_factor) < @max_weight do
        Vector3.scale(weighted_sum, scale_factor)
      else
        # Fallback to geometric center if weights are degenerate
        geometric_center(points)
      end
    else
      # Fallback to geometric center if total weight is too small
      geometric_center(points)
    end
  end

  @spec geometric_center([Vector3.t()]) :: Vector3.t()
  defp geometric_center([]), do: {0.0, 0.0, 0.0}
  defp geometric_center(points) do
    count = length(points)
    sum = Enum.reduce(points, {0.0, 0.0, 0.0}, &Vector3.add/2)
    Vector3.scale(sum, 1.0 / count)
  end

  @spec calculate_inner_product(map()) :: {:ok, map()} | {:error, term()}
  defp calculate_inner_product(qcp_state) do
    %{moved: moved, target: target, weights: weights} = qcp_state

    # Initialize sums
    sums = Enum.zip([moved, target, weights])
           |> Enum.reduce(
             %{
               sum_xx: 0.0, sum_xy: 0.0, sum_xz: 0.0,
               sum_yx: 0.0, sum_yy: 0.0, sum_yz: 0.0,
               sum_zx: 0.0, sum_zy: 0.0, sum_zz: 0.0,
               sum_of_squares1: 0.0, sum_of_squares2: 0.0
             },
             fn {moved_point, target_point, weight}, acc ->
               # Apply weight to moved point
               weighted_moved = Vector3.scale(moved_point, weight)
               {wx, wy, wz} = weighted_moved
               {tx, ty, tz} = target_point

               # Calculate dot products for inner product matrix
               new_sums = %{
                 sum_xx: acc.sum_xx + wx * tx,
                 sum_xy: acc.sum_xy + wx * ty,
                 sum_xz: acc.sum_xz + wx * tz,
                 sum_yx: acc.sum_yx + wy * tx,
                 sum_yy: acc.sum_yy + wy * ty,
                 sum_yz: acc.sum_yz + wy * tz,
                 sum_zx: acc.sum_zx + wz * tx,
                 sum_zy: acc.sum_zy + wz * ty,
                 sum_zz: acc.sum_zz + wz * tz,
                 sum_of_squares1: acc.sum_of_squares1 + Vector3.dot(weighted_moved, moved_point),
                 sum_of_squares2: acc.sum_of_squares2 + weight * Vector3.dot(target_point, target_point)
               }

               new_sums
             end)

    # Calculate initial eigenvalue and derived sums
    initial_eigenvalue = (sums.sum_of_squares1 + sums.sum_of_squares2) * 0.5

    updated_state = %{qcp_state |
      sum_xx: sums.sum_xx, sum_xy: sums.sum_xy, sum_xz: sums.sum_xz,
      sum_yx: sums.sum_yx, sum_yy: sums.sum_yy, sum_yz: sums.sum_yz,
      sum_zx: sums.sum_zx, sum_zy: sums.sum_zy, sum_zz: sums.sum_zz,
      sum_xx_plus_yy: sums.sum_xx + sums.sum_yy,
      sum_xx_minus_yy: sums.sum_xx - sums.sum_yy,
      sum_xy_plus_yx: sums.sum_xy + sums.sum_yx,
      sum_xy_minus_yx: sums.sum_xy - sums.sum_yx,
      sum_xz_plus_zx: sums.sum_xz + sums.sum_zx,
      sum_xz_minus_zx: sums.sum_xz - sums.sum_zx,
      sum_yz_plus_zy: sums.sum_yz + sums.sum_zy,
      sum_yz_minus_zy: sums.sum_yz - sums.sum_zy,
      max_eigenvalue: initial_eigenvalue
    }

    {:ok, updated_state}
  end

  @spec calculate_rotation(map()) :: {:ok, Quaternion.t()} | {:error, term()}
  defp calculate_rotation(qcp_state) do
    %{moved: moved, target: target} = qcp_state

    cond do
      length(moved) == 1 ->
        calculate_single_point_rotation(hd(moved), hd(target))

      true ->
        calculate_multi_point_rotation(qcp_state)
    end
  end

  @spec calculate_single_point_rotation(Vector3.t(), Vector3.t()) :: {:ok, Quaternion.t()}
  defp calculate_single_point_rotation(moved_point, target_point) do
    u_length = Vector3.length(moved_point)
    v_length = Vector3.length(target_point)
    norm_product = u_length * v_length

    if norm_product == 0.0 do
      {:ok, {0.0, 0.0, 0.0, 1.0}}
    else
      dot = Vector3.dot(moved_point, target_point)

      if dot < ((2.0e-15 - 1.0) * norm_product) do
        # Vectors are nearly opposite - return 180-degree rotation around perpendicular axis
        {normalized, _} = Vector3.normalize(moved_point)
        {nx, ny, nz} = normalized
        rotation = {nx, ny, nz, 0.0}
        {normalized_rotation, _} = Quaternion.normalize(rotation)
        {:ok, normalized_rotation}
      else
        # Standard quaternion calculation for rotation between vectors
        q0 = :math.sqrt(0.5 * (1.0 + dot / norm_product))
        coeff = 1.0 / (2.0 * q0 * norm_product)
        cross = Vector3.cross(target_point, moved_point)
        {cx, cy, cz} = cross
        rotation = {coeff * cx, coeff * cy, coeff * cz, q0}
        {normalized_rotation, _} = Quaternion.normalize(rotation)
        {:ok, normalized_rotation}
      end
    end
  end

  @spec calculate_multi_point_rotation(map()) :: {:ok, Quaternion.t()} | {:error, term()}
  defp calculate_multi_point_rotation(qcp_state) do
    try do
      # Check for numerical stability before proceeding
      with :ok <- check_matrix_stability(qcp_state),
           {:ok, quaternion_components} <- calculate_quaternion_components(qcp_state),
           {:ok, normalized_quaternion} <- finalize_quaternion(quaternion_components, qcp_state.precision) do
        {:ok, normalized_quaternion}
      end
    rescue
      error -> {:error, {:quaternion_calculation_failed, error}}
    end
  end

  @spec check_matrix_stability(map()) :: :ok | {:error, term()}
  defp check_matrix_stability(qcp_state) do
    %{max_eigenvalue: max_eigenvalue, precision: precision} = qcp_state

    # Check for reasonable eigenvalue magnitude
    cond do
      not is_finite_number?(max_eigenvalue) ->
        {:error, :infinite_eigenvalue}

      abs(max_eigenvalue) > 1.0e12 ->
        {:error, :eigenvalue_too_large}

      abs(max_eigenvalue) < precision * 1000 ->
        {:error, :eigenvalue_too_small}

      true ->
        :ok
    end
  end

  @spec calculate_quaternion_components(map()) :: {:ok, {float(), float(), float(), float()}} | {:error, term()}
  defp calculate_quaternion_components(qcp_state) do
    %{
      sum_xz_minus_zx: sum_xz_minus_zx, sum_xy_minus_yx: sum_xy_minus_yx,
      sum_yz_minus_zy: sum_yz_minus_zy, sum_xx_minus_yy: sum_xx_minus_yy,
      sum_xy_plus_yx: sum_xy_plus_yx, sum_xz_plus_zx: sum_xz_plus_zx,
      sum_yy: sum_yy, sum_xx: sum_xx, sum_yz_plus_zy: sum_yz_plus_zy,
      sum_zz: sum_zz, sum_xx_plus_yy: sum_xx_plus_yy, max_eigenvalue: max_eigenvalue
    } = qcp_state

    # Build the 4x4 characteristic polynomial matrix elements
    a13 = -sum_xz_minus_zx
    a14 = sum_xy_minus_yx
    a21 = sum_yz_minus_zy
    a22 = sum_xx_minus_yy - sum_zz - max_eigenvalue
    a23 = sum_xy_plus_yx
    a24 = sum_xz_plus_zx
    a31 = a13
    a32 = a23
    a33 = sum_yy - sum_xx - sum_zz - max_eigenvalue
    a34 = sum_yz_plus_zy
    a41 = a14
    a42 = a24
    a43 = a34
    a44 = sum_zz - sum_xx_plus_yy - max_eigenvalue

    # Calculate 3x3 determinants for quaternion components with overflow checking
    determinants = [
      a33 * a44 - a43 * a34,  # a3344_4334
      a32 * a44 - a42 * a34,  # a3244_4234
      a32 * a43 - a42 * a33,  # a3243_4233
      a31 * a43 - a41 * a33,  # a3143_4133
      a31 * a44 - a41 * a34,  # a3144_4134
      a31 * a42 - a41 * a32   # a3142_4132
    ]

    # Check for numerical overflow in determinants
    if Enum.any?(determinants, fn d -> not is_finite_number?(d) end) do
      {:error, :determinant_overflow}
    else
      [a3344_4334, a3244_4234, a3243_4233, a3143_4133, a3144_4134, a3142_4132] = determinants

      # Calculate quaternion components with robust arithmetic
      quaternion_w = safe_multiply_add([{a22, a3344_4334}, {-a23, a3244_4234}, {a24, a3243_4233}])
      quaternion_x = safe_multiply_add([{a21, a3344_4334}, {-a23, a3144_4134}, {a24, a3143_4133}])
      quaternion_y = safe_multiply_add([{-a21, a3244_4234}, {a22, a3144_4134}, {-a24, a3142_4132}])
      quaternion_z = safe_multiply_add([{a21, a3243_4233}, {-a22, a3143_4133}, {a23, a3142_4132}])

      {:ok, {quaternion_w, quaternion_x, quaternion_y, quaternion_z}}
    end
  end

  @spec safe_multiply_add([{float(), float()}]) :: float()
  defp safe_multiply_add(terms) do
    Enum.reduce(terms, 0.0, fn {coeff, value}, acc ->
      product = coeff * value
      if is_finite_number?(product) do
        acc + product
      else
        acc  # Skip infinite/NaN terms
      end
    end)
  end

  @spec finalize_quaternion({float(), float(), float(), float()}, float()) :: {:ok, Quaternion.t()} | {:error, term()}
  defp finalize_quaternion({quaternion_w, quaternion_x, quaternion_y, quaternion_z}, precision) do
    # Check for degenerate quaternion components
    if Enum.all?([quaternion_w, quaternion_x, quaternion_y, quaternion_z], fn c -> abs(c) < precision end) do
      {:ok, {0.0, 0.0, 0.0, 1.0}}  # Identity quaternion
    else
      # Robust normalization approach
      components = [quaternion_w, quaternion_x, quaternion_y, quaternion_z]
      max_component = Enum.max_by(components, &abs/1)

      {norm_w, norm_x, norm_y, norm_z} =
        if abs(max_component) > 1.0e-12 do
          scale = 1.0 / max_component
          {quaternion_w * scale, quaternion_x * scale, quaternion_y * scale, quaternion_z * scale}
        else
          {quaternion_w, quaternion_x, quaternion_y, quaternion_z}
        end

      # Check final quaternion magnitude
      qsqr = norm_w * norm_w + norm_x * norm_x + norm_y * norm_y + norm_z * norm_z

      if qsqr < precision do
        {:ok, {0.0, 0.0, 0.0, 1.0}}
      else
        rotation = {norm_x, norm_y, norm_z, norm_w}
        case Quaternion.normalize(rotation) do
          {normalized_rotation, true} -> {:ok, normalized_rotation}
          {_, false} -> {:error, :quaternion_normalization_failed}
        end
      end
    end
  end

  @spec calculate_translation(map(), Quaternion.t()) :: {:ok, Vector3.t()}
  defp calculate_translation(qcp_state, rotation) do
    %{translate: translate, target_center: target_center, moved_center: moved_center} = qcp_state

    if translate do
      # Translation = target_center - rotation * moved_center
      rotated_moved_center = Quaternion.rotate_vector(rotation, moved_center)
      translation = Vector3.sub(target_center, rotated_moved_center)
      {:ok, translation}
    else
      {:ok, {0.0, 0.0, 0.0}}
    end
  end
end
