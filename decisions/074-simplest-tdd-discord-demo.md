# ADR-074: Simplest TDD Case for Discord Demo

**Status:** Active (June 15, 2025)

## Context

Based on ADR-035 (canonical temporal backtracking problem), ADR-069 (simple Discord frontend), and ADR-050 (temporal planner implementation), we need the absolute simplest test-driven development case that demonstrates temporal planning to a friend on Discord.

The goal is to create a minimal working demo that shows:

- Real temporal reasoning (not just sequential actions)
- Simple emoji-based visualization
- Shareable via web URL on Discord

## Decision

Implement a **1D (straight line) temporal coordination problem** using the simplest possible case from Maya's patrol scenario. Focus on one specific temporal conflict that requires backtracking. Use a single dimension to eliminate spatial complexity and focus purely on temporal reasoning.

## Simplest TDD Case: "Maya's 1D Patrol Coordination"

### Problem Setup (1D Straight Line)

- **Maya** 🔥 at position **5** - needs to cast Scorch but can't see target
- **Alex** 👁️ at position **3** - can scout and report enemy position  
- **Enemy** 🎯 at position **15** - will move to safety at tick 3
- **Goal**: Eliminate enemy before tick 3
- **1D Line**: All movement is on a single axis (0 ← → 20)

### The Temporal Conflict (1D Visualization)

```
Timeline: 0 ← → 20 (1D straight line)
                                
T0: Alex👁️  Maya🔥       Enemy🎯
    |3|    |5|           |15|
    
Initial Plan: Maya casts Scorch at tick 0
Problem: Distance = 10 units > Maya's vision (8 units)
Solution: Alex scouts first, then Maya casts
```

1. **Initial naive plan**: Maya casts Scorch at tick 0
2. **Conflict detected**: Maya can't see enemy (distance 10 > vision range 8)
3. **Backtrack required**: Must coordinate with Alex's scouting first
4. **New plan**: Alex scouts at tick 0, Maya casts at tick 1

### Implementation Plan

#### Phase 1: Failing Test (Red)

```elixir
defmodule AriaTemporalDemo.SimpleCoordinationTest do
  use ExUnit.Case
  
  test "maya requires alex scouting before scorch in 1D scenario" do
    # Initial state (1D positions)
    state = %{
      maya: %{pos: 5, vision_range: 8, abilities: [:scorch]},
      alex: %{pos: 3, abilities: [:scout]},
      enemy: %{pos: 15, hp: 100, will_escape_at: 3}
    }
    
    goal = {:eliminate, :enemy}
    
    # This should fail with vision conflict
    assert {:backtrack_required, :insufficient_vision} = 
      AriaPlanner.plan(state, goal)
  end
end
```

#### Phase 2: Minimal Implementation (Green)

```elixir
defmodule AriaPlanner do
  def plan(state, goal) do
    # Calculate 1D distance
    maya_to_enemy = abs(state.enemy.pos - state.maya.pos)
    if maya_to_enemy > state.maya.vision_range do
      {:backtrack_required, :insufficient_vision}
    else
      {:ok, [:scorch]}
    end
  end
end
```

#### Phase 3: Discord Frontend

```elixir
defmodule AriaDemo.LiveView do
  use Phoenix.LiveView
  
  def render(assigns) do
    ~H"""
    <div class="game-state">
      <h2>🎮 Aria Temporal Planning Demo</h2>
      
      <div class="battlefield">
        Maya 🔥 (3,5) Vision: 8 units<br>
        Alex 👁️ (4,4) Scout ready<br>
        Enemy 🎯 (15,5) Escapes at tick 3<br>
      </div>
      
      <div class="planning">
        <h3>Planning Result:</h3>
        <%= case @plan_result do %>
          <% {:backtrack_required, :insufficient_vision} -> %>
            ❌ Maya can't see enemy! Need coordination.<br>
            💡 Alex must scout first.
          <% {:ok, actions} -> %>
            ✅ Plan found: <%= Enum.join(actions, " → ") %>
        <% end %>
      </div>
      
      <button phx-click="replan">🔄 Try Planning</button>
    </div>
    """
  end
  
  def handle_event("replan", _, socket) do
    # Demo the planning logic
    state = %{
      maya: %{pos: {3,5}, vision_range: 8},
      alex: %{pos: {4,4}},
      enemy: %{pos: {15,5}}
    }
    
    result = AriaPlanner.plan(state, {:eliminate, :enemy})
    
    {:noreply, assign(socket, :plan_result, result)}
  end
end
```

## Success Criteria

1. **Red Test**: Test fails showing temporal conflict detection
2. **Green Test**: Minimal implementation passes the conflict detection  
3. **Web Demo**: Simple Phoenix LiveView shows the problem visually
4. **Discord Shareable**: URL works when shared in Discord
5. **Temporal Proof**: Demonstrates actual backtracking, not sequential planning

## Implementation Steps

- [ ] Create basic test case for vision conflict
- [ ] Implement minimal planner that detects the conflict
- [ ] Add Phoenix LiveView with emoji visualization
- [ ] Test sharing URL on Discord
- [ ] Extend to show actual coordination solution

## Related ADRs

- **ADR-035**: Canonical Temporal Backtracking Problem (source of Maya scenario)
- **ADR-069**: Simple Discord Frontend (emoji/text approach)
- **ADR-050**: Temporal Planner Implementation (foundation)

This represents the absolute minimum viable demo that proves temporal planning capabilities while being immediately shareable and understandable.
