# ADR-188: Practical How-To Documentation

**Status:** Active  
**Date:** 2025-06-25  
**Priority:** HIGH - Advanced Developer Support

## Overview

**Purpose**: Advanced techniques, debugging strategies, and integration patterns for AriaEngine  
**Target Audience**: Developers who have completed ADR-185 and ADR-186  
**Scope**: Complex scenarios, troubleshooting, optimization, and system integration

## Advanced Techniques

### Technique 1: Dynamic Goal Generation

**Problem**: Goals that depend on runtime state or external data

**Solution**: Use task methods to generate goals dynamically

```elixir
defmodule MyApp.Domains.DynamicDomain do
  use AriaEngine.Domain
  
  @task_method
  def process_user_requests(state, [user_id]) do
    # Get user's pending requests from state
    requests = State.get_fact(state, "pending_requests", user_id) || []
    
    # Convert each request to a goal
    goals = Enum.map(requests, fn request ->
      case request.type do
        "meeting" -> 
          {request.id, "meeting_status", "scheduled"}
        "resource" -> 
          {request.resource_id, "allocation_status", "assigned"}
        "task" -> 
          {request.id, "task_status", "complete"}
      end
    end)
    
    {:ok, goals}
  end
  
  # Support method for external data integration
  def load_user_requests_from_api(state, user_id) do
    # Simulate API call
    requests = ExternalAPI.get_user_requests(user_id)
    
    # Store in state for planning
    State.set_fact(state, "pending_requests", user_id, requests)
  end
end
```

**Usage Pattern**:
```elixir
# Load external data first
state = MyApp.Domains.DynamicDomain.load_user_requests_from_api(state, "user_123")

# Then plan with dynamic goals
goal = {:task_process_user_requests, ["user_123"]}
{:ok, final_state} = AriaEngine.plan(domain, state, [goal])
```

### Technique 2: Conditional Action Execution

**Problem**: Actions that should only execute under specific conditions

**Solution**: Use guard clauses and state validation

```elixir
defmodule MyApp.Domains.ConditionalDomain do
  use AriaEngine.Domain
  
  @action duration: "PT30M",
          requires_entities: [
            %{type: "weather_service", capabilities: [:forecast]}
          ]
  def schedule_outdoor_event(state, [event_id, location]) do
    # Check weather conditions before proceeding
    weather = State.get_fact(state, "weather_forecast", location)
    time_of_day = State.get_fact(state, "current_time", "system")
    
    case {weather, time_of_day} do
      {"sunny", hour} when hour >= 9 and hour <= 17 ->
        # Good conditions - proceed
        state
        |> State.set_fact("event_status", event_id, "scheduled")
        |> State.set_fact("event_location", event_id, location)
        
      {"rainy", _} ->
        {:error, "Cannot schedule outdoor event - weather is rainy"}
        
      {_, hour} when hour < 9 or hour > 17 ->
        {:error, "Cannot schedule outdoor event - outside business hours"}
        
      _ ->
        {:error, "Weather conditions unknown for #{location}"}
    end
  end
  
  @unigoal_method predicate: "event_status"
  def plan_event(state, [event_id, "scheduled"]) do
    # Pre-check conditions before attempting action
    location = State.get_fact(state, "preferred_location", event_id)
    weather = State.get_fact(state, "weather_forecast", location)
    
    case weather do
      "sunny" ->
        {:ok, [
          {:schedule_outdoor_event, [event_id, location]}
        ]}
      "rainy" ->
        # Alternative indoor planning
        {:ok, [
          {:schedule_indoor_event, [event_id, "conference_room"]}
        ]}
      nil ->
        # Need to check weather first
        {:ok, [
          {:check_weather_forecast, [location]},
          {:schedule_outdoor_event, [event_id, location]}
        ]}
    end
  end
end
```

### Technique 3: Resource Pool Management

**Problem**: Managing shared resources across multiple concurrent operations

**Solution**: Implement resource allocation and release patterns

