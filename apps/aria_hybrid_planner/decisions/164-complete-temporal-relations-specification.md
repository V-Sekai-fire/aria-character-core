# ADR-164: Complete Temporal Relations Specification

<!-- @adr_serial R25W0138B78 -->

**Status:** Active  
**Date:** 2025-06-25  
**Priority:** HIGH

## Context

The temporal planner requires a comprehensive catalog of temporal relations to handle all types of temporal relationships in planning scenarios. Currently, temporal relations are scattered across multiple files and ADRs, making it difficult to understand the complete system capabilities.

**Current State:** Basic Allen relations partially implemented, advanced relations mentioned but not systematically defined  
**Target State:** Complete, well-documented temporal relations system with clear implementation patterns

## Decision

Implement a comprehensive temporal relations system supporting Allen's core relations, extended relations, event-based relations, multi-timeline coordination, periodic patterns, and probabilistic modeling.

## Complete Temporal Relations Catalog

### Allen's Core Relations (13 Relations)

**Language-neutral codes with mathematical symbols:**

#### Point Relations

- **`EQ`** (=): Intervals are identical
  - `A = B` → `A.start = B.start AND A.end = B.end`
  - STN: `{0, 0}` constraints between corresponding timepoints

- **`ADJ_F`** (→): A adjacent before B  
  - `A → B` → `A.end = B.start`
  - STN: `{0, 0}` constraint between A.end and B.start

- **`ADJ_B`** (←): A adjacent after B
  - `A ← B` → `B.end = A.start`  
  - STN: `{0, 0}` constraint between B.end and A.start

#### Containment Relations

- **`WITHIN`** (⊂): A contained within B
  - `A ⊂ B` → `B.start ≤ A.start AND A.end ≤ B.end`
  - STN: Non-positive constraints from B.start to A.start, A.end to B.end

- **`CONTAINS`** (⊃): A contains B
  - `A ⊃ B` → `A.start ≤ B.start AND B.end ≤ A.end`
  - STN: Non-positive constraints from A.start to B.start, B.end to A.end

- **`START_ALIGN`** (⊢): A and B start together, A ends first
  - `A ⊢ B` → `A.start = B.start AND A.end < B.end`
  - STN: `{0, 0}` for starts, negative constraint A.end to B.end

- **`START_EXTEND`** (⊢→): A and B start together, A ends after
  - `A ⊢→ B` → `A.start = B.start AND B.end < A.end`
  - STN: `{0, 0}` for starts, negative constraint B.end to A.end

- **`END_ALIGN`** (⊣): A and B end together, A starts after
  - `A ⊣ B` → `B.start < A.start AND A.end = B.end`
  - STN: Negative constraint B.start to A.start, `{0, 0}` for ends

- **`END_EXTEND`** (←⊣): A and B end together, A starts before
  - `A ←⊣ B` → `A.start < B.start AND A.end = B.end`
  - STN: Negative constraint A.start to B.start, `{0, 0}` for ends

#### Overlap Relations

- **`OVERLAP_F`** (⟩⟨): A overlaps B, A starts first
  - `A ⟩⟨ B` → `A.start < B.start < A.end < B.end`
  - STN: Negative constraints in sequence order

- **`OVERLAP_B`** (⟨⟩): A overlaps B, B starts first  
  - `A ⟨⟩ B` → `B.start < A.start < B.end < A.end`
  - STN: Negative constraints in sequence order

#### Separation Relations

- **`PRECEDES`** (<): A completely before B
  - `A < B` → `A.end < B.start`
  - STN: Negative constraint from A.end to B.start

- **`FOLLOWS`** (>): A completely after B
  - `A > B` → `B.end < A.start`
  - STN: Negative constraint from B.end to A.start

### Extended Relations

#### Flexible Relations

- **`FLEXIBLE`**: STN constraint ranges `[min, max]`

  ```elixir
  %FlexibleRelation{
    type: :flexible_before,
    interval_a: "task_1",
    interval_b: "task_2", 
    constraint: {-3600, -1800}  # 30-60 minutes before
  }
  ```

#### Conditional Relations  

- **`CONDITIONAL`**: Multiple STN branches with condition-based selection

  ```elixir
  %ConditionalRelation{
    type: :conditional_sequence,
    condition: {:state_fact, "weather", "sunny"},
    if_true: {:relation, :adjacent_before},
    if_false: {:relation, :flexible_before, {-7200, -3600}}
  }
  ```

#### Fuzzy Relations

