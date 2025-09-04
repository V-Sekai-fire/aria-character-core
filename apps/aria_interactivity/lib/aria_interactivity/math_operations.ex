defmodule AriaInteractivity.MathOperations do
  @moduledoc """
  glTF Math Operations Domain

  Implements math operations from glTF Interactivity Extension as planning domain actions.
  Supports arithmetic, comparison, trigonometric, and vector operations.

  Based on glTF Specification.adoc math nodes
  """

  use AriaCore.ActionAttributes

  # ============================================================================
  # ARITHMETIC OPERATIONS
  # ============================================================================

  # Addition
  @action true
  @spec add(AriaState.t(), [number]) :: {:ok, AriaState.t()} | {:error, atom()}
  def add(state, [a, b]) do
    result = a + b
    {:ok, AriaState.set_fact(state, "math_result", "current", result)}
  end

  @command true
  @spec add_command(AriaState.t(), [number]) :: {:ok, AriaState.t()} | {:error, atom()}
  def add_command(state, [a, b]) do
    try do
      result = a + b
      {:ok, AriaState.set_fact(state, "math_result", "current", result)}
    rescue
      _ -> {:error, :math_operation_failed}
    end
  end

  # Subtraction
  @action true
  @spec subtract(AriaState.t(), [number]) :: {:ok, AriaState.t()} | {:error, atom()}
  def subtract(state, [a, b]) do
    result = a - b
    {:ok, AriaState.set_fact(state, "math_result", "current", result)}
  end

  @command true
  @spec subtract_command(AriaState.t(), [number]) :: {:ok, AriaState.t()} | {:error, atom()}
  def subtract_command(state, [a, b]) do
    try do
      result = a - b
      {:ok, AriaState.set_fact(state, "math_result", "current", result)}
    rescue
      _ -> {:error, :math_operation_failed}
    end
  end

  # Multiplication
  @action true
  @spec multiply(AriaState.t(), [number]) :: {:ok, AriaState.t()} | {:error, atom()}
  def multiply(state, [a, b]) do
    result = a * b
    {:ok, AriaState.set_fact(state, "math_result", "current", result)}
  end

  @command true
  @spec multiply_command(AriaState.t(), [number]) :: {:ok, AriaState.t()} | {:error, atom()}
  def multiply_command(state, [a, b]) do
    try do
      result = a * b
      {:ok, AriaState.set_fact(state, "math_result", "current", result)}
    rescue
      _ -> {:error, :math_operation_failed}
    end
  end

  # Division
  @action true
  @spec divide(AriaState.t(), [number]) :: {:ok, AriaState.t()} | {:error, atom()}
  def divide(state, [a, b]) do
    if b == 0 do
      {:error, :division_by_zero}
    else
      result = a / b
      {:ok, AriaState.set_fact(state, "math_result", "current", result)}
    end
  end

  @command true
  @spec divide_command(AriaState.t(), [number]) :: {:ok, AriaState.t()} | {:error, atom()}
  def divide_command(state, [a, b]) do
    try do
      if b == 0 do
        {:error, :division_by_zero}
      else
        result = a / b
        {:ok, AriaState.set_fact(state, "math_result", "current", result)}
      end
    rescue
      _ -> {:error, :math_operation_failed}
    end
  end

  # ============================================================================
  # COMPARISON OPERATIONS
  # ============================================================================

  # Equality
  @action true
  @spec equal(AriaState.t(), [number]) :: {:ok, AriaState.t()} | {:error, atom()}
  def equal(state, [a, b]) do
    result = a == b
    {:ok, AriaState.set_fact(state, "comparison_result", "current", result)}
  end

  # Less Than
  @action true
  @spec less_than(AriaState.t(), [number]) :: {:ok, AriaState.t()} | {:error, atom()}
  def less_than(state, [a, b]) do
    result = a < b
    {:ok, AriaState.set_fact(state, "comparison_result", "current", result)}
  end

  # Greater Than
  @action true
  @spec greater_than(AriaState.t(), [number]) :: {:ok, AriaState.t()} | {:error, atom()}
  def greater_than(state, [a, b]) do
    result = a > b
    {:ok, AriaState.set_fact(state, "comparison_result", "current", result)}
  end

  # ============================================================================
  # TRIGONOMETRIC OPERATIONS
  # ============================================================================

  # Sine
  @action true
  @spec sine(AriaState.t(), [number]) :: {:ok, AriaState.t()} | {:error, atom()}
  def sine(state, [angle]) do
    result = :math.sin(angle)
    {:ok, AriaState.set_fact(state, "trig_result", "current", result)}
  end

  # Cosine
  @action true
  @spec cosine(AriaState.t(), [number]) :: {:ok, AriaState.t()} | {:error, atom()}
  def cosine(state, [angle]) do
    result = :math.cos(angle)
    {:ok, AriaState.set_fact(state, "trig_result", "current", result)}
  end

  # ============================================================================
  # VECTOR OPERATIONS
  # ============================================================================

  # Vector Addition
  @action true
  @spec vector_add(AriaState.t(), [list()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def vector_add(state, [vec1, vec2]) do
    result = Enum.zip(vec1, vec2) |> Enum.map(fn {a, b} -> a + b end)
    {:ok, AriaState.set_fact(state, "vector_result", "current", result)}
  end

  # Vector Dot Product
  @action true
  @spec vector_dot(AriaState.t(), [list()]) :: {:ok, AriaState.t()} | {:error, atom()}
  def vector_dot(state, [vec1, vec2]) do
    result = Enum.zip(vec1, vec2) |> Enum.reduce(0, fn {a, b}, acc -> acc + a * b end)
    {:ok, AriaState.set_fact(state, "scalar_result", "current", result)}
  end

  # ============================================================================
  # UTILITY FUNCTIONS
  # ============================================================================

  # Clamp value between min and max
  @action true
  @spec clamp(AriaState.t(), [number]) :: {:ok, AriaState.t()} | {:error, atom()}
  def clamp(state, [value, min_val, max_val]) do
    result = max(min_val, min(max_val, value))
    {:ok, AriaState.set_fact(state, "clamped_result", "current", result)}
  end

  # Linear interpolation
  @action true
  @spec lerp(AriaState.t(), [number]) :: {:ok, AriaState.t()} | {:error, atom()}
  def lerp(state, [a, b, t]) do
    result = a + (b - a) * t
    {:ok, AriaState.set_fact(state, "lerp_result", "current", result)}
  end
end