```elixir
defmodule MyApp.Domains.ResourcePoolDomain do
  use AriaEngine.Domain
  
  @action duration: "PT5M"
  def acquire_resource(state, [resource_type, task_id, quantity]) do
    available = State.get_fact(state, "available_resources", resource_type) || 0
    allocated = State.get_fact(state, "allocated_resources", task_id) || %{}
    
    if available >= quantity do
      # Allocate resources
      new_available = available - quantity
      new_allocated = Map.put(allocated, resource_type, quantity)
      
      state
      |> State.set_fact("available_resources", resource_type, new_available)
      |> State.set_fact("allocated_resources", task_id, new_allocated)
      |> State.set_fact("resource_status", task_id, "acquired")
    else
      {:error, "Insufficient #{resource_type} resources: need #{quantity}, have #{available}"}
    end
  end
  
  @action duration: "PT2M"
  def release_resource(state, [resource_type, task_id]) do
    allocated = State.get_fact(state, "allocated_resources", task_id) || %{}
    available = State.get_fact(state, "available_resources", resource_type) || 0
    
    case Map.get(allocated, resource_type) do
      nil ->
        # Nothing to release
        state
      quantity ->
        # Release resources back to pool
        new_available = available + quantity
        new_allocated = Map.delete(allocated, resource_type)
        
        state
        |> State.set_fact("available_resources", resource_type, new_available)
        |> State.set_fact("allocated_resources", task_id, new_allocated)
        |> State.set_fact("resource_status", task_id, "released")
    end
  end
end
```

## Debugging Strategies

### Strategy 1: State Inspection and Logging

**Problem**: Understanding why planning fails or produces unexpected results

**Solution**: Add comprehensive state logging and inspection

```elixir
defmodule MyApp.Domains.DebuggableDomain do
  use AriaEngine.Domain
  require Logger
  
  @unigoal_method predicate: "debug_goal"
  def debug_goal_method(state, [subject, target_value]) do
    # Log current state for debugging
    Logger.info("Planning for goal: #{subject} -> #{target_value}")
    Logger.info("Current state facts: #{inspect(State.all_facts(state))}")
    
    current_value = State.get_fact(state, "debug_goal", subject)
    Logger.info("Current value: #{inspect(current_value)}")
    
    case current_value do
      ^target_value ->
        Logger.info("Goal already achieved")
        {:ok, []}
      nil ->
        Logger.warn("Subject #{subject} not found in state")
        {:error, "Unknown subject: #{subject}"}
      other_value ->
        Logger.info("Need to change #{other_value} to #{target_value}")
        {:ok, [
          {:debug_action, [subject, other_value, target_value]}
        ]}
    end
  end
  
  # Helper function for state inspection
  def inspect_state(state, label \\ "State") do
    facts = State.all_facts(state)
    Logger.info("=== #{label} ===")
    Enum.each(facts, fn {subject, predicate, value} ->
      Logger.info("  #{subject}.#{predicate} = #{inspect(value)}")
    end)
    Logger.info("=== End #{label} ===")
    state
  end
end
```

### Strategy 2: Plan Visualization

**Problem**: Understanding complex planning decisions and execution order

**Solution**: Generate plan visualization and execution traces

```elixir
defmodule MyApp.ExecutionTracer do
  @doc """
  Trace plan execution with timing and state changes
  """
  def trace_execution(domain, state, goals) do
    start_time = System.monotonic_time(:millisecond)
    
    case AriaEngine.plan(domain, state, goals) do
      {:ok, final_state} ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time
        
        IO.puts("=== Execution Trace ===")
        IO.puts("Planning completed in #{duration}ms")
        IO.puts("Initial facts: #{count_facts(state)}")
        IO.puts("Final facts: #{count_facts(final_state)}")
        
        # Show state changes
        show_state_diff(state, final_state)
        
        {:ok, final_state}
        
      {:error, reason} ->
        end_time = System.monotonic_time(:millisecond)
        duration = end_time - start_time
        
        IO.puts("=== Execution Failed ===")
        IO.puts("Planning failed after #{duration}ms")
        IO.puts("Reason: #{reason}")
        
        {:error, reason}
    end
  end
  
  defp count_facts(state) do
    State.all_facts(state) |> length()
  end
  
  defp show_state_diff(initial_state, final_state) do
    initial_facts = State.all_facts(initial_state) |> MapSet.new()
    final_facts = State.all_facts(final_state) |> MapSet.new()
    
    added = MapSet.difference(final_facts, initial_facts)
    removed = MapSet.difference(initial_facts, final_facts)
    
    if MapSet.size(added) > 0 do
      IO.puts("Added facts:")
      Enum.each(added, fn {s, p, v} -> IO.puts("  + #{s}.#{p} = #{v}") end)
    end
    
    if MapSet.size(removed) > 0 do
      IO.puts("Removed facts:")
      Enum.each(removed, fn {s, p, v} -> IO.puts("  - #{s}.#{p} = #{v}") end)
    end
  end
end
```

