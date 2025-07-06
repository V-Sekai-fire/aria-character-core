# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Timeline.Internal.STN.Core do
  @moduledoc """
  Main STN (Simple Temporal Network) interface module.

  This module provides a clean delegation API to the split STN modules:
  - Operations: Core interval and constraint management
  - Consistency: Validation and classification
  - Scheduling: Interval queries and scheduling operations

  All functionality is preserved through delegation while maintaining
  backward compatibility with existing code.
  """

  alias Timeline.Internal.STN.{Operations, Consistency, Scheduling}

  @type constraint :: {number(), number()}
  @type time_point :: String.t()
  @type constraint_matrix :: %{optional({time_point(), time_point()}) => constraint()}

  # Delegate to Operations module
  defdelegate add_interval(stn, interval), to: Operations
  defdelegate update_interval(stn, interval), to: Operations
  defdelegate remove_interval(stn, interval_id), to: Operations
  defdelegate add_constraint(stn, from_point, to_point, constraint), to: Operations
  defdelegate get_constraint(stn, from_point, to_point), to: Operations
  defdelegate add_time_point(stn, time_point), to: Operations
  defdelegate time_points(stn), to: Operations

  # Delegate to Consistency module
  defdelegate simple_stn?(stn), to: Consistency
  defdelegate consistent?(stn), to: Consistency
  defdelegate mathematically_consistent?(stn), to: Consistency

  # Delegate to Scheduling module
  defdelegate get_intervals(stn), to: Scheduling
  defdelegate get_overlapping_intervals(stn, query_start, query_end), to: Scheduling
  defdelegate find_free_slots(stn, duration, window_start, window_end), to: Scheduling
  defdelegate check_interval_conflicts(stn, new_start, new_end), to: Scheduling
  defdelegate find_next_available_slot(stn, duration, earliest_start), to: Scheduling
end
