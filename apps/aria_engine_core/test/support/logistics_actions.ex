# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.LogisticsActions do
  @moduledoc """
  Logistics domain actions - implements the basic logistics operations
  from the C++ GTPyhop test suite.
  """

  alias AriaEngine.State

  def drive_truck(%State{} = state, [truck, _from_location, to_location]) do
    State.set_object(state, "at", truck, to_location)
  end

  # Compatibility function for 2-argument version
  def drive_truck(%State{} = state, [truck, location]) do
    State.set_object(state, "truck_at", truck, location)
  end

  def fly_plane(%State{} = state, [plane, _from_airport, to_airport]) do
    State.set_object(state, "at", plane, to_airport)
  end

  # Compatibility function for 2-argument version  
  def fly_plane(%State{} = state, [plane, airport]) do
    State.set_object(state, "plane_at", plane, airport)
  end

  def load_truck(%State{} = state, [object, truck]) do
    State.set_object(state, "at", object, truck)
  end

  def load_plane(%State{} = state, [object, plane]) do
    State.set_object(state, "at", object, plane)
  end

  def unload_plane(%State{} = state, [object, airport]) do
    plane = State.get_object(state, "at", object)
    plane_at = State.get_object(state, "plane_at", plane)
    
    if plane_at == airport do
      State.set_object(state, "at", object, airport)
    else
      state
    end
  end

  def unload_truck(%State{} = state, [object, location]) do
    truck = State.get_object(state, "at", object)
    truck_at = State.get_object(state, "truck_at", truck)
    
    if truck_at == location do
      State.set_object(state, "at", object, location)
    else
      state
    end
  end

  # Helper functions
  def find_truck(%State{} = state, object) do
    trucks = State.get_object(state, "trucks", "list") || []
    
    Enum.find(trucks, fn truck ->
      truck_at = State.get_object(state, "truck_at", truck)
      object_at = State.get_object(state, "at", object)
      truck_city = State.get_object(state, "in_city", truck_at)
      object_city = State.get_object(state, "in_city", object_at)
      truck_city == object_city
    end)
  end

  def find_plane(%State{} = state, object) do
    airplanes = State.get_object(state, "airplanes", "list") || []
    
    # Try to find a plane in the same city
    same_city_plane = Enum.find(airplanes, fn plane ->
      plane_at = State.get_object(state, "plane_at", plane)
      object_at = State.get_object(state, "at", object)
      plane_city = State.get_object(state, "in_city", plane_at)
      object_city = State.get_object(state, "in_city", object_at)
      plane_city == object_city
    end)
    
    # If no plane in same city, return any plane
    same_city_plane || List.last(airplanes)
  end

  def find_airport(%State{} = state, location) do
    airports = State.get_object(state, "airports", "list") || []
    
    Enum.find(airports, fn airport ->
      airport_city = State.get_object(state, "in_city", airport)
      location_city = State.get_object(state, "in_city", location)
      airport_city == location_city
    end)
  end
end