### Strategy 3: Error Recovery and Fallback Patterns

**Problem**: Handling planning failures gracefully

**Solution**: Implement fallback strategies and error recovery

```elixir
defmodule MyApp.Domains.ResilientDomain do
  use AriaEngine.Domain
  
  @unigoal_method predicate: "resilient_goal"
  def resilient_goal_method(state, [subject, target]) do
    # Try primary approach first
    case try_primary_approach(state, subject, target) do
      {:ok, plan} ->
        {:ok, plan}
      {:error, reason} ->
        Logger.warn("Primary approach failed: #{reason}")
        # Try fallback approach
        try_fallback_approach(state, subject, target)
    end
  end
  
  defp try_primary_approach(state, subject, target) do
    # Check if primary resources are available
    primary_resource = State.get_fact(state, "primary_resource", "available")
    
    if primary_resource do
      {:ok, [
        {:use_primary_resource, [subject, target]}
      ]}
    else
      {:error, "Primary resource not available"}
    end
  end
  
  defp try_fallback_approach(state, subject, target) do
    # Check fallback options
    fallback_resource = State.get_fact(state, "fallback_resource", "available")
    manual_option = State.get_fact(state, "manual_processing", "enabled")
    
    cond do
      fallback_resource ->
        Logger.info("Using fallback resource for #{subject}")
        {:ok, [
          {:use_fallback_resource, [subject, target]}
        ]}
      manual_option ->
        Logger.info("Using manual processing for #{subject}")
        {:ok, [
          {:manual_process, [subject, target]}
        ]}
      true ->
        {:error, "No fallback options available"}
    end
  end
end
```

## Integration Patterns

### Pattern 1: External API Integration

**Problem**: Integrating AriaEngine with external services and APIs

**Solution**: Create adapter layers and async handling

```elixir
defmodule MyApp.ExternalIntegration do
  @doc """
  Adapter for external service integration
  """
  defmodule ServiceAdapter do
    def call_external_service(service_name, params) do
      # Simulate external API call
      case HTTPoison.post("https://api.#{service_name}.com/action", Jason.encode!(params)) do
        {:ok, %{status_code: 200, body: body}} ->
          {:ok, Jason.decode!(body)}
        {:ok, %{status_code: status}} ->
          {:error, "Service returned status #{status}"}
        {:error, reason} ->
          {:error, "Network error: #{reason}"}
      end
    end
  end
  
  defmodule IntegratedDomain do
    use AriaEngine.Domain
    
    @action duration: "PT30S"
    def call_payment_service(state, [order_id, amount]) do
      case ServiceAdapter.call_external_service("payments", %{
        order_id: order_id,
        amount: amount,
        currency: "USD"
      }) do
        {:ok, %{"status" => "success", "transaction_id" => tx_id}} ->
          state
          |> State.set_fact("payment_status", order_id, "completed")
          |> State.set_fact("transaction_id", order_id, tx_id)
          
        {:ok, %{"status" => "failed", "reason" => reason}} ->
          {:error, "Payment failed: #{reason}"}
          
        {:error, reason} ->
          {:error, "Payment service error: #{reason}"}
      end
    end
    
    @unigoal_method predicate: "order_status"
    def process_order(state, [order_id, "completed"]) do
      payment_status = State.get_fact(state, "payment_status", order_id)
      
      case payment_status do
        "completed" ->
          {:ok, [
            {:fulfill_order, [order_id]},
            {:send_confirmation, [order_id]}
          ]}
        _ ->
          amount = State.get_fact(state, "order_amount", order_id)
          {:ok, [
            {:call_payment_service, [order_id, amount]},
            {:fulfill_order, [order_id]},
            {:send_confirmation, [order_id]}
          ]}
      end
    end
  end
end
```

### Pattern 2: Event-Driven Integration

**Problem**: Responding to external events and triggers

**Solution**: Event handling with state updates

