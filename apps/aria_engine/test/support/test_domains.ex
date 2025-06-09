# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.TestDomains do
  @moduledoc """
  Test domain builders for AriaEngine testing.
  
  This module provides domain builders for logistics and blocks world
  domains used in testing scenarios.
  """

  import AriaEngine

  @doc """
  Builds a logistics domain for testing.
  
  This creates a sample domain with basic logistics actions and methods.
  """
  @spec build_logistics_domain() :: AriaEngine.domain()
  def build_logistics_domain do
    domain = create_domain("logistics")
    
    # Add basic movement actions (with both naming conventions for compatibility)
    domain
    |> add_action(:drive, &AriaEngine.LogisticsActions.drive_truck/2)
    |> add_action(:drive_truck, &AriaEngine.LogisticsActions.drive_truck/2)
    |> add_action(:fly, &AriaEngine.LogisticsActions.fly_plane/2)
    |> add_action(:fly_plane, &AriaEngine.LogisticsActions.fly_plane/2) 
    |> add_action(:load, &AriaEngine.LogisticsActions.load_truck/2)
    |> add_action(:load_truck, &AriaEngine.LogisticsActions.load_truck/2)
    |> add_action(:unload, &AriaEngine.LogisticsActions.unload_truck/2)
    |> add_action(:unload_truck, &AriaEngine.LogisticsActions.unload_truck/2)
    |> add_action(:load_plane, &AriaEngine.LogisticsActions.load_plane/2)
    |> add_action(:unload_plane, &AriaEngine.LogisticsActions.unload_plane/2)
    
    # Add task methods
    |> add_task_method("transport", &AriaEngine.LogisticsMethods.transport/2)
    
    # Add unigoal methods
    |> add_unigoal_method("truck_at", &AriaEngine.LogisticsMethods.truck_at/2)
    |> add_unigoal_method("plane_at", &AriaEngine.LogisticsMethods.plane_at/2)
    |> add_unigoal_method("at", &AriaEngine.LogisticsMethods.at_unigoal/2)
  end

  @doc """
  Builds a blocks world domain for testing.
  
  This creates a domain with the four basic blocks world actions and 
  associated task and goal methods for complex block manipulation.
  """
  @spec build_blocks_world_domain() :: AriaEngine.domain()
  def build_blocks_world_domain do
    domain = create_domain("blocks_world")
    
    # Add basic blocks world actions
    domain
    |> add_action(:pickup, &AriaEngine.BlocksWorldActions.pickup/2)
    |> add_action(:putdown, &AriaEngine.BlocksWorldActions.putdown/2)
    |> add_action(:stack, &AriaEngine.BlocksWorldActions.stack/2)
    |> add_action(:unstack, &AriaEngine.BlocksWorldActions.unstack/2)
    
    # Add task methods
    |> add_task_method("move_block", &AriaEngine.BlocksWorldMethods.move_block/2)
    |> add_task_method("get_block", &AriaEngine.BlocksWorldMethods.get_block/2)
    |> add_task_method("clear_block", &AriaEngine.BlocksWorldMethods.clear_block/2)
    |> add_task_method("build_tower", &AriaEngine.BlocksWorldMethods.build_tower/2)
    
    # Add unigoal methods
    |> add_unigoal_method("on", &AriaEngine.BlocksWorldMethods.on_unigoal/2)
    |> add_unigoal_method("on_table", &AriaEngine.BlocksWorldMethods.on_table_unigoal/2)
    |> add_unigoal_method("clear", &AriaEngine.BlocksWorldMethods.clear_unigoal/2)
  end
end