- **`FUZZY`**: Uncertainty modeling with confidence intervals

  ```elixir
  %FuzzyRelation{
    type: :fuzzy_before,
    interval_a: "meeting_prep",
    interval_b: "meeting_start",
    uncertainty: %{
      type: :gaussian,
      mean: -1800,      # 30 minutes before
      std_dev: 300,     # ±5 minutes
      confidence: 0.95
    }
  }
  ```

#### Resource Relations

- **`RESOURCE_BOUND`**: Resource availability constraints
- **`MUTEX`**: Mutual exclusion constraints

  ```elixir
  %ResourceRelation{
    type: :mutex,
    intervals: ["cooking_task_1", "cooking_task_2"],
    resource: "kitchen_oven",
    constraint: :exclusive_access
  }
  ```

### Event-Based Relations (Oban-Powered)

#### Causal Relations

- **`TRIGGERS`**: Event A causes Event B

  ```elixir
  %TriggerRelation{
    trigger_event: "alarm_activated",
    triggered_event: "security_response",
    delay: {:range, 0, 300},  # 0-5 minutes
    probability: 0.95
  }
  ```

- **`PREVENTS`**: Event A blocks Event B

  ```elixir
  %PreventRelation{
    preventing_event: "system_maintenance",
    prevented_event: "user_login",
    duration: :while_active
  }
  ```

- **`ENABLES`**: Event A allows Event B

  ```elixir
  %EnableRelation{
    enabling_event: "authentication_success",
    enabled_event: "data_access",
    window: {:duration, 3600}  # 1 hour window
  }
  ```

#### Priority Relations

- **`PREEMPTS`**: Event A interrupts Event B

  ```elixir
  %PreemptRelation{
    preempting_event: "emergency_alert",
    preempted_event: "routine_task",
    resume_policy: :after_completion
  }
  ```

- **`YIELDS`**: Event A defers to Event B

  ```elixir
  %YieldRelation{
    yielding_event: "background_sync",
    priority_event: "user_interaction",
    defer_duration: {:adaptive, :until_idle}
  }
  ```

#### Propagation Relations

- **`CASCADES`**: Event A propagates through sequence

  ```elixir
  %CascadeRelation{
    initial_event: "server_failure",
    cascade_sequence: [
      {"load_balancer_redirect", {:delay, 5}},
      {"backup_server_activation", {:delay, 30}},
      {"client_notification", {:delay, 60}}
    ],
    propagation_rule: :sequential
  }
  ```

### Multi-Timeline Relations

#### Synchronization Relations

- **`SYNCHRONIZED`**: Identical events across timelines

  ```elixir
  %SynchronizedRelation{
    event_type: "daily_standup",
    timelines: ["team_alpha", "team_beta", "team_gamma"],
    sync_tolerance: 300,  # 5 minutes
    coordination_method: :oban_shared_queue
  }
  ```

- **`COORDINATED`**: Cross-timeline dependencies

  ```elixir
  %CoordinatedRelation{
    source_timeline: "development_team",
    source_event: "feature_complete",
    target_timeline: "qa_team", 
    target_event: "testing_start",
    dependency_type: :prerequisite
  }
  ```

- **`REPLICATED`**: Event replication across active timelines

  ```elixir
  %ReplicatedRelation{
    master_timeline: "primary_schedule",
    replica_timelines: ["backup_schedule_1", "backup_schedule_2"],
    replication_policy: :immediate,
    conflict_resolution: :master_wins
  }
  ```

#### Coordination Framework

- **`MULTI_TIMELINE`**: General coordination framework

  ```elixir
  %MultiTimelineRelation{
    coordination_type: :resource_sharing,
    participating_timelines: ["agent_1", "agent_2", "agent_3"],
    shared_resources: ["conference_room", "presentation_equipment"],
    allocation_strategy: :first_come_first_served
  }
  ```

### Periodic Relations

- **`PERIODIC`**: Recurring patterns with cron/interval support

  ```elixir
  %PeriodicRelation{
    event_template: "weekly_team_meeting",
    schedule: %{
      type: :cron,
      expression: "0 10 * * 1",  # Mondays at 10 AM
      timezone: "America/Vancouver"
    },
    duration: "PT1H",
    exceptions: ["2025-12-25", "2025-01-01"]  # Holiday exceptions
  }
  ```

### Probabilistic Relations

#### Likelihood Relations

- **`LIKELY_BEFORE`**: P(X occurs before Y) = p

  ```elixir
  %LikelihoodRelation{
    type: :likely_before,
    interval_a: "task_preparation",
    interval_b: "task_execution", 
    probability: 0.85,
    confidence_interval: {0.75, 0.95}
  }
  ```