```elixir
defmodule MyApp.EventDrivenIntegration do
  defmodule EventHandler do
    use GenServer
    
    def start_link(domain) do
      GenServer.start_link(__MODULE__, domain, name: __MODULE__)
    end
    
    def handle_external_event(event_type, event_data) do
      GenServer.cast(__MODULE__, {:external_event, event_type, event_data})
    end
    
    def init(domain) do
      {:ok, %{domain: domain, current_state: State.new()}}
    end
    
    def handle_cast({:external_event, event_type, event_data}, %{domain: domain, current_state: state}) do
      # Convert external event to AriaEngine goals
      goals = case event_type do
        :user_login ->
          user_id = event_data.user_id
          [
            {user_id, "session_status", "active"},
            {user_id, "last_login", DateTime.utc_now()}
          ]
          
        :order_received ->
          order_id = event_data.order_id
          [
            {order_id, "order_status", "processing"}
          ]
          
        :system_alert ->
          alert_id = event_data.alert_id
          [
            {alert_id, "alert_status", "acknowledged"}
          ]
      end
      
      # Plan and execute response
      case AriaEngine.plan(domain, state, goals) do
        {:ok, new_state} ->
          {:noreply, %{domain: domain, current_state: new_state}}
        {:error, reason} ->
          Logger.error("Failed to handle event #{event_type}: #{reason}")
          {:noreply, %{domain: domain, current_state: state}}
      end
    end
  end
end
```

### Pattern 3: Database Integration

**Problem**: Persisting and loading state from databases

**Solution**: State persistence layer

```elixir
defmodule MyApp.DatabaseIntegration do
  defmodule StatePersistence do
    @doc """
    Save AriaEngine state to database
    """
    def save_state(state, session_id) do
      facts = State.all_facts(state)
      
      # Convert facts to database records
      records = Enum.map(facts, fn {subject, predicate, value} ->
        %{
          session_id: session_id,
          subject: subject,
          predicate: predicate,
          value: Jason.encode!(value),
          inserted_at: DateTime.utc_now()
        }
      end)
      
      # Batch insert
      MyApp.Repo.insert_all("state_facts", records)
    end
    
    @doc """
    Load AriaEngine state from database
    """
    def load_state(session_id) do
      import Ecto.Query
      
      facts = from(f in "state_facts",
        where: f.session_id == ^session_id,
        select: {f.subject, f.predicate, f.value}
      )
      |> MyApp.Repo.all()
      |> Enum.map(fn {subject, predicate, value} ->
        {subject, predicate, Jason.decode!(value)}
      end)
      
      # Rebuild state from facts
      Enum.reduce(facts, State.new(), fn {subject, predicate, value}, state ->
        State.set_fact(state, predicate, subject, value)
      end)
    end
  end
  
  defmodule PersistentDomain do
    use AriaEngine.Domain
    
    @action duration: "PT1M"
    def save_progress(state, [session_id]) do
      # Persist current state
      StatePersistence.save_state(state, session_id)
      
      state
      |> State.set_fact("save_status", session_id, "saved")
      |> State.set_fact("last_save", session_id, DateTime.utc_now())
    end
    
    @unigoal_method predicate: "session_status"
    def restore_session(state, [session_id, "active"]) do
      # Check if session exists
      case StatePersistence.load_state(session_id) do
        %State{} = loaded_state ->
          # Session found - merge states
          {:ok, []}  # State already loaded
        nil ->
          # New session
          {:ok, [
            {:initialize_session, [session_id]}
          ]}
      end
    end
  end
end
```

## Performance Optimization

### Optimization 1: Method Caching

**Problem**: Expensive method computations being repeated

**Solution**: Implement method result caching

```elixir
defmodule MyApp.OptimizedDomain do
  use AriaEngine.Domain
  
  # Cache for expensive computations
  @cache_table :method_cache
  
  def init_cache do
    :ets.new(@cache_table, [:set, :public, :named_table])
  end
  
  @unigoal_method predicate: "expensive_computation"
  def expensive_goal_method(state, [input, target]) do
    cache_key = {:expensive_computation, input, target}
    
    case :ets.lookup(@cache_table, cache_key) do
      [{^cache_key, cached_result}] ->
        # Return cached result
        cached_result
      [] ->
        # Compute and cache result
        result = compute_expensive_method(state, input, target)
        :ets.insert(@cache_table, {cache_key, result})
        result
    end
  end
  
  defp compute_expensive_method(state, input, target) do
    # Simulate expensive computation
    :timer.sleep(1000)  # 1 second delay
    
    # Actual computation logic
    current = State.get_fact(state, "expensive_computation", input)
    
    if current == target do
      {:ok, []}
    else
      {:ok, [
        {:expensive_action, [input, target]}
      ]}
    end
  end
end
```

