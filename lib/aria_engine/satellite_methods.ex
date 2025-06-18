# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.SatelliteMethods do
  @moduledoc """
  Simulated method functions for the Satellite domain.
  """

  # (:method method0
  #   :parameters (?mdoatt_t_d_prev - image_direction ?mdoatt_t_s - satellite ?mdoatt_ti_d - image_direction ?mdoatt_ti_i - instrument ?mdoatt_ti_m - mode)
  #   :task (do_observation ?mdoatt_ti_d ?mdoatt_ti_m)
  #   :subtasks (and
  #    (task0 (activate_instrument ?mdoatt_t_s ?mdoatt_ti_i))
  #    (task1 (turn_to ?mdoatt_t_s ?mdoatt_ti_d ?mdoatt_t_d_prev))
  #    (task2 (take_image ?mdoatt_t_s ?mdoatt_ti_d ?mdoatt_ti_i ?mdoatt_ti_m))
  #   )
  # )
  def method0(args) do
    [_t_d_prev, t_s, ti_d, ti_i, ti_m] = args
    {:ok, [
      {:activate_instrument, [t_s, ti_i]},
      {:turn_to, [t_s, ti_d, :current_pointing]}, # Use a placeholder for current pointing
      {:take_image, [t_s, ti_d, ti_i, ti_m]}
    ]}
  end

  # (:method method1
  #   :parameters (?mdott_t_d_prev - direction ?mdott_t_s - satellite ?mdott_ti_d - image_direction ?mdott_ti_i - instrument ?mdott_ti_m - mode)
  #   :task (do_observation ?mdott_ti_d ?mdott_ti_m)
  #   :subtasks (and
  #    (task0 (turn_to ?mdott_t_s ?mdott_ti_d ?mdott_t_d_prev))
  #    (task1 (take_image ?mdott_t_s ?mdott_ti_d ?mdott_ti_i ?mdott_ti_m))
  #   )
  # )
  def method1(args) do
    [_t_d_prev, t_s, ti_d, ti_i, ti_m] = args
    {:ok, [
      {:turn_to, [t_s, ti_d, :current_pointing]}, # Use a placeholder for current pointing
      {:take_image, [t_s, ti_d, ti_i, ti_m]}
    ]}
  end

  # (:method method2
  #   :parameters (?mdoat_ti_d - image_direction ?mdoat_ti_i - instrument ?mdoat_ti_m - mode ?mdoat_ti_s - satellite)
  #   :task (do_observation ?mdoat_ti_d ?mdoat_ti_m)
  #   :subtasks (and
  #    (task0 (activate_instrument ?mdoat_ti_s ?mdoat_ti_i))
  #    (task1 (take_image ?mdoat_ti_s ?mdoat_ti_d ?mdoat_ti_i ?mdoat_ti_m))
  #   )
  # )
  def method2(args) do
    [ti_d, ti_i, ti_m, ti_s] = args
    {:ok, [
      {:activate_instrument, [ti_s, ti_i]},
      {:take_image, [ti_s, ti_d, ti_i, ti_m]}
    ]}
  end

  # (:method method3
  #   :parameters (?mdot_ti_d - image_direction ?mdot_ti_i - instrument ?mdot_ti_m - mode ?mdot_ti_s - satellite)
  #   :task (do_observation ?mdot_ti_d ?mdot_ti_m)
  #   :subtasks (and
  #    (task0 (take_image ?mdot_ti_s ?mdot_ti_d ?mdot_ti_i ?mdot_ti_m))
  #   )
  # )
  def method3(args) do
    [ti_d, ti_i, ti_m, ti_s] = args
    {:ok, [
      {:take_image, [ti_s, ti_d, ti_i, ti_m]}
    ]}
  end

  # (:method method4
  #   :parameters (?maissa_ac_i - instrument ?maissa_ac_s - satellite ?maissa_sof_i - instrument)
  #   :task (activate_instrument ?maissa_ac_s ?maissa_ac_i)
  #   :subtasks (and
  #    (task0 (switch_off ?maissa_sof_i ?maissa_ac_s))
  #    (task1 (switch_on ?maissa_ac_i ?maissa_ac_s))
  #    (task2 (auto_calibrate ?maissa_ac_s ?maissa_ac_i))
  #   )
  # )
  def method4(args) do
    [ac_i, ac_s, sof_i] = args
    {:ok, [
      {:switch_off, [sof_i, ac_s]},
      {:switch_on, [ac_i, ac_s]},
      {:auto_calibrate, [ac_s, ac_i]}
    ]}
  end

  # (:method method5
  #   :parameters (?maisa_ac_i - instrument ?maisa_ac_s - satellite)
  #   :task (activate_instrument ?maisa_ac_s ?maisa_ac_i)
  #   :subtasks (and
  #    (task0 (switch_on ?maisa_ac_i ?maisa_ac_s))
  #    (task1 (auto_calibrate ?maisa_ac_s ?maisa_ac_i))
  #   )
  # )
  def method5(args) do
    [ac_i, ac_s] = args
    {:ok, [
      {:switch_on, [ac_i, ac_s]},
      {:auto_calibrate, [ac_s, ac_i]}
    ]}
  end

  # (:method method6
  #   :parameters (?mactc_c_d - calib_direction ?mactc_c_i - instrument ?mactc_c_s - satellite ?mactc_tt_d_prev - direction)
  #   :task (auto_calibrate ?mactc_c_s ?mactc_c_i)
  #   :subtasks (and
  #    (task0 (turn_to ?mactc_c_s ?mactc_c_d ?mactc_tt_d_prev))
  #    (task1 (calibrate ?mactc_c_s ?mactc_c_i ?mactc_c_d))
  #   )
  # )
  def method6(args) do
    [c_d, c_i, c_s, _tt_d_prev] = args
    {:ok, [
      {:turn_to, [c_s, c_d, :current_pointing]}, # Use a placeholder for current pointing
      {:calibrate, [c_s, c_i, c_d]}
    ]}
  end

  # (:method method7
  #   :parameters (?macc_c_d - calib_direction ?macc_c_i - instrument ?macc_c_s - satellite)
  #   :task (auto_calibrate ?macc_c_s ?macc_c_i)
  #   :subtasks (and
  #    (task0 (calibrate ?macc_c_s ?macc_c_i ?macc_c_d))
  #   )
  # )
  def method7(args) do
    [c_d, c_i, c_s] = args
    {:ok, [
      {:calibrate, [c_s, c_i, c_d]}
    ]}
  end
end
