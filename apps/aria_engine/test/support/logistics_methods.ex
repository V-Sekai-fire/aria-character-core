# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.LogisticsMethods do
  @moduledoc """
  Logistics domain methods - implements the task and goal methods
  from the C++ GTPyhop test suite.
  """

  alias AriaEngine.State

  def truck_at(%State{} = state, [truck, location]) do
    trucks = State.get_object(state, "trucks", "list") || []
    locations = State.get_object(state, "locations", "list") || []
    
    if truck in trucks and location in locations do
      truck_current = State.get_object(state, "truck_at", truck)
      truck_city = State.get_object(state, "in_city", truck_current)
      location_city = State.get_object(state, "in_city", location)
      
      if truck_city == location_city do
        [{:drive_truck, [truck, location]}]
      else
        false
      end
    else
      false
    end
  end

  def plane_at(%State{} = state, [plane, airport]) do
    airplanes = State.get_object(state, "airplanes", "list") || []
    airports = State.get_object(state, "airports", "list") || []
    
    if plane in airplanes and airport in airports do
      [{:fly_plane, [plane, airport]}]
    else
      false
    end
  end

  def at_unigoal(%State{} = state, [object, location]) do
    packages = State.get_object(state, "packages", "list") || []
    
    if object in packages do
      # Try various methods to get object to location
      try_load_truck(state, object, location) ||
      try_unload_truck(state, object, location) ||
      try_load_plane(state, object, location) ||
      try_unload_plane(state, object, location) ||
      try_move_within_city(state, object, location) ||
      try_move_between_airports(state, object, location) ||
      try_move_between_cities(state, object, location)
    else
      false
    end
  end

  defp try_load_truck(%State{} = state, object, truck) do
    trucks = State.get_object(state, "trucks", "list") || []
    
    if truck in trucks do
      object_at = State.get_object(state, "at", object)
      truck_at = State.get_object(state, "truck_at", truck)
      
      if object_at == truck_at do
        [{:load_truck, [object, truck]}]
      else
        false
      end
    else
      false
    end
  end

  defp try_unload_truck(%State{} = state, object, location) do
    trucks = State.get_object(state, "trucks", "list") || []
    locations = State.get_object(state, "locations", "list") || []
    
    if location in locations do
      object_at = State.get_object(state, "at", object)
      
      if object_at in trucks do
        [{:unload_truck, [object, location]}]
      else
        false
      end
    else
      false
    end
  end

  defp try_load_plane(%State{} = state, object, plane) do
    airplanes = State.get_object(state, "airplanes", "list") || []
    
    if plane in airplanes do
      object_at = State.get_object(state, "at", object)
      plane_at = State.get_object(state, "plane_at", plane)
      
      if object_at == plane_at do
        [{:load_plane, [object, plane]}]
      else
        false
      end
    else
      false
    end
  end

  defp try_unload_plane(%State{} = state, object, airport) do
    airplanes = State.get_object(state, "airplanes", "list") || []
    airports = State.get_object(state, "airports", "list") || []
    
    if airport in airports do
      object_at = State.get_object(state, "at", object)
      
      if object_at in airplanes do
        [{:unload_plane, [object, airport]}]
      else
        false
      end
    else
      false
    end
  end

  defp try_move_within_city(%State{} = state, object, location) do
    packages = State.get_object(state, "packages", "list") || []
    locations = State.get_object(state, "locations", "list") || []
    
    if object in packages and location in locations do
      object_at = State.get_object(state, "at", object)
      
      if State.get_object(state, "in_city", object_at) == State.get_object(state, "in_city", location) do
        truck = AriaEngine.LogisticsActions.find_truck(state, object)
        
        if truck do
          # Return as multigoal - multiple goals that need to be achieved
          {:multigoal, [
            {"truck_at", truck, object_at},
            {"at", object, truck},
            {"truck_at", truck, location},
            {"at", object, location}
          ]}
        else
          false
        end
      else
        false
      end
    else
      false
    end
  end

  defp try_move_between_airports(%State{} = state, object, airport) do
    packages = State.get_object(state, "packages", "list") || []
    airports = State.get_object(state, "airports", "list") || []
    
    if object in packages and airport in airports do
      object_at = State.get_object(state, "at", object)
      
      if object_at in airports and 
         State.get_object(state, "in_city", object_at) != State.get_object(state, "in_city", airport) do
        plane = AriaEngine.LogisticsActions.find_plane(state, object)
        
        if plane do
          # Return as multigoal - multiple goals that need to be achieved in sequence
          {:multigoal, [
            {"plane_at", plane, object_at},
            {"at", object, plane},
            {"plane_at", plane, airport},
            {"at", object, airport}
          ]}
        else
          false
        end
      else
        false
      end
    else
      false
    end
  end

  defp try_move_between_cities(%State{} = state, object, location) do
    packages = State.get_object(state, "packages", "list") || []
    locations = State.get_object(state, "locations", "list") || []
    
    if object in packages and location in locations do
      object_at = State.get_object(state, "at", object)
      
      if State.get_object(state, "in_city", object_at) != State.get_object(state, "in_city", location) do
        airport1 = AriaEngine.LogisticsActions.find_airport(state, object_at)
        airport2 = AriaEngine.LogisticsActions.find_airport(state, location)
        
        if airport1 && airport2 do
          # Return as multigoal - multiple goals that need to be achieved in sequence
          {:multigoal, [
            {"at", object, airport1},
            {"at", object, airport2},
            {"at", object, location}
          ]}
        else
          false
        end
      else
        false
      end
    else
      false
    end
  end

  # Task method for transporting an object to a location
  def transport(%State{} = _state, [object, destination]) do
    # Simple transport: create a goal to get the object to the destination
    [{"at", object, destination}]
  end
end