### Optimization 2: Lazy Evaluation

**Problem**: Computing all possible plans when only one is needed

**Solution**: Implement lazy plan generation

```elixir
defmodule MyApp.LazyDomain do
  use AriaEngine.Domain
  
  @unigoal_method predicate: "lazy_goal"
  def lazy_goal_method(state, [subject, target]) do
    # Generate plans lazily using streams
    plan_stream = Stream.unfold({state, 0}, fn
      {current_state, step} when step < 10 ->
        plan_step = generate_plan_step(current_state, subject, target, step)
        {plan_step, {current_state, step + 1}}
      _ ->
        nil
    end)
    
    # Take only the first valid plan
    case Enum.find(plan_stream, fn plan -> valid_plan?(plan) end) do
      nil ->
        {:error, "No valid plan found"}
      plan ->
        {:ok, plan}
    end
  end
  
  defp generate_plan_step(state, subject, target, step) do
    # Generate different plan alternatives based on step
    case step do
      0 -> [{:quick_action, [subject, target]}]
      1 -> [{:careful_action, [subject, target]}]
      2 -> [{:prepare_action, [subject]}, {:execute_action, [subject, target]}]
      _ -> [{:fallback_action, [subject, target]}]
    end
  end
  
  defp valid_plan?(plan) do
    # Check if plan is valid (simplified)
    length(plan) > 0
  end
end
```

## Testing Strategies

### Strategy 1: Domain Testing Framework

**Problem**: Testing complex domain logic systematically

**Solution**: Create domain-specific test helpers

```elixir
defmodule MyApp.DomainTestHelpers do
  @doc """
  Test helper for domain planning scenarios
  """
  def test_planning_scenario(domain, initial_facts, goals, expected_outcome) do
    # Set up initial state
    state = Enum.reduce(initial_facts, State.new(), fn {subject, predicate, value}, acc ->
      State.set_fact(acc, predicate, subject, value)
    end)
    
    # Execute planning
    result = AriaEngine.plan(domain, state, goals)
    
    # Verify outcome
    case {result, expected_outcome} do
      {{:ok, final_state}, {:success, expected_facts}} ->
        verify_expected_facts(final_state, expected_facts)
        
      {{:error, reason}, {:error, expected_reason}} ->
        assert reason =~ expected_reason
        
      {actual, expected} ->
        flunk("Expected #{inspect(expected)}, got #{inspect(actual)}")
    end
  end
  
  defp verify_expected_facts(state, expected_facts) do
    Enum.each(expected_facts, fn {subject, predicate, expected_value} ->
      actual_value = State.get_fact(state, predicate, subject)
      assert actual_value == expected_value,
        "Expected #{subject}.#{predicate} = #{expected_value}, got #{actual_value}"
    end)
  end
  
  @doc """
  Generate test cases for domain validation
  """
  def generate_test_cases(domain_module) do
    [
      # Basic functionality tests
      %{
        name: "basic_goal_achievement",
        initial_facts: [{"entity1", "status", "initial"}],
        goals: [{"entity1", "status", "target"}],
        expected: {:success, [{"entity1", "status", "target"}]}
      },
      
      # Error handling tests
      %{
        name: "invalid_goal_handling",
        initial_facts: [],
        goals: [{"nonexistent", "invalid_predicate", "value"}],
        expected: {:error, "No methods available"}
      },
      
      # Resource constraint tests
      %{
        name: "resource_constraint_violation",
        initial_facts: [{"resource1", "available", false}],
        goals: [{"task1", "status", "complete"}],
        expected: {:error, "Resource not available"}
      }
    ]
  end
end

# Example test usage
defmodule MyApp.DomainTest do
  use ExUnit.Case
  import MyApp.DomainTestHelpers
  
  test "restaurant domain scenarios" do
    domain = MyApp.Domains.RestaurantDomain.create_domain()
    
    test_planning_scenario(
      domain,
      [
        {"chef_1", "status", "available"},
        {"order_001", "dish_type", "pasta"}
      ],
      [{"order_001", "order_status", "ready"}],
      {:success, [{"order_001", "order_status", "ready"}]}
    )
  end
end
```

