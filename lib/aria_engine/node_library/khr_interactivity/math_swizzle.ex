# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivity.MathSwizzle do
  @moduledoc """
  Swizzle operations for KHR_interactivity specification.
  Implements vector and matrix combine/extract operations.
  """

  alias StateV2

  # =============================================================================
  # Vector Combine Operations
  # =============================================================================

  @doc """
  Combine values into 2D vector.
  
  ## Parameters
  - state: Current state
  - [node_id, x, y]: Node ID and component values
  
  ## Returns
  Updated state with 2D vector
  """
  def combine2(state, [node_id, x, y]) do
    result = [x, y]
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  @doc """
  Combine values into 3D vector.
  
  ## Parameters
  - state: Current state
  - [node_id, x, y, z]: Node ID and component values
  
  ## Returns
  Updated state with 3D vector
  """
  def combine3(state, [node_id, x, y, z]) do
    result = [x, y, z]
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  @doc """
  Combine values into 4D vector.
  
  ## Parameters
  - state: Current state
  - [node_id, x, y, z, w]: Node ID and component values
  
  ## Returns
  Updated state with 4D vector
  """
  def combine4(state, [node_id, x, y, z, w]) do
    result = [x, y, z, w]
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  # =============================================================================
  # Vector Extract Operations
  # =============================================================================

  @doc """
  Extract 2D vector from larger vector.
  
  ## Parameters
  - state: Current state
  - [node_id, vector, start_index]: Node ID, source vector, and start index
  
  ## Returns
  Updated state with extracted 2D vector
  """
  def extract2(state, [node_id, vector, start_index]) when is_list(vector) and is_integer(start_index) do
    result = 
      if start_index >= 0 and start_index + 1 < length(vector) do
        [Enum.at(vector, start_index), Enum.at(vector, start_index + 1)]
      else
        [0.0, 0.0]
      end
    
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  @doc """
  Extract 3D vector from larger vector.
  
  ## Parameters
  - state: Current state
  - [node_id, vector, start_index]: Node ID, source vector, and start index
  
  ## Returns
  Updated state with extracted 3D vector
  """
  def extract3(state, [node_id, vector, start_index]) when is_list(vector) and is_integer(start_index) do
    result = 
      if start_index >= 0 and start_index + 2 < length(vector) do
        [
          Enum.at(vector, start_index),
          Enum.at(vector, start_index + 1),
          Enum.at(vector, start_index + 2)
        ]
      else
        [0.0, 0.0, 0.0]
      end
    
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  @doc """
  Extract 4D vector from larger vector.
  
  ## Parameters
  - state: Current state
  - [node_id, vector, start_index]: Node ID, source vector, and start index
  
  ## Returns
  Updated state with extracted 4D vector
  """
  def extract4(state, [node_id, vector, start_index]) when is_list(vector) and is_integer(start_index) do
    result = 
      if start_index >= 0 and start_index + 3 < length(vector) do
        [
          Enum.at(vector, start_index),
          Enum.at(vector, start_index + 1),
          Enum.at(vector, start_index + 2),
          Enum.at(vector, start_index + 3)
        ]
      else
        [0.0, 0.0, 0.0, 0.0]
      end
    
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  # =============================================================================
  # Matrix Combine Operations
  # =============================================================================

  @doc """
  Combine vectors into 2x2 matrix.
  
  ## Parameters
  - state: Current state
  - [node_id, row0, row1]: Node ID and row vectors
  
  ## Returns
  Updated state with 2x2 matrix
  """
  def combine2x2(state, [node_id, [r0c0, r0c1], [r1c0, r1c1]]) do
    result = [r0c0, r0c1, r1c0, r1c1]
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  @doc """
  Combine vectors into 3x3 matrix.
  
  ## Parameters
  - state: Current state
  - [node_id, row0, row1, row2]: Node ID and row vectors
  
  ## Returns
  Updated state with 3x3 matrix
  """
  def combine3x3(state, [node_id, [r0c0, r0c1, r0c2], [r1c0, r1c1, r1c2], [r2c0, r2c1, r2c2]]) do
    result = [r0c0, r0c1, r0c2, r1c0, r1c1, r1c2, r2c0, r2c1, r2c2]
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  @doc """
  Combine vectors into 4x4 matrix.
  
  ## Parameters
  - state: Current state
  - [node_id, row0, row1, row2, row3]: Node ID and row vectors
  
  ## Returns
  Updated state with 4x4 matrix
  """
  def combine4x4(state, [node_id, row0, row1, row2, row3]) do
    result = row0 ++ row1 ++ row2 ++ row3
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  # =============================================================================
  # Matrix Extract Operations
  # =============================================================================

  @doc """
  Extract 2x2 matrix from larger matrix.
  
  ## Parameters
  - state: Current state
  - [node_id, matrix, row_start, col_start]: Node ID, source matrix, start row, start column
  
  ## Returns
  Updated state with extracted 2x2 matrix
  """
  def extract2x2(state, [node_id, matrix, row_start, col_start]) when is_list(matrix) do
    matrix_size = determine_matrix_size(length(matrix))
    
    result = 
      if matrix_size >= 2 and row_start >= 0 and col_start >= 0 and 
         row_start + 1 < matrix_size and col_start + 1 < matrix_size do
        [
          Enum.at(matrix, row_start * matrix_size + col_start),
          Enum.at(matrix, row_start * matrix_size + col_start + 1),
          Enum.at(matrix, (row_start + 1) * matrix_size + col_start),
          Enum.at(matrix, (row_start + 1) * matrix_size + col_start + 1)
        ]
      else
        [1.0, 0.0, 0.0, 1.0]  # Identity 2x2
      end
    
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  @doc """
  Extract 3x3 matrix from larger matrix.
  
  ## Parameters
  - state: Current state
  - [node_id, matrix, row_start, col_start]: Node ID, source matrix, start row, start column
  
  ## Returns
  Updated state with extracted 3x3 matrix
  """
  def extract3x3(state, [node_id, matrix, row_start, col_start]) when is_list(matrix) do
    matrix_size = determine_matrix_size(length(matrix))
    
    result = 
      if matrix_size >= 3 and row_start >= 0 and col_start >= 0 and 
         row_start + 2 < matrix_size and col_start + 2 < matrix_size do
        for row <- 0..2, col <- 0..2 do
          Enum.at(matrix, (row_start + row) * matrix_size + (col_start + col))
        end
      else
        [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]  # Identity 3x3
      end
    
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  @doc """
  Extract 4x4 matrix from larger matrix (or return as-is if already 4x4).
  
  ## Parameters
  - state: Current state
  - [node_id, matrix, row_start, col_start]: Node ID, source matrix, start row, start column
  
  ## Returns
  Updated state with extracted 4x4 matrix
  """
  def extract4x4(state, [node_id, matrix, row_start, col_start]) when is_list(matrix) do
    matrix_size = determine_matrix_size(length(matrix))
    
    result = 
      if matrix_size == 4 and row_start == 0 and col_start == 0 do
        matrix
      else
        # For now, return identity 4x4 for invalid extractions
        [
          1.0, 0.0, 0.0, 0.0,
          0.0, 1.0, 0.0, 0.0,
          0.0, 0.0, 1.0, 0.0,
          0.0, 0.0, 0.0, 1.0
        ]
      end
    
    StateV2.set_fact(state, Integer.to_string(node_id), "value", result)
  end

  # =============================================================================
  # Helper Functions
  # =============================================================================

  defp determine_matrix_size(element_count) do
    case element_count do
      4 -> 2   # 2x2
      9 -> 3   # 3x3
      16 -> 4  # 4x4
      _ -> 0   # Invalid
    end
  end

  # =============================================================================
  # Task Methods for HTN Planning
  # =============================================================================

  def combine2_task_method(_state, [node_id, x, y]) do
    [[:khr_math_combine2, node_id, x, y]]
  end

  def combine3_task_method(_state, [node_id, x, y, z]) do
    [[:khr_math_combine3, node_id, x, y, z]]
  end

  def combine4_task_method(_state, [node_id, x, y, z, w]) do
    [[:khr_math_combine4, node_id, x, y, z, w]]
  end

  def extract2_task_method(_state, [node_id, vector, start_index]) do
    [[:khr_math_extract2, node_id, vector, start_index]]
  end

  def extract3_task_method(_state, [node_id, vector, start_index]) do
    [[:khr_math_extract3, node_id, vector, start_index]]
  end

  def extract4_task_method(_state, [node_id, vector, start_index]) do
    [[:khr_math_extract4, node_id, vector, start_index]]
  end

  def combine2x2_task_method(_state, [node_id, row0, row1]) do
    [[:khr_math_combine2x2, node_id, row0, row1]]
  end

  def combine3x3_task_method(_state, [node_id, row0, row1, row2]) do
    [[:khr_math_combine3x3, node_id, row0, row1, row2]]
  end

  def combine4x4_task_method(_state, [node_id, row0, row1, row2, row3]) do
    [[:khr_math_combine4x4, node_id, row0, row1, row2, row3]]
  end

  def extract2x2_task_method(_state, [node_id, matrix, row_start, col_start]) do
    [[:khr_math_extract2x2, node_id, matrix, row_start, col_start]]
  end

  def extract3x3_task_method(_state, [node_id, matrix, row_start, col_start]) do
    [[:khr_math_extract3x3, node_id, matrix, row_start, col_start]]
  end

  def extract4x4_task_method(_state, [node_id, matrix, row_start, col_start]) do
    [[:khr_math_extract4x4, node_id, matrix, row_start, col_start]]
  end
end