#### Stochastic Relations

- **`STOCHASTIC`**: Random timing distributions

  ```elixir
  %StochasticRelation{
    event: "customer_arrival",
    distribution: %{
      type: :poisson,
      lambda: 0.5,  # Average 0.5 arrivals per minute
      time_unit: :minutes
    }
  }
  ```

#### Conditional Probability

- **`DEPENDENT_PROBABILITY`**: Conditional probability chains

  ```elixir
  %DependentProbabilityRelation{
    condition_event: "rain_detected",
    dependent_event: "outdoor_event_cancellation",
    probability_table: %{
      {:rain_detected, true} => 0.9,
      {:rain_detected, false} => 0.1
    }
  }
  ```

## Reserved Keywords and Stub Placeholders

To ensure immediate compatibility with ADRs 131-134 action specifications, all temporal relation keywords are reserved with stub implementations. This allows actions to reference temporal relations in their metadata without runtime errors while the full system is developed.

### Reserved Temporal Relation Keywords

**Allen's Core Relations (13 keywords):**

- `EQ`, `ADJ_F`, `ADJ_B`, `WITHIN`, `CONTAINS`, `START_ALIGN`, `START_EXTEND`, `END_ALIGN`, `END_EXTEND`, `OVERLAP_F`, `OVERLAP_B`, `PRECEDES`, `FOLLOWS`

**Extended Relations (4 keywords):**

- `FLEXIBLE`, `CONDITIONAL`, `FUZZY`, `MUTEX`, `RESOURCE_BOUND`

**Event-Based Relations (6 keywords):**

- `TRIGGERS`, `PREVENTS`, `ENABLES`, `PREEMPTS`, `YIELDS`, `CASCADES`

**Multi-Timeline Relations (4 keywords):**

- `SYNCHRONIZED`, `COORDINATED`, `REPLICATED`, `MULTI_TIMELINE`

**Advanced Relations (3 keywords):**

- `PERIODIC`, `STOCHASTIC`, `LIKELY_BEFORE`, `DEPENDENT_PROBABILITY`

### Stub Implementation Module