### Strategy 2: Property-Based Testing

**Problem**: Testing domain behavior across many input combinations

**Solution**: Use property-based testing with StreamData

```elixir
defmodule MyApp.PropertyTests do
  use ExUnit.Case
  use ExUnitProperties
  
  property "state facts are preserved correctly" do
    check all subject <- string(:alphanumeric),
              predicate <- string(:alphanumeric),
              value <- one_of([string(:alphanumeric), integer(), boolean()]) do
      
      state = State.new()
      |> State.set_fact(predicate, subject, value)
      
      retrieved_value = State.get_fact(state, predicate, subject)
      assert retrieved_value == value
    end
  end
  
  property "planning with valid goals succeeds" do
    check all goal_count <- integer(1..5),
              subjects <- list_of(string(:alphanumeric), length: goal_count),
              predicates <- list_of(string(:alphanumeric), length: goal_count),
              values <- list_of(string(:alphanumeric), length: goal_count) do
      
      domain = create_test_domain()
      state = State.new()
      
      goals = Enum.zip([subjects, predicates, values])
      |> Enum.map(fn {s, p, v} -> {s, p, v} end)
      
      # This should not crash (may succeed or fail gracefully)
      case AriaEngine.plan(domain, state, goals) do
        {:ok, _final_state} -> :ok
        {:error, _reason} -> :ok
      end
    end
  end
  
  defp create_test_domain do
    # Create a minimal test domain for property testing
    MyApp.Domains.TestDomain.create_domain()
  end
end
```

## Common Debugging Scenarios

### Scenario 1: "No methods available for goal"

**Diagnosis Steps**:
1. Check goal format: `{subject, predicate, value}`
2. Verify `@unigoal_method predicate:` matches goal predicate
3. Check method function signature: `def method_name(state, [subject, value])`

**Example Fix**:
```elixir
# Problem: Goal predicate doesn't match method
goal = {"user_1", "login_status", "logged_in"}

# Wrong method predicate
@unigoal_method predicate: "user_status"  # Doesn't match "login_status"
def handle_user_login(state, [user_id, status]) do
  # ...
end

# Correct method predicate
@unigoal_method predicate: "login_status"  # Matches goal predicate
def handle_user_login(state, [user_id, status]) do
  # ...
end
```

### Scenario 2: "Action failed during execution"

**Diagnosis Steps**:
1. Check action return value (should be state or `{:ok, state}`)
2. Verify state transformation logic
3. Check for runtime errors in action code

**Example Fix**:
```elixir
# Problem: Action returns error tuple
@action
def problematic_action(state, [param]) do
  if some_condition do
    {:error, "Something went wrong"}  # This causes execution failure
  else
    State.set_fact(state, "result", param, "success")
  end
end

# Solution: Handle errors gracefully or ensure success
@action
def fixed_action(state, [param]) do
  if some_condition do
    # Log error but return valid state
    Logger.warn("Condition not met for #{param}")
    State.set_fact(state, "result", param, "failed")
  else
    State.set_fact(state, "result", param, "success")
  end
end
```

### Scenario 3: "Planning takes too long"

**Diagnosis Steps**:
1. Check for infinite loops in method logic
2. Verify goal termination conditions
3. Look for overly complex method decomposition

**Example Fix**:
```elixir
# Problem: Method doesn't check current state
@unigoal_method predicate: "task_status"
def infinite_method(state, [task_id, "complete"]) do
  # Always returns the same action, causing infinite loop
  {:ok, [
    {:work_on_task, [task_id]}
  ]}
end

# Solution: Check current state first
@unigoal_method predicate: "task_status"
def terminating_method(state, [task_id, "complete"]) do
  current_status = State.get_fact(state, "task_status", task_id)
  
  case current_status do
    "complete" ->
      {:ok, []}  # Already done - terminate
    _ ->
      {:ok, [
        {:work_on_task, [task_id]}
      ]}
  end
end
```

## Success Criteria

After reading this ADR, you should be able to:

- [x] Implement dynamic goal generation based on runtime data
- [x] Create conditional actions with proper state validation
- [x] Manage resource pools and handle allocation conflicts
- [x] Debug planning failures using state inspection and logging
- [x] Integrate AriaEngine with external APIs and databases
- [x] Optimize domain performance with caching
