# R25W045E2B3: Aria Town - RDF-Powered NPC Demonstration System

<!-- @adr_serial R25W045E2B3 -->

**Status:** Future Work  
**Date:** June 17, 2025  
**Closure Date:** June 21, 2025  
**Priority:** Medium - Demo Implementation

## Context

Following completion of the Enhanced Scheduling System (ADR-085), we need a compelling visual demonstration that showcases autonomous NPC behavior in real-time. The Stanford Generative Agents paper provides an excellent reference implementation of believable AI agents living in a simulated town environment.

This demonstration will serve multiple purposes:

- Visual validation of our Enhanced Scheduling system capabilities
- Compelling demo for showcasing AriaEngine's NPC coordination
- Test bed for social AI behaviors and information diffusion
- Engaging "digital aquarium" suitable for side-screen monitoring with complete behavioral cycles every 20 minutes

## Decision

Implement **Aria Town Live** - a Phoenix LiveView-based NPC town simulation that replicates the visual style and core behaviors from the Generative Agents paper, enhanced with RDF.ex for sophisticated knowledge representation and **20-minute accelerated day cycles**.

### Core Architecture Decisions

1. **RDF.ex Knowledge Base**: Use semantic triples for NPC memory streams, relationships, and information diffusion tracking
2. **Phoenix LiveView**: Real-time web interface with 2D pixel art visual style
3. **20-Minute Day Cycles**: Complete daily behavioral patterns compressed into watchable timeframes
4. **Enhanced Scheduling Integration**: Leverage ADR-085's priority-based conflict resolution
5. **Conversation Engine**: Generate contextual dialogue based on RDF knowledge queries
6. **Information Diffusion Visualization**: Animated social network showing gossip propagation

## Temporal Architecture

### Day Cycle Structure (20 minutes = 1 simulation day)

- **Dawn (0-2 mins)**: NPCs wake up, morning routines, plan day
- **Morning (2-7 mins)**: Work activities, errands, initial social interactions  
- **Midday (7-10 mins)**: Peak activity, lunch, scheduled meetings
- **Afternoon (10-15 mins)**: Continued work, afternoon socializing, gossip spread
- **Evening (15-18 mins)**: Dinner, community events, information consolidation
- **Night (18-20 mins)**: NPCs return home, sleep preparations, cycle reset

### Technical Time Management

```elixir
defmodule AriaTown.TimeManager do
  @simulation_day_ms 20 * 60 * 1000     # 20 minutes
  @update_interval_ms 30 * 1000         # Update every 30 seconds
  @conversation_duration_ms 2 * 60 * 1000 # 2-minute conversations
  
  def current_time_of_day() do
    elapsed = rem(System.system_time(:millisecond), @simulation_day_ms)
    percentage = elapsed / @simulation_day_ms
    
    case percentage do
      p when p < 0.1 -> :dawn
      p when p < 0.35 -> :morning  
      p when p < 0.5 -> :midday
      p when p < 0.75 -> :afternoon
      p when p < 0.9 -> :evening
      _ -> :night
    end
  end
  
  def schedule_for_time(npc, time_of_day) do
    NPC.get_schedule(npc)[time_of_day]
  end
end
```

## Implementation Plan

### Phase 1: Core Infrastructure (1.5 hours)

- [x] Create aria_town_demo umbrella app
- [ ] Set up Phoenix LiveView with RDF.ex dependencies
- [ ] Define NPC ontology and knowledge representation
- [ ] Implement 20-minute day cycle timing system
- [ ] Basic grid layout with CSS pixel art styling
- [ ] Integration with AriaEngine Enhanced Scheduling

### Phase 2: NPC Behavior System (2 hours)

- [ ] RDF-based memory stream implementation
- [ ] Time-based NPC personality and schedule definitions
- [ ] Movement and pathfinding on 2D grid
- [ ] Activity bubble system (emoji representations change with time)
- [ ] Schedule conflicts via Enhanced Scheduling (peak during midday)

### Phase 3: Social Interaction Layer (2 hours)

- [ ] Proximity-based conversation triggering
- [ ] ~~SPARQL-powered~~ (Removed v0.2.0, RDF remains) dialogue generation using shared knowledge
- [ ] Speech bubble UI matching paper's visual style
- [ ] Information diffusion tracking and visualization
- [ ] Conversation memory persistence in RDF with timestamps

### Phase 4: Advanced Behaviors (1.5 hours)

- [ ] Emergency event system (town meetings override schedules)
- [ ] Social coordination scenarios (evening party planning)
- [ ] Day/night visual cycle with lighting changes
- [ ] Interactive features (click NPCs for internal state and schedule)
- [ ] Performance optimization for smooth 30-second updates

## Technical Specifications

### Dependencies

```elixir
{:rdf, "~> 1.1"},
{:sparql, "~> 0.3"},  # ~~SPARQL removed v0.2.0, RDF remains~~
{:phoenix_live_view, "~> 0.20"},
{:jason, "~> 1.4"}
```

### JSON-LD Context Schema (Chibifire.com)

