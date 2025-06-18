# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine do
  @moduledoc """
  Main AriaEngine module providing utility functions.
  
  This module contains utility functions that are used across the AriaEngine system.
  """

  @doc """
  Merges two method maps, combining method lists for the same keys.
  
  When both maps have the same key, the method lists are concatenated.
  """
  @spec merge_method_maps(map(), map()) :: map()
  def merge_method_maps(map1, map2) when is_map(map1) and is_map(map2) do
    Map.merge(map1, map2, fn _key, methods1, methods2 ->
      # Both should be lists of methods - concatenate them
      case {methods1, methods2} do
        {list1, list2} when is_list(list1) and is_list(list2) ->
          list1 ++ list2
        {^methods1, methods2} ->
          # Fallback: if not both lists, prefer the second one
          methods2
      end
    end)
  end

  @doc """
  Basic planning function that delegates to the Planner module.
  """
  defdelegate plan(domain, state, todos, opts \\ []), to: AriaEngine.Planner

  @doc """
  Basic plan execution function that delegates to the Planner module.
  """
  defdelegate execute_plan(domain, state, plan), to: AriaEngine.Planner, as: :execute
end
