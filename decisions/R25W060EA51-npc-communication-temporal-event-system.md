# 103 - NPC Communication and Temporal Event System

<!-- @adr_serial R25W060EA51 -->

## Status

Proposed (June 18, 2025)

## Context

Analysis of ADR-085 "Unsolved Planner Problems for NPCs" revealed that the current AriaEngine.Scheduler already provides robust capabilities for multi-agent coordination, resource management, and capability-based task assignment. However, two key gaps prevent full NPC behavioral realism:

1. **Temporal Event Gaps**: While the scheduler uses DateTime extensively and can handle discrete activities with durations, it lacks automatic time-triggered effects and recurring schedule management.

2. **Inter-Agent Communication Gaps**: The scheduler coordinates multiple entities effectively through centralized planning, but NPCs cannot communicate directly with each other for dynamic collaboration, information sharing, or negotiation.

### Current Scheduler Strengths

The AriaEngine.Scheduler already solves many "multi-agent" problems through:

- **Entity Management**: Multiple NPCs with different capabilities and availability windows
- **Resource Conflict Resolution**: Priority-based allocation with temporal coordination
- **Capability-Based Assignment**: Automatic task distribution based on NPC skills
- **Comprehensive Analytics**: Activity logging, resource utilization tracking, timeline generation

### Identified Gaps

**Enhanced Timed Effects/Goals (ADR-085 Phase 2)**:

- No automatic time-triggered effects ("increase hunger every hour")
- No recurring schedule support ("work starts at 9 AM daily")
- No deadline-based failure handling ("become cranky if no meal by 6 PM")

**Multi-Agent Communication (ADR-085 Phase 3)**:

- No inter-NPC message passing for coordination
- No dynamic group formation or collaboration requests
- No information sharing between NPCs
- No resource negotiation capabilities

## Decision

Extend the current AriaEngine.Scheduler with two complementary systems rather than replacing the core architecture:

1. **Temporal Event System**: Integrate cron-like scheduling for automatic time-triggered effects
2. **NPC Communication System**: Implement mailbox pattern for inter-agent message passing

This approach preserves the scheduler's proven coordination capabilities while adding the missing temporal and communication features needed for realistic NPC behavior.

## Implementation Plan

### Phase 1: Temporal Event System Integration

#### Cron-Like Scheduling for Time-Triggered Effects

```elixir
# Automatic recurring effects using cron patterns
defmodule NPCTemporalEffects do
  @moduledoc """
  Handles time-triggered effects for NPCs using cron-like scheduling.
  """

  def schedule_recurring_effect(npc_id, effect, cron_pattern) do
    # Schedule using cron pattern (e.g., "0 * * * *" for hourly)
    CronScheduler.schedule(cron_pattern, fn ->
      apply_effect_to_npc(npc_id, effect)
    end)
  end

  def schedule_daily_routine(npc_id, routine, start_time) do
    # Daily routine (e.g., "0 9 * * *" for 9 AM daily)
    cron_pattern = build_daily_cron(start_time)

    CronScheduler.schedule(cron_pattern, fn ->
      execute_npc_routine(npc_id, routine)
    end)
  end

  defp execute_npc_routine(npc_id, routine) do
    # Get NPC entity and convert routine to activities
    npc = get_npc_entity(npc_id)
    activities = convert_routine_to_activities(routine)

    # Use existing scheduler for activity coordination
    {:ok, result} = AriaEngine.Scheduler.schedule_activities(
      "#{npc_id}_daily_routine",
      activities,
      entities: [npc],
      resources: get_available_resources(),
      simulation_mode: false
    )

    # Execute the scheduled activities
    execute_schedule(result.schedule)
  end
end
```

#### Deadline-Based Goal Management

```elixir
defmodule NPCDeadlineManager do
  @moduledoc """
  Manages time-based goals and deadlines for NPCs.
  """

  def set_goal_deadline(npc_id, goal, deadline_time) do
    # Schedule deadline check
    time_until_deadline = DateTime.diff(deadline_time, DateTime.utc_now(), :millisecond)

    Process.send_after(self(), {:check_deadline, npc_id, goal}, time_until_deadline)
  end

  def handle_info({:check_deadline, npc_id, goal}, state) do
    case check_goal_completion(npc_id, goal) do
      :completed ->
        # Goal met, no action needed
        :ok
      :failed ->
        # Apply failure consequences
        apply_deadline_failure(npc_id, goal)

        # Optionally reschedule or create recovery activities
        create_recovery_activities(npc_id, goal)
    end

    {:noreply, state}
  end
end
```