```elixir
@chibifire_context %{
  "@context" => %{
    # Full URL semantic identifiers
    "Person" => "https://chibifire.com/schema/Person",
    "Location" => "https://chibifire.com/schema/Location", 
    "Activity" => "https://chibifire.com/schema/Activity",
    "Conversation" => "https://chibifire.com/schema/Conversation",
    
    # Relationship properties
    "knows" => "https://chibifire.com/schema/knows",
    "locatedAt" => "https://chibifire.com/schema/locatedAt",
    "engagedIn" => "https://chibifire.com/schema/engagedIn",
    "spokeWith" => "https://chibifire.com/schema/spokeWith",
    "heardAbout" => "https://chibifire.com/schema/heardAbout",
    "plansTo" => "https://chibifire.com/schema/plansTo",
    "remembers" => "https://chibifire.com/schema/remembers",
    
    # Temporal properties
    "timeOfDay" => "https://chibifire.com/schema/timeOfDay",
    "scheduledAt" => "https://chibifire.com/schema/scheduledAt",
    "timestamp" => "https://chibifire.com/schema/timestamp",
    
    # Social properties
    "personality" => "https://chibifire.com/schema/personality",
    "mood" => "https://chibifire.com/schema/mood",
    "priority" => "https://chibifire.com/schema/priority",
    "conflictsWith" => "https://chibifire.com/schema/conflictsWith"
  }
}
```

### Capped Persistence Strategy

- **Save Frequency**: Every 2 minutes with JSON-LD format
- **Conversation Cap**: 50 conversations per NPC maximum
- **Knowledge Cap**: 100 knowledge facts per NPC maximum  
- **File Size Limit**: 10MB JSON-LD file maximum
- **Time Window**: Keep memories from last 7 days (3 days under pressure)
- **Cleanup Strategy**: Remove oldest memories first, then low-importance facts
- **Chibifire.com Namespace**: Full URL identifiers for all entities (e.g., `https://chibifire.com/npc/alice`)

### Sample NPC Schedule (Time-Compressed)

```elixir
%Schedule{
  dawn: [:wake_up, :coffee, :check_weather],
  morning: [:garden_work, :greet_neighbors], 
  midday: [:grocery_shopping, :lunch_prep, :town_square_socializing],
  afternoon: [:reading, :house_cleaning, :afternoon_tea],
  evening: [:dinner_prep, :community_meeting, :evening_gossip],
  night: [:evening_reflection, :prepare_for_sleep]
}
```

### Demo Scenarios (Fit Within 20-Minute Cycles)

1. **Election Gossip**: Information spreads from morning through evening
2. **Schedule Conflicts**: Peak conflicts during midday activities
3. **Emergency Meetings**: Evening announcements interrupt normal schedules
4. **Social Events**: NPCs coordinate weekend party during evening planning phase

## Success Criteria

- [ ] 5-8 autonomous NPCs with distinct personalities and time-based schedules
- [ ] Complete 20-minute day cycles with clear behavioral phases
- [ ] Real-time visual updates every 30 seconds
- [ ] Contextual conversations based on RDF knowledge queries
- [ ] Information diffusion visualization completing within single cycles
- [ ] Integration with Enhanced Scheduling for realistic conflict resolution
- [ ] Pixel art visual style with day/night lighting transitions
- [ ] Interactive features allowing inspection of NPC schedules and internal state
- [ ] Performance stability with continuous 20-minute cycles

## Consequences

### Benefits

- **Perfect Demo Timing**: Complete behavioral cycles every 20 minutes for presentations
- **Engaging Monitoring**: Suitable for side-screen watching with clear progression
- **Compelling Visual Demonstration**: Shows AriaEngine capabilities through emergent behaviors
- **Test Bed for Social AI**: Rapid iteration on multi-agent coordination research
- **Reusable Foundation**: Time-accelerated framework for future NPC systems

### Risks

- **Performance Under Continuous Operation**: 20-minute cycles require stable real-time processing
- **RDF Query Performance**: Complex ~~SPARQL queries~~ (Removed v0.2.0, RDF remains) at 30-second intervals
- **Visual Complexity**: Rich interactions may overwhelm core scheduling demonstrations
- **Memory Management**: Continuous RDF growth without cleanup

### Mitigation Strategies

- **Optimize Update Frequency**: Critical path analysis for 30-second cycles
- **RDF Query Caching**: Pre-computed common patterns and relationships
- **Progressive Complexity**: Start with minimal NPCs, add features incrementally
- **Memory Cleanup**: Archive old conversations and events after each day cycle
- **Performance Monitoring**: Real-time metrics for cycle completion times

## Related ADRs

- **ADR-085**: Enhanced Scheduling System (foundation for conflict resolution)
- **R25W044B3F2**: Entity-Agent Timeline Graph Architecture (NPC state management)

## Segment Closure Note

**June 21, 2025:** This ADR is being marked as "Future Work" as part of the temporal planning segment closure. While the Enhanced Scheduling System (ADR-085) provides the foundation for NPC coordination, this demonstration system represents application-layer work that extends beyond the core temporal planning infrastructure. The RDF-powered town simulation would be an excellent showcase for the temporal planning capabilities but is not essential for the core functionality.

**Current Status:** Future work for demonstration and application development phases.

---

**Ready for Future Implementation**: This ADR establishes a complete, time-bounded demonstration system that showcases Enhanced Scheduling through compelling 20-minute social simulation cycles.
