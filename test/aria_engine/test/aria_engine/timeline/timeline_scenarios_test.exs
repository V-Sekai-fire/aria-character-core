# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Timeline.ScenariosTest do
  use ExUnit.Case, async: true

  alias AriaEngine.Timeline
  alias AriaEngine.Timeline.Interval
  alias AriaEngine.Timeline.AgentEntity

  describe "autonomous vehicle fleet coordination" do
    test "coordinates multiple autonomous vehicles with dynamic capabilities" do
      timeline = Timeline.new()

      # Fleet of vehicles with different capabilities
      delivery_van =
        AgentEntity.create_agent(
          "van1",
          "Delivery Van Alpha",
          %{cargo_capacity: 500, battery: 85},
          capabilities: [:autonomous_driving, :package_delivery, :route_optimization]
        )

      passenger_car =
        AgentEntity.create_agent(
          "car1",
          "Passenger Car Beta",
          %{passenger_capacity: 4, battery: 92},
          capabilities: [:autonomous_driving, :passenger_transport, :navigation]
        )

      maintenance_vehicle =
        AgentEntity.create_entity(
          "maint1",
          "Maintenance Vehicle",
          %{tools: ["diagnostic", "repair"], battery: 0}
        )

      # Morning delivery route
      delivery_route =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 08:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC"),
          agent: delivery_van,
          label: "Morning Delivery Route",
          metadata: %{
            required_capabilities: [:autonomous_driving, :package_delivery],
            route: ["warehouse", "stop1", "stop2", "stop3"]
          }
        )

      # Passenger pickup service
      passenger_service =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 09:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:00:00], "Etc/UTC"),
          agent: passenger_car,
          label: "Passenger Service",
          metadata: %{
            required_capabilities: [:autonomous_driving, :passenger_transport],
            service_area: "downtown"
          }
        )

      # Van charging and maintenance (loses autonomous capabilities)
      charging_van =
        AgentEntity.remove_capabilities(delivery_van, [:autonomous_driving, :route_optimization])

      charging_period =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 11:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 13:00:00], "Etc/UTC"),
          entity: charging_van,
          label: "Charging and Maintenance",
          metadata: %{location: "depot"}
        )

      # Maintenance vehicle gains capabilities for service
      active_maintenance =
        AgentEntity.add_capabilities(maintenance_vehicle, [
          :diagnostic_analysis,
          :repair_operations
        ])

      maintenance_service =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 11:30:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 12:30:00], "Etc/UTC"),
          agent: active_maintenance,
          label: "Fleet Maintenance",
          metadata: %{
            required_capabilities: [:diagnostic_analysis, :repair_operations],
            target: "van1"
          }
        )

      # Add all intervals with constraints
      timeline =
        timeline
        |> Timeline.add_interval(delivery_route)
        |> Timeline.add_interval(passenger_service)
        |> Timeline.add_interval(charging_period)
        |> Timeline.add_interval(maintenance_service)
        |> Timeline.add_constraint(
          "#{delivery_route.id}_end",
          "#{charging_period.id}_start",
          {0, 0}
        )
        # 30 min delay
        |> Timeline.add_constraint(
          "#{charging_period.id}_start",
          "#{maintenance_service.id}_start",
          {1800, 1800}
        )

      assert Timeline.consistent?(timeline)

      # Verify capability transitions
      assert AgentEntity.has_capability?(delivery_van, :autonomous_driving)
      assert AgentEntity.has_capability?(passenger_car, :passenger_transport)
      refute AgentEntity.is_currently_agent?(charging_van)
      assert AgentEntity.is_currently_agent?(active_maintenance)
    end

    test "handles emergency response with capability reallocation" do
      timeline = Timeline.new()

      # Normal operation vehicles
      ambulance =
        AgentEntity.create_agent(
          "amb1",
          "Emergency Ambulance",
          %{medical_equipment: true, priority: "emergency"},
          capabilities: [:emergency_response, :medical_transport, :autonomous_driving]
        )

      patrol_car =
        AgentEntity.create_agent(
          "patrol1",
          "Police Patrol",
          %{jurisdiction: "city", equipment: ["radio", "computer"]},
          capabilities: [:law_enforcement, :traffic_control, :autonomous_driving]
        )

      # Normal patrol duty
      routine_patrol =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 10:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 14:00:00], "Etc/UTC"),
          agent: patrol_car,
          label: "Routine Patrol",
          metadata: %{
            required_capabilities: [:law_enforcement, :autonomous_driving],
            area: "downtown"
          }
        )

      # Emergency call interrupts normal operations
      emergency_response =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 12:30:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 13:30:00], "Etc/UTC"),
          agent: ambulance,
          label: "Emergency Medical Response",
          metadata: %{
            required_capabilities: [:emergency_response, :medical_transport],
            priority: "critical",
            location: "accident_site"
          }
        )

      # Patrol car provides traffic control support
      traffic_support =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 12:30:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 13:30:00], "Etc/UTC"),
          agent: patrol_car,
          label: "Emergency Traffic Control",
          metadata: %{
            required_capabilities: [:traffic_control, :autonomous_driving],
            support_for: "amb1"
          }
        )

      # Add intervals with emergency coordination
      timeline =
        timeline
        |> Timeline.add_interval(routine_patrol)
        |> Timeline.add_interval(emergency_response)
        |> Timeline.add_interval(traffic_support)
        # simultaneous response
        |> Timeline.add_constraint(
          "#{emergency_response.id}_start",
          "#{traffic_support.id}_start",
          {0, 0}
        )
        # simultaneous end
        |> Timeline.add_constraint(
          "#{emergency_response.id}_end",
          "#{traffic_support.id}_end",
          {0, 0}
        )

      assert Timeline.consistent?(timeline)

      # Verify emergency capabilities
      assert AgentEntity.has_capability?(ambulance, :emergency_response)
      assert AgentEntity.has_capability?(patrol_car, :traffic_control)
      assert AgentEntity.has_capability?(patrol_car, :law_enforcement)
    end
  end

  describe "smart city infrastructure coordination" do
    test "coordinates traffic lights and autonomous vehicles" do
      timeline = Timeline.new()

      # Smart traffic infrastructure
      traffic_light_a =
        AgentEntity.create_entity(
          "light_a",
          "Traffic Light A",
          %{intersection: "main_and_first", sensors: ["camera", "radar"]}
        )

      traffic_controller =
        AgentEntity.create_agent(
          "controller1",
          "Traffic Management System",
          %{coverage: "downtown", ai_enabled: true},
          capabilities: [:traffic_optimization, :real_time_analysis, :coordination]
        )

      autonomous_bus =
        AgentEntity.create_agent(
          "bus1",
          "Autonomous Bus Route 42",
          %{capacity: 50, route: "downtown_loop"},
          capabilities: [:autonomous_driving, :passenger_transport, :schedule_adherence]
        )

      # Traffic light gains smart capabilities during upgrade
      smart_light =
        AgentEntity.add_capabilities(traffic_light_a, [:adaptive_timing, :vehicle_communication])

      # Morning rush hour optimization
      traffic_optimization =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 07:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 09:00:00], "Etc/UTC"),
          agent: traffic_controller,
          label: "Rush Hour Traffic Optimization",
          metadata: %{
            required_capabilities: [:traffic_optimization, :real_time_analysis],
            target_efficiency: 85
          }
        )

      # Smart light adaptive timing
      adaptive_timing =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 07:30:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 08:30:00], "Etc/UTC"),
          agent: smart_light,
          label: "Adaptive Signal Timing",
          metadata: %{
            required_capabilities: [:adaptive_timing, :vehicle_communication],
            coordination_with: "controller1"
          }
        )

      # Bus route with priority signaling
      priority_route =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 08:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 08:45:00], "Etc/UTC"),
          agent: autonomous_bus,
          label: "Priority Bus Route",
          metadata: %{
            required_capabilities: [:autonomous_driving, :schedule_adherence],
            signal_priority: true
          }
        )

      # Add coordination constraints
      timeline =
        timeline
        |> Timeline.add_interval(traffic_optimization)
        |> Timeline.add_interval(adaptive_timing)
        |> Timeline.add_interval(priority_route)
        # 30 min delay
        |> Timeline.add_constraint(
          "#{traffic_optimization.id}_start",
          "#{adaptive_timing.id}_start",
          {1800, 1800}
        )
        # 30 min delay
        |> Timeline.add_constraint(
          "#{adaptive_timing.id}_start",
          "#{priority_route.id}_start",
          {1800, 1800}
        )

      assert Timeline.consistent?(timeline)

      # Verify smart city capabilities
      assert AgentEntity.has_capability?(traffic_controller, :traffic_optimization)
      assert AgentEntity.has_capability?(smart_light, :adaptive_timing)
      assert AgentEntity.has_capability?(autonomous_bus, :schedule_adherence)
    end

    test "handles power grid and electric vehicle coordination" do
      timeline = Timeline.new()

      # Power grid infrastructure
      power_station =
        AgentEntity.create_agent(
          "station1",
          "Smart Power Station",
          %{capacity: "50MW", renewable_mix: 0.6},
          capabilities: [:power_generation, :load_balancing, :grid_optimization]
        )

      charging_station =
        AgentEntity.create_entity(
          "charger1",
          "Fast Charging Station",
          %{power_rating: "150kW", connectors: 4}
        )

      electric_vehicle =
        AgentEntity.create_agent(
          "ev1",
          "Electric Delivery Truck",
          %{battery_capacity: "100kWh", current_charge: 25},
          capabilities: [:autonomous_driving, :cargo_delivery, :smart_charging]
        )

      # Peak demand management
      load_balancing =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 17:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 20:00:00], "Etc/UTC"),
          agent: power_station,
          label: "Peak Load Management",
          metadata: %{
            required_capabilities: [:load_balancing, :grid_optimization],
            demand_forecast: "high"
          }
        )

      # Charging station gains smart capabilities
      smart_charger =
        AgentEntity.add_capabilities(charging_station, [:dynamic_pricing, :load_management])

      smart_charging =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 18:00:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 20:00:00], "Etc/UTC"),
          agent: smart_charger,
          label: "Smart Charging Management",
          metadata: %{
            required_capabilities: [:dynamic_pricing, :load_management],
            grid_responsive: true
          }
        )

      # Vehicle charging with grid coordination
      vehicle_charging =
        Interval.new(
          DateTime.from_naive!(~N[2025-01-01 18:30:00], "Etc/UTC"),
          DateTime.from_naive!(~N[2025-01-01 19:30:00], "Etc/UTC"),
          entity: smart_charger,
          agent: electric_vehicle,
          label: "Coordinated Vehicle Charging",
          metadata: %{
            required_capabilities: [:smart_charging],
            target_charge: 80,
            grid_friendly: true
          }
        )

      # Add grid coordination constraints
      timeline =
        timeline
        |> Timeline.add_interval(load_balancing)
        |> Timeline.add_interval(smart_charging)
        |> Timeline.add_interval(vehicle_charging)
        # 1 hour delay
        |> Timeline.add_constraint(
          "#{load_balancing.id}_start",
          "#{smart_charging.id}_start",
          {3600, 3600}
        )
        # 30 min delay
        |> Timeline.add_constraint(
          "#{smart_charging.id}_start",
          "#{vehicle_charging.id}_start",
          {1800, 1800}
        )

      assert Timeline.consistent?(timeline)

      # Verify grid coordination capabilities
      assert AgentEntity.has_capability?(power_station, :grid_optimization)
      assert AgentEntity.has_capability?(smart_charger, :load_management)
      assert AgentEntity.has_capability?(electric_vehicle, :smart_charging)
    end
  end
end