```elixir
# apps/aria_temporal_planner/lib/timeline/temporal_relations_stubs.ex
defmodule Timeline.TemporalRelationsStubs do
  @moduledoc """
  Stub implementations for temporal relations to ensure compatibility
  with action specifications while full system is under development.
  
  All functions return {:ok, :stub} to indicate placeholder status.
  """
  
  # Allen's Core Relations Stubs
  def allen_relation(:EQ, _interval_a, _interval_b, _opts \\ []), do: {:ok, :stub}
  def allen_relation(:ADJ_F, _interval_a, _interval_b, _opts \\ []), do: {:ok, :stub}
  def allen_relation(:ADJ_B, _interval_a, _interval_b, _opts \\ []), do: {:ok, :stub}
  def allen_relation(:WITHIN, _interval_a, _interval_b, _opts \\ []), do: {:ok, :stub}
  def allen_relation(:CONTAINS, _interval_a, _interval_b, _opts \\ []), do: {:ok, :stub}
  def allen_relation(:START_ALIGN, _interval_a, _interval_b, _opts \\ []), do: {:ok, :stub}
  def allen_relation(:START_EXTEND, _interval_a, _interval_b, _opts \\ []), do: {:ok, :stub}
  def allen_relation(:END_ALIGN, _interval_a, _interval_b, _opts \\ []), do: {:ok, :stub}
  def allen_relation(:END_EXTEND, _interval_a, _interval_b, _opts \\ []), do: {:ok, :stub}
  def allen_relation(:OVERLAP_F, _interval_a, _interval_b, _opts \\ []), do: {:ok, :stub}
  def allen_relation(:OVERLAP_B, _interval_a, _interval_b, _opts \\ []), do: {:ok, :stub}
  def allen_relation(:PRECEDES, _interval_a, _interval_b, _opts \\ []), do: {:ok, :stub}
  def allen_relation(:FOLLOWS, _interval_a, _interval_b, _opts \\ []), do: {:ok, :stub}
  
  # Extended Relations Stubs
  def flexible_relation(_interval_a, _interval_b, _constraint_range), do: {:ok, :stub}
  def conditional_relation(_condition, _if_true, _if_false), do: {:ok, :stub}
  def fuzzy_relation(_interval_a, _interval_b, _uncertainty_spec), do: {:ok, :stub}
  def mutex_relation(_intervals, _resource), do: {:ok, :stub}
  def resource_bound_relation(_intervals, _resource, _constraints), do: {:ok, :stub}
  
  # Event-Based Relations Stubs
  def trigger_relation(_trigger_event, _triggered_event, _opts), do: {:ok, :stub}
  def prevent_relation(_preventing_event, _prevented_event, _opts), do: {:ok, :stub}
  def enable_relation(_enabling_event, _enabled_event, _opts), do: {:ok, :stub}
  def preempt_relation(_preempting_event, _preempted_event, _opts), do: {:ok, :stub}
  def yield_relation(_yielding_event, _priority_event, _opts), do: {:ok, :stub}
  def cascade_relation(_initial_event, _cascade_sequence, _opts), do: {:ok, :stub}
  
  # Multi-Timeline Relations Stubs
  def synchronized_relation(_event_type, _timelines, _opts), do: {:ok, :stub}
  def coordinated_relation(_source, _target, _dependency_type), do: {:ok, :stub}
  def replicated_relation(_master, _replicas, _policy), do: {:ok, :stub}
  def multi_timeline_relation(_coordination_type, _timelines, _opts), do: {:ok, :stub}
  
  # Advanced Relations Stubs
  def periodic_relation(_event_template, _schedule, _opts), do: {:ok, :stub}
  def stochastic_relation(_event, _distribution), do: {:ok, :stub}
  def likely_before_relation(_interval_a, _interval_b, _probability), do: {:ok, :stub}
  def dependent_probability_relation(_condition, _dependent, _probability_table), do: {:ok, :stub}
  
  # Stub validation for action metadata
  def validate_temporal_relations(temporal_relations) when is_list(temporal_relations) do
    results = Enum.map(temporal_relations, &validate_single_relation/1)
    
    case Enum.find(results, fn {status, _} -> status == :error end) do
      nil -> {:ok, :all_stubs}
      {:error, reason} -> {:error, reason}
    end
  end
  
  defp validate_single_relation({:allen, relation_type, _target}) when relation_type in [
    :EQ, :ADJ_F, :ADJ_B, :WITHIN, :CONTAINS, :START_ALIGN, :START_EXTEND, 
    :END_ALIGN, :END_EXTEND, :OVERLAP_F, :OVERLAP_B, :PRECEDES, :FOLLOWS
  ], do: {:ok, :stub}
  
  defp validate_single_relation({:flexible, _type, _target, _constraint}) do
    {:ok, :stub}
  end
  
  defp validate_single_relation({:mutex, _target, _resource}) do
    {:ok, :stub}
  end
  
  defp validate_single_relation(unknown_relation) do
    {:error, "Unknown temporal relation: #{inspect(unknown_relation)}"}
  end
end
```

### Action Metadata Integration Stubs

**Compatible with ADR-131/134 action specifications:**

```elixir
# Example action using reserved temporal relation keywords
@action duration: "PT2H",
        requires_entities: [
          %{type: "agent", capabilities: [:cooking]},
          %{type: "oven", capabilities: [:heating]}
        ],
        temporal_relations: [
          {:allen, :PRECEDES, "gather_ingredients"},
          {:flexible, :before, "serve_meal", {-1800, -900}},
          {:mutex, "kitchen_cleanup", :exclusive_access},
          {:triggers, "cooking_complete", "cleanup_start"}
        ]
def cook_meal(state, [meal_type]) do
  # Pure state transformation - temporal relations handled by planner
  state
  |> State.set_fact("meal_status", meal_type, "cooking")
  |> State.set_fact("chef_status", "chef_1", "busy")
end
```

### Stub Bridge Integration

**Bridge layer stub for STN constraint generation:**

```elixir
# apps/aria_temporal_planner/lib/timeline/bridge_stubs.ex
defmodule Timeline.BridgeStubs do
  @moduledoc """
  Stub bridge layer for temporal relations to STN constraints.
  Returns placeholder constraints until full implementation.
  """
  
  def temporal_relation_to_stn_constraints({:allen, relation_type, _target}) do
    # Return placeholder STN constraint
    case relation_type do
      :PRECEDES -> [{:placeholder_end, :placeholder_start, {-999999, -1}}]
      :FOLLOWS -> [{:placeholder_start, :placeholder_end, {-999999, -1}}]
      :EQ -> [{:placeholder_start, :placeholder_start, {0, 0}}, {:placeholder_end, :placeholder_end, {0, 0}}]
      _ -> [{:placeholder_constraint, :placeholder_constraint, {-1, 1}}]
    end
  end
  
  def temporal_relation_to_stn_constraints({:flexible, _type, _target, {min, max}}) do
    [{:placeholder_end, :placeholder_start, {min, max}}]
  end
  
  def temporal_relation_to_stn_constraints({:mutex, _target, _resource}) do
    # Mutex constraints handled separately from STN
    [{:mutex_placeholder, :mutex_placeholder, :exclusive}]
  end
  
  def temporal_relation_to_stn_constraints(unknown_relation) do
    # Unknown relations get safe placeholder
    [{:unknown_placeholder, :unknown_placeholder, {-1, 1}}]
  end
end
```