### Phase 2: NPC Communication System

#### Mailbox Pattern for Inter-Agent Communication

```elixir
defmodule NPCMailbox do
  @moduledoc """
  Handles message passing between NPCs for coordination and information sharing.
  """

  use GenServer

  # Public API
  def send_message(from_npc_id, to_npc_id, message) do
    GenServer.cast({:via, Registry, {NPCRegistry, to_npc_id}},
                   {:message, from_npc_id, message})
  end

  def broadcast_to_group(from_npc_id, group_id, message) do
    group_members = get_group_members(group_id)
    Enum.each(group_members, fn npc_id ->
      send_message(from_npc_id, npc_id, message)
    end)
  end

  def check_messages(npc_id) do
    GenServer.call({:via, Registry, {NPCRegistry, npc_id}}, :get_messages)
  end

  # GenServer callbacks
  def handle_cast({:message, from_npc, message}, %{messages: messages} = state) do
    new_messages = [{from_npc, message, DateTime.utc_now()} | messages]
    {:noreply, %{state | messages: new_messages}}
  end

  def handle_call(:get_messages, _from, %{messages: messages} = state) do
    {:reply, messages, %{state | messages: []}}
  end
end
```

#### Message-Triggered Scheduling

```elixir
defmodule NPCBehavior do
  @moduledoc """
  Processes NPC messages and triggers appropriate scheduling responses.
  """

  def process_messages(npc_id) do
    messages = NPCMailbox.check_messages(npc_id)

    Enum.each(messages, fn {from_npc, message, timestamp} ->
      handle_message(npc_id, from_npc, message, timestamp)
    end)
  end

  defp handle_message(npc_id, from_npc, message, _timestamp) do
    case message do
      {:request_help, task} ->
        # Create new activity to help other NPC
        help_activity = create_help_activity(task, from_npc)

        # Use scheduler to plan the help
        AriaEngine.Scheduler.schedule_activities(
          "help_#{from_npc}",
          [help_activity],
          entities: [get_npc_entity(npc_id)],
          resources: get_available_resources()
        )

      {:share_info, info} ->
        # Update NPC's knowledge state
        update_npc_knowledge(npc_id, info)

      {:negotiate_resource, resource, terms} ->
        # Decide whether to accept trade
        if should_accept_trade?(npc_id, resource, terms) do
          NPCMailbox.send_message(npc_id, from_npc, {:accept_trade, resource})
          # Reschedule activities to accommodate trade
          reschedule_for_trade(npc_id, resource, terms)
        end

      {:alert, alert_type, location} ->
        # Respond to alerts (guards, emergencies, etc.)
        response_activity = create_alert_response(alert_type, location)

        # High priority scheduling for alerts
        AriaEngine.Scheduler.schedule_activities(
          "alert_response_#{alert_type}",
          [response_activity],
          entities: [get_npc_entity(npc_id)],
          constraints: %{priority: :critical}
        )
    end
  end
end
```

### Phase 3: Integration and Coordination

#### Unified NPC Management System

```elixir
defmodule NPCCoordinator do
  @moduledoc """
  Coordinates temporal events, communication, and scheduling for NPCs.
  """

  def start_npc_systems(npc_configs) do
    Enum.each(npc_configs, fn npc_config ->
      npc_id = npc_config.id

      # Start mailbox for communication
      NPCMailbox.start_link(npc_id)

      # Schedule recurring effects
      Enum.each(npc_config.recurring_effects, fn {effect, cron_pattern} ->
        NPCTemporalEffects.schedule_recurring_effect(npc_id, effect, cron_pattern)
      end)

      # Schedule daily routines
      if npc_config.daily_routine do
        NPCTemporalEffects.schedule_daily_routine(
          npc_id,
          npc_config.daily_routine,
          npc_config.work_start_time
        )
      end

      # Schedule regular message processing
      schedule_message_processing(npc_id)
    end)
  end

  defp schedule_message_processing(npc_id) do
    # Process messages every 30 seconds using cron
    CronScheduler.schedule("*/30 * * * * *", fn ->
      NPCBehavior.process_messages(npc_id)
    end)
  end
end
```

## Example Usage Scenarios

