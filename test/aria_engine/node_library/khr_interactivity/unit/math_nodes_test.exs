# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule NodeLibrary.KHRInteractivity.Unit.MathNodesTest do
  use ExUnit.Case, async: true
  
  alias NodeLibrary.KHRInteractivityDomain
  alias StateV2
  
  describe "math constants" do
    test "khr_math_e returns Euler's number" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_e(state, [0])
      
      assert StateV2.get_fact(result_state, "0", "value") == :math.exp(1)
      assert_in_delta StateV2.get_fact(result_state, "0", "value"), 2.718281828459045, 1.0e-15
    end
    
    test "khr_math_pi returns pi constant" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_pi(state, [1])
      
      assert StateV2.get_fact(result_state, "1", "value") == :math.pi()
      assert_in_delta StateV2.get_fact(result_state, "1", "value"), 3.141592653589793, 1.0e-15
    end
    
    test "khr_math_inf returns positive infinity" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_inf(state, [2])
      
      assert StateV2.get_fact(result_state, "2", "value") == :positive_infinity
    end
    
    test "khr_math_nan returns NaN" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_nan(state, [3])
      
      assert StateV2.get_fact(result_state, "3", "value") == :nan
    end
  end
  
  describe "math arithmetic - unary operations" do
    test "khr_math_abs with positive number" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_abs(state, [4, 5.5])
      
      assert StateV2.get_fact(result_state, "4", "value") == 5.5
    end
    
    test "khr_math_abs with negative number" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_abs(state, [5, -3.7])
      
      assert StateV2.get_fact(result_state, "5", "value") == 3.7
    end
    
    test "khr_math_abs with zero" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_abs(state, [6, 0])
      
      assert StateV2.get_fact(result_state, "6", "value") == 0
    end
    
    test "khr_math_sign with positive number" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_sign(state, [7, 42.5])
      
      assert StateV2.get_fact(result_state, "7", "value") == 1
    end
    
    test "khr_math_sign with negative number" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_sign(state, [8, -15.3])
      
      assert StateV2.get_fact(result_state, "8", "value") == -1
    end
    
    test "khr_math_sign with zero" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_sign(state, [9, 0])
      
      assert StateV2.get_fact(result_state, "9", "value") == 0
    end
    
    test "khr_math_neg with positive number" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_neg(state, [10, 7.2])
      
      assert StateV2.get_fact(result_state, "10", "value") == -7.2
    end
    
    test "khr_math_neg with negative number" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_neg(state, [11, -4.1])
      
      assert StateV2.get_fact(result_state, "11", "value") == 4.1
    end
    
    test "khr_math_floor with positive decimal" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_floor(state, [12, 3.7])
      
      assert StateV2.get_fact(result_state, "12", "value") == 3.0
    end
    
    test "khr_math_floor with negative decimal" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_floor(state, [13, -2.3])
      
      assert StateV2.get_fact(result_state, "13", "value") == -3.0
    end
    
    test "khr_math_ceil with positive decimal" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_ceil(state, [14, 2.1])
      
      assert StateV2.get_fact(result_state, "14", "value") == 3.0
    end
    
    test "khr_math_ceil with negative decimal" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_ceil(state, [15, -3.9])
      
      assert StateV2.get_fact(result_state, "15", "value") == -3.0
    end
    
    test "khr_math_round with positive half-up" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_round(state, [16, 2.5])
      
      assert StateV2.get_fact(result_state, "16", "value") == 3
    end
    
    test "khr_math_round with negative half-down" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_round(state, [17, -2.5])
      
      assert StateV2.get_fact(result_state, "17", "value") == -3
    end
    
    test "khr_math_trunc with positive decimal" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_trunc(state, [18, 3.9])
      
      assert StateV2.get_fact(result_state, "18", "value") == 3
    end
    
    test "khr_math_trunc with negative decimal" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_trunc(state, [19, -2.7])
      
      assert StateV2.get_fact(result_state, "19", "value") == -2
    end
    
    test "khr_math_fract with positive number" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_fract(state, [20, 3.7])
      
      assert_in_delta StateV2.get_fact(result_state, "20", "value"), 0.7, 1.0e-15
    end
    
    test "khr_math_fract with negative number" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_fract(state, [21, -2.3])
      
      assert_in_delta StateV2.get_fact(result_state, "21", "value"), 0.7, 1.0e-15
    end
    
    test "khr_math_saturate within range" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_saturate(state, [22, 0.7])
      
      assert StateV2.get_fact(result_state, "22", "value") == 0.7
    end
    
    test "khr_math_saturate above range" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_saturate(state, [23, 1.5])
      
      assert StateV2.get_fact(result_state, "23", "value") == 1.0
    end
    
    test "khr_math_saturate below range" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_saturate(state, [24, -0.3])
      
      assert StateV2.get_fact(result_state, "24", "value") == 0.0
    end
  end
  
  describe "math arithmetic - binary operations" do
    test "khr_math_add with two positive numbers" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_add(state, [25, 3.5, 2.1])
      
      assert_in_delta StateV2.get_fact(result_state, "25", "value"), 5.6, 1.0e-15
    end
    
    test "khr_math_add with negative numbers" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_add(state, [26, -2.5, -1.5])
      
      assert StateV2.get_fact(result_state, "26", "value") == -4.0
    end
    
    test "khr_math_sub basic subtraction" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_sub(state, [27, 7.5, 2.3])
      
      assert_in_delta StateV2.get_fact(result_state, "27", "value"), 5.2, 1.0e-15
    end
    
    test "khr_math_mul basic multiplication" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_mul(state, [28, 3.0, 4.0])
      
      assert StateV2.get_fact(result_state, "28", "value") == 12.0
    end
    
    test "khr_math_div basic division" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_div(state, [29, 10.0, 2.0])
      
      assert StateV2.get_fact(result_state, "29", "value") == 5.0
    end
    
    test "khr_math_div by zero with positive numerator" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_div(state, [30, 5.0, 0.0])
      
      assert StateV2.get_fact(result_state, "30", "value") == :positive_infinity
    end
    
    test "khr_math_div by zero with negative numerator" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_div(state, [31, -3.0, 0.0])
      
      assert StateV2.get_fact(result_state, "31", "value") == :negative_infinity
    end
    
    test "khr_math_div zero by zero" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_div(state, [32, 0.0, 0.0])
      
      assert StateV2.get_fact(result_state, "32", "value") == :nan
    end
    
    test "khr_math_rem basic remainder" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_rem(state, [33, 7.0, 3.0])
      
      assert_in_delta StateV2.get_fact(result_state, "33", "value"), 1.0, 1.0e-15
    end
    
    test "khr_math_rem with zero divisor" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_rem(state, [34, 5.0, 0.0])
      
      assert StateV2.get_fact(result_state, "34", "value") == :nan
    end
    
    test "khr_math_min with two different numbers" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_min(state, [35, 3.7, 2.1])
      
      assert StateV2.get_fact(result_state, "35", "value") == 2.1
    end
    
    test "khr_math_min with equal numbers" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_min(state, [36, 4.5, 4.5])
      
      assert StateV2.get_fact(result_state, "36", "value") == 4.5
    end
    
    test "khr_math_max with two different numbers" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_max(state, [37, 3.7, 2.1])
      
      assert StateV2.get_fact(result_state, "37", "value") == 3.7
    end
    
    test "khr_math_max with equal numbers" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_max(state, [38, 6.2, 6.2])
      
      assert StateV2.get_fact(result_state, "38", "value") == 6.2
    end
    
    test "khr_math_mix basic interpolation" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_mix(state, [39, 0.0, 10.0, 0.3])
      
      assert StateV2.get_fact(result_state, "39", "value") == 3.0
    end
    
    test "khr_math_mix at endpoints" do
      state = StateV2.new()
      result_state_0 = KHRInteractivityDomain.math_mix(state, [40, 5.0, 15.0, 0.0])
      result_state_1 = KHRInteractivityDomain.math_mix(state, [41, 5.0, 15.0, 1.0])
      
      assert StateV2.get_fact(result_state_0, "40", "value") == 5.0
      assert StateV2.get_fact(result_state_1, "41", "value") == 15.0
    end
  end
  
  describe "math arithmetic - ternary operations" do
    test "khr_math_clamp within bounds" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_clamp(state, [42, 5.0, 2.0, 8.0])
      
      assert StateV2.get_fact(result_state, "42", "value") == 5.0
    end
    
    test "khr_math_clamp below minimum" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_clamp(state, [43, 1.0, 3.0, 7.0])
      
      assert StateV2.get_fact(result_state, "43", "value") == 3.0
    end
    
    test "khr_math_clamp above maximum" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_clamp(state, [44, 9.0, 2.0, 6.0])
      
      assert StateV2.get_fact(result_state, "44", "value") == 6.0
    end
    
    test "khr_math_clamp with reversed bounds" do
      state = StateV2.new()
      result_state = KHRInteractivityDomain.math_clamp(state, [45, 5.0, 8.0, 3.0])
      
      # According to KHR spec: min(max(a, min(b, c)), max(b, c))
      # min(max(5.0, min(8.0, 3.0)), max(8.0, 3.0))
      # min(max(5.0, 3.0), 8.0) = min(5.0, 8.0) = 5.0
      assert StateV2.get_fact(result_state, "45", "value") == 5.0
    end
  end
end