### Compatibility Validation

**Validation function for action metadata:**

```elixir
# apps/aria_temporal_planner/lib/timeline/compatibility_validator.ex
defmodule Timeline.CompatibilityValidator do
  @moduledoc """
  Validates that action metadata temporal relations use only reserved keywords.
  Ensures compatibility between ADR-131/134 specifications and ADR-164 relations.
  """
  
  alias Timeline.TemporalRelationsStubs
  
  def validate_action_temporal_relations(action_metadata) do
    case Map.get(action_metadata, :temporal_relations) do
      nil -> 
        {:ok, :no_temporal_relations}
      
      temporal_relations when is_list(temporal_relations) ->
        TemporalRelationsStubs.validate_temporal_relations(temporal_relations)
      
      invalid ->
        {:error, "temporal_relations must be a list, got: #{inspect(invalid)}"}
    end
  end
  
  def validate_domain_compatibility(domain) do
    actions = Domain.get_all_actions(domain)
    
    validation_results = Enum.map(actions, fn {action_name, action_metadata} ->
      case validate_action_temporal_relations(action_metadata) do
        {:ok, _} -> {:ok, action_name}
        {:error, reason} -> {:error, action_name, reason}
      end
    end)
    
    errors = Enum.filter(validation_results, fn
      {:error, _, _} -> true
      _ -> false
    end)
    
    case errors do
      [] -> {:ok, :domain_compatible}
      errors -> {:error, "Domain compatibility errors: #{inspect(errors)}"}
    end
  end
end
```

## Implementation Architecture

### Core Module Structure

```elixir
# apps/aria_temporal_planner/lib/timeline/temporal_relations.ex
defmodule Timeline.TemporalRelations do
  @moduledoc """
  Complete temporal relations system supporting Allen's core relations,
  extended relations, event-based relations, and probabilistic modeling.
  """
  
  # Allen's core relations
  def allen_relation(type, interval_a, interval_b, opts \\ [])
  
  # Extended relations  
  def flexible_relation(interval_a, interval_b, constraint_range)
  def conditional_relation(condition, if_true, if_false)
  def fuzzy_relation(interval_a, interval_b, uncertainty_spec)
  
  # Event-based relations (Oban integration)
  def trigger_relation(trigger_event, triggered_event, opts)
  def prevent_relation(preventing_event, prevented_event, opts)
  def cascade_relation(initial_event, cascade_sequence, opts)
  
  # Multi-timeline relations
  def synchronized_relation(event_type, timelines, opts)
  def coordinated_relation(source, target, dependency_type)
  def replicated_relation(master, replicas, policy)
  
  # Periodic relations
  def periodic_relation(event_template, schedule, opts)
  
  # Probabilistic relations
  def likelihood_relation(interval_a, interval_b, probability)
  def stochastic_relation(event, distribution)
  def dependent_probability_relation(condition, dependent, probability_table)
end
```

### Integration with Action Specifications

**Compatible with ADRs 131-134 action metadata:**

```elixir
# ADR-134 style action with temporal relations
@action duration: "PT2H",
        requires_entities: [%{type: "agent", capabilities: [:cooking]}],
        temporal_relations: [
          {:allen, :precedes, "gather_ingredients"},
          {:flexible, :before, "serve_meal", {-1800, -900}},  # 15-30 min before
          {:mutex, "kitchen_cleanup", :exclusive_access}
        ]
def cook_meal(state, [meal_type]) do
  # Pure state transformation
  state
  |> State.set_fact("meal_status", meal_type, "cooking")
  |> State.set_fact("chef_status", "chef_1", "busy")
end
```

### STN Integration

**Bridge layer converts relations to STN constraints:**