### Scenario 1: Guard Patrol Coordination

```elixir
# Guard 1 sees suspicious activity
NPCMailbox.broadcast_to_group("guard_1", "patrol_group",
  {:alert, "suspicious_activity", location: {x: 100, y: 200}})

# Other guards receive alert and automatically reschedule to investigate
# High-priority alert activities override normal patrol schedules
```

### Scenario 2: Kitchen Staff Coordination

```elixir
# Head cook realizes they need help during busy period
NPCMailbox.send_message("head_cook", "assistant_cook",
  {:request_help, "prep_vegetables"})

# Assistant cook receives message and adds help activity to schedule
# Scheduler automatically coordinates shared kitchen resources
```

### Scenario 3: Merchant Information Network

```elixir
# Merchant learns about bandit activity affecting trade routes
NPCMailbox.broadcast_to_group("merchant_1", "traders_guild",
  {:share_info, "bandits_on_east_road"})

# All merchants update their knowledge and reschedule travel plans
# Scheduler automatically avoids dangerous routes in future planning
```

### Scenario 4: Time-Based NPC Routines

```elixir
# Baker starts work at 6 AM daily
NPCTemporalEffects.schedule_daily_routine("baker_npc",
  ["prepare_dough", "heat_ovens", "bake_bread"], "0 6 * * *")

# Hunger increases every hour for all NPCs
NPCTemporalEffects.schedule_recurring_effect("all_npcs",
  "increase_hunger", "0 * * * *")

# Tavern closes at midnight
NPCTemporalEffects.schedule_daily_routine("tavern_keeper",
  ["close_tavern", "clean_tables", "lock_doors"], "0 0 * * *")
```

## Success Criteria

### Phase 1 Success Criteria (Temporal Events)

- [ ] NPCs follow time-based daily routines using cron scheduling
- [ ] Automatic effects (hunger, fatigue, etc.) trigger on schedule
- [ ] Deadline-based goals with failure handling work correctly
- [ ] Integration with existing scheduler maintains performance

### Phase 2 Success Criteria (Communication)

- [ ] NPCs can send and receive messages reliably
- [ ] Message-triggered activities integrate with scheduler
- [ ] Group communication and broadcasting work correctly
- [ ] Resource negotiation between NPCs functions properly

### Phase 3 Success Criteria (Integration)

- [ ] Combined temporal + communication scenarios work seamlessly
- [ ] System scales to handle multiple NPCs with complex interactions
- [ ] Performance remains acceptable for real-time virtual environments
- [ ] All features integrate cleanly with existing AriaEngine architecture

## Consequences/Risks

### Benefits

- **Preserves Existing Investment**: Builds on proven scheduler architecture
- **Modular Design**: Each system can be developed and tested independently
- **Realistic NPC Behavior**: Enables complex, dynamic NPC interactions
- **Scalable Architecture**: Can handle growing numbers of NPCs and interactions

### Risks

- **Complexity Management**: Multiple interacting systems require careful coordination
- **Performance Overhead**: Message passing and cron scheduling add computational cost
- **State Synchronization**: Ensuring consistency between temporal events and communication
- **Debugging Difficulty**: Distributed behavior can be harder to trace and debug

### Mitigation Strategies

- **Comprehensive Testing**: Extensive integration tests for all system combinations
- **Performance Monitoring**: Track system performance under various NPC loads
- **Clear Interfaces**: Well-defined APIs between temporal, communication, and scheduling systems
- **Gradual Rollout**: Implement and test each phase independently before integration

## Related ADRs

- **ADR-085**: Unsolved Planner Problems for NPCs (parent problem definition)
- **R25W044B3F2**: Entity-Agent Timeline Graph Architecture (alternative approach)
- **ADR-086**: Implement Durative Actions (foundation for temporal capabilities)
- **R25W057B149**: Extract Scheduler Remove MCP (scheduler architecture decisions)
- **R25W058D6B9**: Reconnect Scheduler with Hybrid Planner (scheduler integration)

## Implementation Notes

This ADR addresses the core gaps identified in ADR-085 while leveraging the existing scheduler's strengths. The solution provides a clear path to realistic NPC behavior without requiring a complete architectural overhaul.

The key insight is that most "unsolved" multi-agent problems can be solved by adding **temporal automation** (cron) and **communication primitives** (mailbox) to the existing **coordination engine** (scheduler).
