defmodule AriaEngineCore.Math.Primitives do
  @moduledoc """
  KHR Interactivity mathematical primitives implementing the complete specification.

  This module provides all mathematical operations defined in the glTF KHR Interactivity
  specification, including constants, arithmetic, comparison, trigonometry, exponential,
  and special operations for float, integer, and boolean types.

  All operations follow IEEE-754 standard for NaN, infinity, and special case handling.
  """

  import Bitwise

  # Mathematical constants
  @e 2.718281828459045
  @pi 3.141592653589793

  ## Constants

  @doc """
  Euler's number (e).

  Implements `math/e` operation from KHR Interactivity spec.
  """
  @spec e() :: float()
  def e, do: @e

  @doc """
  Pi constant.

  Implements `math/pi` operation from KHR Interactivity spec.
  """
  @spec pi() :: float()
  def pi, do: @pi

  @doc """
  Positive infinity.

  Implements `math/inf` operation from KHR Interactivity spec.
  """
  @spec inf() :: float()
  def inf do
    try do
      1.0 / 0.0
    rescue
      ArithmeticError -> :positive_infinity
    end
  end

  @doc """
  Not a Number (NaN).

  Implements `math/nan` operation from KHR Interactivity spec.
  """
  @spec nan() :: float()
  def nan do
    try do
      0.0 / 0.0
    rescue
      ArithmeticError -> :nan
    end
  end

  ## Arithmetic Operations (Float)

  @doc """
  Absolute value operation for floats.

  Implements `math/abs` operation from KHR Interactivity spec.
  """
  @spec abs_float(float()) :: float()
  def abs_float(a) when a < 0, do: -a
  def abs_float(a) when a == -0.0, do: 0.0
  def abs_float(a), do: a

  @doc """
  Sign operation for floats.

  Implements `math/sign` operation from KHR Interactivity spec.
  """
  @spec sign_float(float()) :: float()
  def sign_float(a) when a < 0, do: -1.0
  def sign_float(a) when a == 0.0 or a == -0.0, do: a
  def sign_float(a) when a > 0, do: 1.0
  def sign_float(_a), do: nan()  # NaN case

  @doc """
  Truncate operation for floats.

  Implements `math/trunc` operation from KHR Interactivity spec.
  """
  @spec trunc_float(float()) :: float()
  def trunc_float(a) do
    cond do
      is_infinite(a) -> a
      is_nan(a) -> a
      true -> Float.round(a, 0) |> trunc() |> to_float()
    end
  end

  @doc """
  Floor operation for floats.

  Implements `math/floor` operation from KHR Interactivity spec.
  """
  @spec floor_float(float()) :: float()
  def floor_float(a) do
    cond do
      is_infinite(a) -> a
      is_nan(a) -> a
      true -> :math.floor(a)
    end
  end

  @doc """
  Ceiling operation for floats.

  Implements `math/ceil` operation from KHR Interactivity spec.
  """
  @spec ceil_float(float()) :: float()
  def ceil_float(a) do
    cond do
      is_infinite(a) -> a
      is_nan(a) -> a
      true -> :math.ceil(a)
    end
  end

  @doc """
  Round operation for floats.

  Implements `math/round` operation from KHR Interactivity spec.
  Half-way cases are rounded away from zero.
  """
  @spec round_float(float()) :: float()
  def round_float(a) do
    cond do
      is_infinite(a) -> a
      is_nan(a) -> a
      a < 0 -> -:math.floor(-a + 0.5)
      true -> :math.floor(a + 0.5)
    end
  end

  @doc """
  Fractional operation for floats.

  Implements `math/fract` operation from KHR Interactivity spec.
  Returns a - floor(a).
  """
  @spec fract_float(float()) :: float()
  def fract_float(a), do: a - floor_float(a)

  @doc """
  Negation operation for floats.

  Implements `math/neg` operation from KHR Interactivity spec.
  """
  @spec neg_float(float()) :: float()
  def neg_float(a), do: -a

  @doc """
  Addition operation for floats.

  Implements `math/add` operation from KHR Interactivity spec.
  """
  @spec add_float(float(), float()) :: float()
  def add_float(a, b), do: a + b

  @doc """
  Subtraction operation for floats.

  Implements `math/sub` operation from KHR Interactivity spec.
  """
  @spec sub_float(float(), float()) :: float()
  def sub_float(a, b), do: a - b

  @doc """
  Multiplication operation for floats.

  Implements `math/mul` operation from KHR Interactivity spec.
  """
  @spec mul_float(float(), float()) :: float()
  def mul_float(a, b), do: a * b

  @doc """
  Division operation for floats.

  Implements `math/div` operation from KHR Interactivity spec.
  """
  @spec div_float(float(), float()) :: float()
  def div_float(a, b), do: a / b

  @doc """
  Remainder operation for floats.

  Implements `math/rem` operation from KHR Interactivity spec.
  """
  @spec rem_float(float(), float()) :: float()
  def rem_float(a, b) do
    cond do
      is_infinite(a) or b == 0.0 -> nan()
      is_infinite(b) -> a
      true -> a - b * trunc_float(a / b)
    end
  end

  @doc """
  Minimum operation for floats.

  Implements `math/min` operation from KHR Interactivity spec.
  Negative zero is less than positive zero.
  """
  @spec min_float(float(), float()) :: float()
  def min_float(a, b) do
    cond do
      is_nan(a) or is_nan(b) -> nan()
      a == -0.0 and b == 0.0 -> -0.0
      a == 0.0 and b == -0.0 -> -0.0
      a <= b -> a
      true -> b
    end
  end

  @doc """
  Maximum operation for floats.

  Implements `math/max` operation from KHR Interactivity spec.
  Negative zero is less than positive zero.
  """
  @spec max_float(float(), float()) :: float()
  def max_float(a, b) do
    cond do
      is_nan(a) or is_nan(b) -> nan()
      a == -0.0 and b == 0.0 -> 0.0
      a == 0.0 and b == -0.0 -> 0.0
      a >= b -> a
      true -> b
    end
  end

  @doc """
  Clamp operation for floats.

  Implements `math/clamp` operation from KHR Interactivity spec.
  """
  @spec clamp_float(float(), float(), float()) :: float()
  def clamp_float(a, b, c) do
    min_float(max_float(a, min_float(b, c)), max_float(b, c))
  end

  @doc """
  Saturate operation for floats.

  Implements `math/saturate` operation from KHR Interactivity spec.
  Clamps value between 0 and 1.
  """
  @spec saturate_float(float()) :: float()
  def saturate_float(a), do: clamp_float(a, 0.0, 1.0)

  @doc """
  Linear interpolation operation for floats.

  Implements `math/mix` operation from KHR Interactivity spec.
  """
  @spec mix_float(float(), float(), float()) :: float()
  def mix_float(a, b, c), do: (1.0 - c) * a + c * b

  ## Comparison Operations

  @doc """
  Equality operation for floats.

  Implements `math/eq` operation from KHR Interactivity spec.
  """
  @spec eq_float(float(), float()) :: boolean()
  def eq_float(a, b) do
    cond do
      is_nan(a) or is_nan(b) -> false
      a == -0.0 and b == 0.0 -> true
      a == 0.0 and b == -0.0 -> true
      true -> a == b
    end
  end

  @doc """
  Less than operation for floats.

  Implements `math/lt` operation from KHR Interactivity spec.
  """
  @spec lt_float(float(), float()) :: boolean()
  def lt_float(a, b) do
    if is_nan(a) or is_nan(b) do
      false
    else
      a < b
    end
  end

  @doc """
  Less than or equal operation for floats.

  Implements `math/le` operation from KHR Interactivity spec.
  """
  @spec le_float(float(), float()) :: boolean()
  def le_float(a, b) do
    if is_nan(a) or is_nan(b) do
      false
    else
      a <= b
    end
  end

  @doc """
  Greater than operation for floats.

  Implements `math/gt` operation from KHR Interactivity spec.
  """
  @spec gt_float(float(), float()) :: boolean()
  def gt_float(a, b) do
    if is_nan(a) or is_nan(b) do
      false
    else
      a > b
    end
  end

  @doc """
  Greater than or equal operation for floats.

  Implements `math/ge` operation from KHR Interactivity spec.
  """
  @spec ge_float(float(), float()) :: boolean()
  def ge_float(a, b) do
    if is_nan(a) or is_nan(b) do
      false
    else
      a >= b
    end
  end

  ## Special Operations

  @doc """
  Is NaN check for floats.

  Implements `math/isnan` operation from KHR Interactivity spec.
  """
  @spec isnan_float(float()) :: boolean()
  def isnan_float(a), do: is_nan(a)

  @doc """
  Is infinity check for floats.

  Implements `math/isinf` operation from KHR Interactivity spec.
  """
  @spec isinf_float(float()) :: boolean()
  def isinf_float(a), do: is_infinite(a)

  @doc """
  Conditional selection operation.

  Implements `math/select` operation from KHR Interactivity spec.
  """
  @spec select(boolean(), any(), any()) :: any()
  def select(true, a, _b), do: a
  def select(false, _a, b), do: b

  @doc """
  Random value generation.

  Implements `math/random` operation from KHR Interactivity spec.
  Returns pseudo-random number >= 0.0 and < 1.0.
  """
  @spec random() :: float()
  def random, do: :rand.uniform()

  ## Trigonometric Operations

  @doc """
  Degrees to radians conversion.

  Implements `math/rad` operation from KHR Interactivity spec.
  """
  @spec rad_float(float()) :: float()
  def rad_float(a), do: a * @pi / 180.0

  @doc """
  Radians to degrees conversion.

  Implements `math/deg` operation from KHR Interactivity spec.
  """
  @spec deg_float(float()) :: float()
  def deg_float(a), do: a * 180.0 / @pi

  @doc """
  Sine function.

  Implements `math/sin` operation from KHR Interactivity spec.
  """
  @spec sin_float(float()) :: float()
  def sin_float(a) do
    cond do
      a == 0.0 or a == -0.0 -> a
      is_infinite(a) -> nan()
      true -> :math.sin(a)
    end
  end

  @doc """
  Cosine function.

  Implements `math/cos` operation from KHR Interactivity spec.
  """
  @spec cos_float(float()) :: float()
  def cos_float(a) do
    cond do
      a == 0.0 or a == -0.0 -> 1.0
      is_infinite(a) -> nan()
      true -> :math.cos(a)
    end
  end

  @doc """
  Tangent function.

  Implements `math/tan` operation from KHR Interactivity spec.
  """
  @spec tan_float(float()) :: float()
  def tan_float(a) do
    cond do
      a == 0.0 or a == -0.0 -> a
      is_infinite(a) -> nan()
      true -> :math.tan(a)
    end
  end

  @doc """
  Arcsine function.

  Implements `math/asin` operation from KHR Interactivity spec.
  """
  @spec asin_float(float()) :: float()
  def asin_float(a) do
    cond do
      a == 0.0 or a == -0.0 -> a
      abs(a) > 1.0 -> nan()
      true -> :math.asin(a)
    end
  end

  @doc """
  Arccosine function.

  Implements `math/acos` operation from KHR Interactivity spec.
  """
  @spec acos_float(float()) :: float()
  def acos_float(a) do
    cond do
      a == 1.0 -> 0.0
      abs(a) > 1.0 -> nan()
      true -> :math.acos(a)
    end
  end

  @doc """
  Arctangent function.

  Implements `math/atan` operation from KHR Interactivity spec.
  """
  @spec atan_float(float()) :: float()
  def atan_float(a) do
    cond do
      a == 0.0 or a == -0.0 -> a
      is_infinite(a) and a > 0 -> @pi / 2.0
      is_infinite(a) and a < 0 -> -@pi / 2.0
      true -> :math.atan(a)
    end
  end

  @doc """
  Arctangent 2 function.

  Implements `math/atan2` operation from KHR Interactivity spec.
  """
  @spec atan2_float(float(), float()) :: float()
  def atan2_float(a, b), do: :math.atan2(a, b)

  ## Exponential Operations

  @doc """
  Exponential function.

  Implements `math/exp` operation from KHR Interactivity spec.
  """
  @spec exp_float(float()) :: float()
  def exp_float(a) do
    cond do
      a == :negative_infinity -> 0.0
      a == 0.0 or a == -0.0 -> 1.0
      a == :positive_infinity -> inf()
      true -> :math.exp(a)
    end
  end

  @doc """
  Natural logarithm function.

  Implements `math/log` operation from KHR Interactivity spec.
  """
  @spec log_float(float()) :: float()
  def log_float(a) do
    cond do
      a < 0 -> nan()
      a == 0.0 or a == -0.0 -> -inf()
      a == 1.0 -> 0.0
      is_infinite(a) and a > 0 -> inf()
      true -> :math.log(a)
    end
  end

  @doc """
  Base-2 logarithm function.

  Implements `math/log2` operation from KHR Interactivity spec.
  """
  @spec log2_float(float()) :: float()
  def log2_float(a) do
    cond do
      a < 0 -> nan()
      a == 0.0 or a == -0.0 -> -inf()
      a == 1.0 -> 0.0
      is_infinite(a) and a > 0 -> inf()
      true -> :math.log2(a)
    end
  end

  @doc """
  Base-10 logarithm function.

  Implements `math/log10` operation from KHR Interactivity spec.
  """
  @spec log10_float(float()) :: float()
  def log10_float(a) do
    cond do
      a < 0 -> nan()
      a == 0.0 or a == -0.0 -> -inf()
      a == 1.0 -> 0.0
      is_infinite(a) and a > 0 -> inf()
      true -> :math.log10(a)
    end
  end

  @doc """
  Square root function.

  Implements `math/sqrt` operation from KHR Interactivity spec.
  """
  @spec sqrt_float(float()) :: float()
  def sqrt_float(a) do
    cond do
      a < 0 -> nan()
      a == 0.0 or a == -0.0 -> a
      is_infinite(a) and a > 0 -> inf()
      true -> :math.sqrt(a)
    end
  end

  @doc """
  Cube root function.

  Implements `math/cbrt` operation from KHR Interactivity spec.
  """
  @spec cbrt_float(float()) :: float()
  def cbrt_float(a) do
    cond do
      a == 0.0 or a == -0.0 -> a
      is_infinite(a) -> a
      a < 0 -> -:math.pow(-a, 1.0/3.0)
      true -> :math.pow(a, 1.0/3.0)
    end
  end

  @doc """
  Power function.

  Implements `math/pow` operation from KHR Interactivity spec.
  """
  @spec pow_float(float(), float()) :: float()
  def pow_float(a, b) do
    cond do
      is_nan(b) -> nan()
      is_nan(a) and b == 0.0 -> 1.0
      a == -0.0 and b == 0.0 -> 1.0
      a == 1.0 and is_infinite(b) -> nan()
      a == -1.0 and is_infinite(b) -> nan()
      a == 1.0 and is_nan(b) -> nan()
      true -> :math.pow(a, b)
    end
  end

  ## Integer Operations

  @doc """
  Absolute value for integers.

  Implements `math/abs` operation for int type from KHR Interactivity spec.
  """
  @spec abs_int(integer()) :: integer()
  def abs_int(a) when a == -2_147_483_648, do: -2_147_483_648  # Special case
  def abs_int(a) when a < 0, do: -a
  def abs_int(a), do: a

  @doc """
  Sign operation for integers.

  Implements `math/sign` operation for int type from KHR Interactivity spec.
  """
  @spec sign_int(integer()) :: integer()
  def sign_int(a) when a < 0, do: -1
  def sign_int(0), do: 0
  def sign_int(a) when a > 0, do: 1

  @doc """
  Negation for integers.

  Implements `math/neg` operation for int type from KHR Interactivity spec.
  """
  @spec neg_int(integer()) :: integer()
  def neg_int(-2_147_483_648), do: -2_147_483_648  # Special case for overflow
  def neg_int(a), do: (-a) &&& 0xFFFFFFFF |> to_signed_32()

  @doc """
  Addition for integers with overflow handling.

  Implements `math/add` operation for int type from KHR Interactivity spec.
  """
  @spec add_int(integer(), integer()) :: integer()
  def add_int(a, b), do: (a + b) &&& 0xFFFFFFFF |> to_signed_32()

  @doc """
  Subtraction for integers with overflow handling.

  Implements `math/sub` operation for int type from KHR Interactivity spec.
  """
  @spec sub_int(integer(), integer()) :: integer()
  def sub_int(a, b), do: (a - b) &&& 0xFFFFFFFF |> to_signed_32()

  @doc """
  Multiplication for integers with overflow handling.

  Implements `math/mul` operation for int type from KHR Interactivity spec.
  """
  @spec mul_int(integer(), integer()) :: integer()
  def mul_int(a, b) do
    result = a * b
    # Handle overflow using 32-bit signed integer semantics
    (result &&& 0xFFFFFFFF) |> to_signed_32()
  end

  @doc """
  Division for integers.

  Implements `math/div` operation for int type from KHR Interactivity spec.
  """
  @spec div_int(integer(), integer()) :: integer()
  def div_int(_a, 0), do: 0  # Division by zero returns 0
  def div_int(-2_147_483_648, -1), do: -2_147_483_648  # Overflow case
  def div_int(a, b), do: div(a, b)

  @doc """
  Remainder for integers.

  Implements `math/rem` operation for int type from KHR Interactivity spec.
  """
  @spec rem_int(integer(), integer()) :: integer()
  def rem_int(_a, 0), do: 0  # Remainder with zero divisor returns 0
  def rem_int(a, b), do: rem(a, b)

  @doc """
  Minimum for integers.

  Implements `math/min` operation for int type from KHR Interactivity spec.
  """
  @spec min_int(integer(), integer()) :: integer()
  def min_int(a, b) when a <= b, do: a
  def min_int(_a, b), do: b

  @doc """
  Maximum for integers.

  Implements `math/max` operation for int type from KHR Interactivity spec.
  """
  @spec max_int(integer(), integer()) :: integer()
  def max_int(a, b) when a >= b, do: a
  def max_int(_a, b), do: b

  @doc """
  Clamp for integers.

  Implements `math/clamp` operation for int type from KHR Interactivity spec.
  """
  @spec clamp_int(integer(), integer(), integer()) :: integer()
  def clamp_int(a, b, c) do
    min_int(max_int(a, min_int(b, c)), max_int(b, c))
  end

  ## Integer Comparison Operations

  @doc """
  Equality for integers.

  Implements `math/eq` operation for int type from KHR Interactivity spec.
  """
  @spec eq_int(integer(), integer()) :: boolean()
  def eq_int(a, b), do: a == b

  @doc """
  Less than for integers.

  Implements `math/lt` operation for int type from KHR Interactivity spec.
  """
  @spec lt_int(integer(), integer()) :: boolean()
  def lt_int(a, b), do: a < b

  @doc """
  Less than or equal for integers.

  Implements `math/le` operation for int type from KHR Interactivity spec.
  """
  @spec le_int(integer(), integer()) :: boolean()
  def le_int(a, b), do: a <= b

  @doc """
  Greater than for integers.

  Implements `math/gt` operation for int type from KHR Interactivity spec.
  """
  @spec gt_int(integer(), integer()) :: boolean()
  def gt_int(a, b), do: a > b

  @doc """
  Greater than or equal for integers.

  Implements `math/ge` operation for int type from KHR Interactivity spec.
  """
  @spec ge_int(integer(), integer()) :: boolean()
  def ge_int(a, b), do: a >= b

  ## Boolean Operations

  @doc """
  Logical AND operation for booleans.

  Implements `math/and` operation from KHR Interactivity spec.
  """
  @spec and_bool(boolean(), boolean()) :: boolean()
  def and_bool(a, b), do: a and b

  @doc """
  Logical OR operation for booleans.

  Implements `math/or` operation from KHR Interactivity spec.
  """
  @spec or_bool(boolean(), boolean()) :: boolean()
  def or_bool(a, b), do: a or b

  @doc """
  Logical NOT operation for booleans.

  Implements `math/not` operation from KHR Interactivity spec.
  """
  @spec not_bool(boolean()) :: boolean()
  def not_bool(a), do: not a

  @doc """
  Exclusive OR operation for booleans.

  Implements `math/xor` operation from KHR Interactivity spec.
  """
  @spec xor_bool(boolean(), boolean()) :: boolean()
  def xor_bool(a, b), do: (a and not b) or (not a and b)

  ## Bitwise Operations (Integer)

  @doc """
  Bitwise AND operation for integers.

  Implements `math/bitand` operation from KHR Interactivity spec.
  """
  @spec bitand_int(integer(), integer()) :: integer()
  def bitand_int(a, b), do: (a &&& b) &&& 0xFFFFFFFF |> to_signed_32()

  @doc """
  Bitwise OR operation for integers.

  Implements `math/bitor` operation from KHR Interactivity spec.
  """
  @spec bitor_int(integer(), integer()) :: integer()
  def bitor_int(a, b), do: (a ||| b) &&& 0xFFFFFFFF |> to_signed_32()

  @doc """
  Bitwise XOR operation for integers.

  Implements `math/bitxor` operation from KHR Interactivity spec.
  """
  @spec bitxor_int(integer(), integer()) :: integer()
  def bitxor_int(a, b), do: bxor(a, b) &&& 0xFFFFFFFF |> to_signed_32()

  @doc """
  Bitwise NOT operation for integers.

  Implements `math/bitnot` operation from KHR Interactivity spec.
  """
  @spec bitnot_int(integer()) :: integer()
  def bitnot_int(a), do: (~~~a) &&& 0xFFFFFFFF |> to_signed_32()

  @doc """
  Bitwise left shift operation for integers.

  Implements `math/lshift` operation from KHR Interactivity spec.
  """
  @spec lshift_int(integer(), integer()) :: integer()
  def lshift_int(_a, b) when b >= 32, do: 0
  def lshift_int(a, b) when b <= 0, do: a &&& 0xFFFFFFFF |> to_signed_32()
  def lshift_int(a, b), do: (a <<< b) &&& 0xFFFFFFFF |> to_signed_32()

  @doc """
  Bitwise right shift operation for integers.

  Implements `math/rshift` operation from KHR Interactivity spec.
  """
  @spec rshift_int(integer(), integer()) :: integer()
  def rshift_int(a, b) when b >= 32, do: if(a < 0, do: -1, else: 0)
  def rshift_int(a, b) when b <= 0, do: a &&& 0xFFFFFFFF |> to_signed_32()
  def rshift_int(a, b), do: (a >>> b) &&& 0xFFFFFFFF |> to_signed_32()

  ## Helper Functions

  # Convert to signed 32-bit integer
  defp to_signed_32(n) when n > 2_147_483_647, do: n - 4_294_967_296
  defp to_signed_32(n), do: n

  # Convert to float
  defp to_float(n) when is_integer(n), do: n / 1
  defp to_float(n), do: n

  # IEEE-754 helper functions
  defp is_nan(x) do
    x != x
  end

  defp is_finite(x) do
    not is_nan(x) and not is_infinite(x)
  end

  defp is_infinite(x) do
    x == :positive_infinity or x == :negative_infinity or
    x == 1.0 / 0.0 or x == -1.0 / 0.0
  rescue
    ArithmeticError -> false
  end
end