```elixir
# apps/aria_temporal_planner/lib/timeline/bridge.ex
defmodule Timeline.Bridge do
  def temporal_relation_to_stn_constraints(relation) do
    case relation do
      %AllenRelation{type: :precedes} ->
        [{relation.interval_a.end, relation.interval_b.start, {-∞, -1}}]
        
      %FlexibleRelation{constraint: {min, max}} ->
        [{relation.interval_a.end, relation.interval_b.start, {min, max}}]
        
      %FuzzyRelation{uncertainty: uncertainty} ->
        bounds = calculate_confidence_bounds(uncertainty)
        [{relation.interval_a.end, relation.interval_b.start, bounds}]
    end
  end
end
```

### Oban Integration for Event Relations

**Event-based relations use Oban for execution:**

```elixir
# apps/aria_temporal_planner/lib/timeline/event_relations.ex
defmodule Timeline.EventRelations do
  use Oban.Worker, queue: :temporal_events
  
  def perform(%Oban.Job{args: %{"type" => "trigger", "trigger_event" => trigger}}) do
    case detect_trigger_event(trigger) do
      {:triggered, event_data} ->
        schedule_triggered_events(event_data)
        :ok
      :not_triggered ->
        :ok
    end
  end
end
```

## Dependencies

### Required Libraries

```elixir
# apps/aria_temporal_planner/mix.exs
{:oban, "~> 2.17"},           # Event-based relations
{:ecto_sqlite3, "~> 0.12"},   # Oban persistence
{:statistics, "~> 0.6.3"}     # Probabilistic relations
```

### Integration Points

- **STN Solver**: All relations convert to STN constraints via Bridge layer
- **Timeline System**: Relations operate on Timeline intervals and events
- **Action Specifications**: Relations declared in action metadata (ADRs 131-134)
- **Oban Queues**: Event-based relations use Oban for execution and scheduling

## Success Criteria

### Core Relations (Phase 1)

- [ ] All 13 Allen relations implemented with language-neutral codes
- [ ] STN constraint generation for each Allen relation
- [ ] Integration with existing Timeline and Bridge systems
- [ ] Comprehensive test coverage for core relations

### Extended Relations (Phase 2)  

- [ ] Flexible, conditional, and fuzzy relations functional
- [ ] Resource and mutex relations working with STN constraints
- [ ] Bridge layer properly handles extended relation types
- [ ] Performance optimization for complex relation processing

### Event-Based Relations (Phase 3)

- [ ] Oban integration for triggers, prevents, enables relations
- [ ] Priority relations (preempts, yields) working with Oban queues
- [ ] Cascade relations with proper event propagation
- [ ] Multi-timeline coordination via shared Oban database

### Advanced Relations (Phase 4)

- [ ] Periodic relations with cron scheduling
- [ ] Probabilistic relations using Statistics library
- [ ] Complete integration with action specification system
- [ ] Documentation and examples for all relation types

## Related ADRs

- **ADR-131**: Unified Durative Action Specification (action metadata integration)
- **ADR-132**: Fix Duration Handling Precision Loss (temporal specification compatibility)
- **ADR-133**: Planner Standardization Open Problems (system integration)
- **ADR-134**: Unified Action Specification Examples (usage patterns)
- **ADR-152**: Complete Temporal Relations System Implementation (parent ADR - now focused on bug fixes)
- **ADR-153**: STN Fixed-Point Constraint Prohibition (STN integration requirements)

## Implementation Notes

### Language-Neutral Design

All relation codes use mathematical symbols and English abbreviations to support internationalization:

- Symbols: `=`, `→`, `←`, `⊂`, `⊃`, `⊢`, `⊣`, `⟩⟨`, `⟨⟩`, `<`, `>`
- Codes: `EQ`, `ADJ_F`, `ADJ_B`, `WITHIN`, `CONTAINS`, etc.
- Descriptions: Translatable strings for UI display

### Performance Considerations

- **STN Constraint Generation**: Optimized Bridge layer processing
- **Oban Event Processing**: Efficient queue management for event relations
- **Probabilistic Calculations**: Cached distribution sampling for performance
- **Multi-Timeline Coordination**: Minimal cross-timeline communication overhead

### Error Handling

- **Invalid Relations**: Clear error messages for unsupported relation combinations
- **STN Conflicts**: Graceful handling of inconsistent temporal constraints
- **Event Failures**: Robust error recovery for Oban-based event relations
- **Probabilistic Edge Cases**: Proper handling of extreme probability values

This comprehensive temporal relations specification provides the foundation for sophisticated temporal reasoning in the AriaEngine planning system.
