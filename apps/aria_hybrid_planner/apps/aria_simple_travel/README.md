# AriaSimpleTravel

A Simple Travel planning domain for AriaEngine demonstrating durative actions and temporal planning.

This app implements the classic simple travel domain from IPyHOP but enhanced with AriaEngine's unified durative action specification (R25W1398085), showcasing temporal constraints, entity-capability modeling, and multi-agent coordination.

## Overview

The Simple Travel domain models people moving between locations using different transportation methods (walking or taxi) with realistic temporal constraints and resource management.

### Key Features

- **Durative Actions**: Walking and taxi rides take time based on distance
- **Instant Actions**: Calling taxis and paying drivers are immediate
- **Entity-Capability Model**: People, taxis, and locations with specific capabilities
- **Resource Management**: Cash constraints for taxi fares
- **Temporal Planning**: AriaEngine handles scheduling and coordination
- **Multi-Agent Support**: Multiple people and taxis can operate simultaneously

## Domain Model

### Entities

**People** (alice, bob):

- Capabilities: `:walking`, `:taxi_calling`, `:taxi_riding`, `:payment`
- Properties: `cash` (money available), `owe` (taxi fare owed)
- Initial locations: alice at home_a, bob at home_b

**Taxis** (taxi1):

- Capabilities: `:transportation`, `:route_planning`
- Properties: `status` (available/busy)
- Initial location: downtown

**Locations** (home_a, home_b, park, downtown):

- Capabilities: `:destination`, `:waypoint`
- Properties: `distance` between locations

### Actions

#### Instant Actions (Pattern 1)

- **`call_taxi/2`**: Instantly brings taxi to person's location and places person inside
- **`pay_driver/2`**: Instantly processes payment and exits taxi

#### Durative Actions (Pattern 6: Calculated end)

- **`walk/3`**: Duration = 10 minutes per distance unit
- **`ride_taxi/2`**: Duration = 5 minutes per distance unit (faster but costs money)

### Methods

- **`travel/2`**: High-level task method that chooses optimal transportation
- **`achieve_location/2`**: Unigoal method for location goals

## Temporal Patterns Demonstrated

This domain showcases multiple temporal patterns from R25W1398085:

1. **Pattern 1 (Instant, anytime)**: `call_taxi`, `pay_driver`
2. **Pattern 6 (Calculated end)**: `walk`, `ride_taxi` with dynamic durations

## Usage Examples

### Basic Setup

```elixir
# Create domain and initial state
domain = AriaSimpleTravel.create_domain()
{:ok, state} = AriaSimpleTravel.setup_scenario()
```

### Planning Only

```elixir
# Plan Alice's trip to the park
goals = [{"location", "alice", "park"}]
{:ok, solution_tree} = AriaSimpleTravel.plan(domain, state, goals)

# Inspect the plan before execution
IO.inspect(solution_tree, label: "Travel Plan")
```

### Plan and Execute

```elixir
# Plan and execute in one step
goals = [{"location", "alice", "park"}]
{:ok, {final_state, solution_tree}} = AriaSimpleTravel.run_lazy(domain, state, goals)
```

### Execute Pre-made Plan

```elixir
# Execute a previously created plan
{:ok, solution_tree} = AriaSimpleTravel.plan(domain, state, goals)
{:ok, {final_state, _}} = AriaSimpleTravel.run_lazy_tree(domain, state, solution_tree)
```

### Example Scenarios

```elixir
# Run predefined scenarios
{:ok, {final_state, solution_tree, info}} = AriaSimpleTravel.run_example(:alice_to_park)
{:ok, {final_state, solution_tree, info}} = AriaSimpleTravel.run_example(:bob_short_walk)
{:ok, {final_state, solution_tree, info}} = AriaSimpleTravel.run_example(:multi_person)

# Get all available scenarios
scenarios = AriaSimpleTravel.get_example_scenarios()
```

## Example Scenarios

### Alice to Park (Taxi Required)

Alice needs to travel from home_a to park (distance: 8 units). Since the distance exceeds walking threshold (2 units), she must take a taxi.

**Expected Plan:**

1. `call_taxi("alice", "taxi1")` - Instant
2. `ride_taxi("alice", "park")` - 40 minutes (8 units × 5 min/unit)
3. `pay_driver("alice", "park")` - Instant

**Cost:** $5.50 (1.5 + 0.5 × 8)

### Bob Short Walk

Bob walks from home_b to park (distance: 2 units). Since distance is within walking threshold, he walks.

**Expected Plan:**

1. `walk("bob", "home_b", "park")` - 20 minutes (2 units × 10 min/unit)

**Cost:** Free

### Multi-Person Coordination

Both Alice and Bob travel to different destinations simultaneously, demonstrating multi-agent planning.

## Transportation Decision Logic

The domain automatically chooses transportation based on:

1. **Distance ≤ 2 units**: Walk (free, slower)
2. **Distance > 2 units AND sufficient cash**: Taxi (costs money, faster)
3. **Distance > 2 units AND insufficient cash**: No viable transportation (planning fails)

## Distance Matrix

```
         home_a  home_b  park  downtown
home_a      0      -      8       7
home_b      -      0      2       8
park        8      2      0       9
downtown    7      8      9       0
```

## Testing

Run the test suite:

```bash
# From umbrella root
mix test apps/aria_simple_travel
```

Test specific scenarios:

```elixir
# In IEx
iex> AriaSimpleTravel.validate_specification_compliance()
:ok

iex> {:ok, {final_state, solution_tree, info}} = AriaSimpleTravel.run_example(:alice_to_park)
iex> info.description
"Alice travels from home_a to park (requires taxi due to distance)"
```

## Architecture Integration

This app demonstrates integration with:

- **AriaState.RelationalState**: World state management with facts and entities
- **AriaEngine.Domain**: Domain definition with `use AriaEngine.Domain`
- **AriaEngineCore**: Planning and execution (`plan/3`, `run_lazy/3`, `run_lazy_tree/3`)
- **AriaHybridPlanner**: Goal achievement and method selection
- **AriaCore**: Multi-goal coordination

## R25W1398085 Compliance

This domain fully implements the unified durative action specification:

- ✅ Entity-capability model for resource management
- ✅ Temporal patterns (instant and durative actions)
- ✅ AriaEngine.Domain integration
- ✅ Proper `@action`, `@task_method`, and `@unigoal_method` attributes
- ✅ Goal format: `{"predicate", subject, value}`
- ✅ State validation using `AriaState.RelationalState.get_fact/3`

## Comparison with IPyHOP

| Aspect | IPyHOP Original | AriaSimpleTravel |
|--------|----------------|------------------|
| Planning | HTN task decomposition | AriaEngine temporal planning |
| Actions | Instant state changes | Instant + durative with ISO 8601 |
| Resources | Simple state variables | Entity-capability model |
| Execution | Sequential action list | Temporal solution tree |
| Coordination | Single agent | Multi-agent with resource allocation |

## Future Enhancements

Potential extensions to demonstrate additional R25W1398085 patterns:

- **Pattern 4 (Deadline)**: Appointments with fixed end times
- **Pattern 7 (Fixed interval)**: Scheduled bus routes
- **Pattern 8 (Validation)**: Complex multi-modal journeys
- **Commands**: Real-world failure handling (traffic, taxi unavailable)
- **Multigoal methods**: Optimizing multiple people's travel plans
- **Multitodo methods**: Batch processing of travel requests

This domain serves as a comprehensive example of temporal planning with durative actions, suitable for learning AriaEngine concepts and as a foundation for more complex planning domains.
