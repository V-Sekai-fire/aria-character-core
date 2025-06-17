# ADR-087: Entity-Agent Timeline Graph Architecture

**Status:** Proposed (June 17, 2025)

## Context

ADR-085 identified several unsolved NPC planning problems requiring enhanced scheduling, multi-agent coordination, processes & events, and enhanced timed effects. The current architecture treats timelines as constraint-solving tools rather than living entities that grow and evolve with their owners.

**Current Problems:**

1. **Static Timeline Creation**: STN timelines are manually constructed for specific planning problems, not owned by entities
2. **No Agent Abstraction**: We have State (world facts) and STN (constraint networks), but no first-class Agent entity
3. **Manual LOD Management**: Level of detail changes require explicit calls, not automatic adaptation based on relevance
4. **Disconnected Coordination**: Multi-agent planning requires manual coordination rather than natural timeline bridging

**Key Insight:** Agents are entities with action capabilities, and every entity should own a timeline that automatically grows as they live, act, and interact in the world.

## Decision

Implement an Entity-Agent Timeline Graph Architecture where:

1. **Every Entity owns an auto-growing timeline**
2. **Agents are Entities with action capabilities** 
3. **Timelines automatically bridge during interactions**
4. **LOD scales dynamically based on relevance**
5. **No manual timeline management required**

### Core Architecture

```elixir
# Base abstraction - everything in the world
entity = Entity.new("chair_1")
|> Entity.set_property("type", "furniture")
|> Entity.set_property("material", "wood")
# Timeline grows when: moved, used, damaged, scheduled events affect it

# Agents are entities with action capabilities
npc = Entity.new("guard_npc")
|> Entity.set_property("type", "humanoid") 
|> Agent.make_agent()  # Gains action capabilities
|> Agent.add_capability(:patrol)
|> Agent.add_capability(:investigate)
# Timeline grows when: planning actions, executing actions, reacting to events, 
# being affected by others, plus all Entity timeline growth triggers
```

### Timeline Graph Management

```elixir
# Automatic bridging during interactions
TimelineGraph.on_interaction("guard_npc", "player") do
  # Timelines auto-bridge at interaction point
  # Guard's timeline LOD auto-promotes to :high
  # Shared temporal constraints created for conversation duration
end

# Automatic LOD management based on distance
TimelineGraph.on_distance_change("guard_npc", "player", distance: 50) do
  # Bridge stays for recent history
  # Guard's timeline LOD downgrades back to :medium
  # Future constraints disconnect
end
```

## Implementation Plan

### Phase 1: Core Entity-Agent System

- [ ] **AriaEngine.Entity** - Base entity abstraction with timeline ownership
  - [ ] Entity creation with automatic timeline attachment
  - [ ] Property management integrated with State system
  - [ ] Timeline growth triggers for passive events
  - [ ] Integration with existing AriaEngine.State predicate-subject-fact system

- [ ] **AriaEngine.Agent** - Entity extension with action capabilities
  - [ ] Agent behavior addition to existing entities
  - [ ] Action planning integration with timeline growth
  - [ ] Capability management and goal pursuit
  - [ ] Integration with existing AriaEngine planner

- [ ] **AriaEngine.TimelineGraph** - Inter-timeline connection management
  - [ ] Bridge creation and lifecycle management
  - [ ] Automatic LOD promotion and demotion
  - [ ] Connection triggers (proximity, interaction, communication)
  - [ ] Performance optimization for background entities

### Phase 2: Bridge Types and Behaviors

- [ ] **Proximity Bridges** - Spatial interaction management
  - [ ] Automatic bridging when entities are near each other
  - [ ] LOD scaling based on distance
  - [ ] Bridge strength attenuation over distance

- [ ] **Memory Bridges** - Persistent relationship management
  - [ ] Bridge creation from past interactions
  - [ ] Memory strength degradation over time
  - [ ] Influence on future decision-making

- [ ] **Communication Bridges** - Message and information transfer
  - [ ] Messenger-mediated timeline connections
  - [ ] Communication delay modeling
  - [ ] Information propagation across space

- [ ] **Conversation Bridges** - Real-time dialogue management
  - [ ] Direct conversation bridging between entities
  - [ ] External user integration (VRChat, Discord, web interfaces)
  - [ ] Real-time dialogue state synchronization
  - [ ] Cross-platform conversation continuity

- [ ] **Causal Bridges** - Action-at-a-distance effects
  - [ ] Spell effects, environmental impacts
  - [ ] Propagation delay modeling
  - [ ] Causal chain maintenance

### Phase 3: Advanced Coordination

- [ ] **Coordination Bridges** - Synchronized multi-agent actions
  - [ ] Shared synchronization points
  - [ ] Distributed coordination without central planning
  - [ ] Team behavior emergence from individual timelines

- [ ] **Environmental Timeline Integration**
  - [ ] World events affecting multiple entities
  - [ ] Weather, day/night cycles, scheduled events
  - [ ] Automatic timeline growth from environmental changes

## Timeline Growth Rules

### Automatic Growth Triggers

**All Entities:**
- Being affected by other entities (interactions received)
- Environmental events (weather changes, scheduled events)
- State changes (properties modified)
- Spatial events (being moved, collisions)

**Agents (additional triggers):**
- Planning actions (future timepoints added automatically)
- Executing actions (current timepoints updated automatically)
- Goal pursuit (timeline extends to include goal achievement)
- Reacting to sensory input (reactive timepoints added)

**No Manual Configuration:**
```elixir
# The system figures it out automatically based on entity nature
Entity.new("chair")        # Timeline grows when moved, used, damaged
Agent.make_agent(entity)   # Timeline now also grows from autonomous planning
```

## Integration with ADR-085 Problems

This architecture solves multiple ADR-085 unsolved problems:

### Enhanced Scheduling
**Solution:** Auto-growing timelines with dynamic LOD provide natural scheduling system
- Agent timelines automatically extend as they plan daily/weekly routines  
- LOD scaling ensures computational efficiency for background NPCs
- Timeline bridging enables automatic coordination between scheduling entities

### Multi-Agent Planning  
**Solution:** Timeline bridging enables automatic coordination between agents
- Agents planning coordinated actions automatically bridge their timelines
- Shared temporal constraints emerge naturally from interaction
- No central coordination required - emerges from individual timeline connections

### Processes & Events
**Solution:** Environmental events automatically grow entity timelines
- Weather changes, day/night cycles automatically added to affected entity timelines
- Resource depletion, environmental state changes propagate through entity network
- Continuous processes modeled as timeline growth rather than separate systems

### Enhanced Timed Effects/Goals
**Solution:** Living timelines naturally handle time-based effects
- Absolute time constraints integrated into timeline growth
- Deadline-based goals become natural timeline endpoints
- Failure handling through timeline branch management

## LOD Management Strategy

### Automatic LOD Scaling

**Ultra High LOD**: Player entities
- Millisecond precision planning and execution
- Full temporal constraint solving
- All bridge types active

**High LOD**: Entities directly interacting with ultra-high LOD entities  
- Second precision planning
- Active bridge management
- Promoted automatically during interactions

**Medium LOD**: Active NPCs in local area
- Minute precision planning
- Selective bridge activation
- Background autonomous behavior

**Low LOD**: Background entities and distant NPCs
- Hour precision planning
- Minimal bridge maintenance
- State-only updates until relevance increases

**Very Low LOD**: Completely background entities
- Daily precision planning  
- Bridge storage only
- Minimal computational overhead

### Dynamic Promotion/Demotion

```elixir
# Automatic LOD changes based on relevance
player_approaches_npc -> promote_npc_to_high_lod()
player_leaves_area -> demote_npc_to_medium_lod() 
npc_starts_important_quest -> promote_to_high_lod()
quest_completes -> demote_based_on_distance()
```

## Bridge Lifecycle Management

### Bridge Creation
- **Proximity**: Automatic when entities within interaction range
- **Memory**: Created after significant interactions, persist with decay
- **Communication**: Created when messages sent/received
- **Causal**: Created when actions affect distant entities
- **Coordination**: Created when agents plan coordinated activities

### Bridge Maintenance
- **Strength Decay**: Bridge influence weakens over time/distance
- **Relevance Updates**: Bridge importance changes based on ongoing interactions
- **Computational Budgets**: Bridge complexity managed based on available resources

### Bridge Cleanup
- **Automatic Pruning**: Remove bridges below relevance threshold
- **Memory Consolidation**: Convert active bridges to memory traces
- **Performance Optimization**: Maintain bridge indices for fast lookup

## Technical Architecture

### Module Structure

```elixir
# Core entity system
AriaEngine.Entity           # Base entity with timeline ownership
AriaEngine.Agent           # Entity extension with action capabilities
AriaEngine.TimelineGraph   # Bridge management and LOD coordination

# Bridge implementations  
AriaEngine.TimelineGraph.ProximityBridge     # Spatial interactions
AriaEngine.TimelineGraph.MemoryBridge        # Persistent relationships
AriaEngine.TimelineGraph.CommunicationBridge # Message transfer
AriaEngine.TimelineGraph.ConversationBridge  # Real-time dialogue (internal/external)
AriaEngine.TimelineGraph.CausalBridge        # Action-at-distance
AriaEngine.TimelineGraph.CoordinationBridge  # Synchronized actions

# LOD management
AriaEngine.TimelineGraph.LODManager          # Automatic scaling
AriaEngine.TimelineGraph.RelevanceCalculator # Bridge importance

# External integrations
AriaEngine.TimelineGraph.ExternalBridge      # VRChat, Discord, web interface connections
```

### Integration Points

**With Existing Systems:**
- **AriaEngine.State**: Entity properties integrate with predicate-subject-fact system
- **AriaEngine.Planner**: Agent planning triggers automatic timeline growth
- **AriaEngine.Timeline.STN**: Timeline constraints solved using existing STN system
- **AriaEngine.Domain**: Action capabilities defined through existing domain system

## Success Criteria

### Phase 1 Success
- [ ] Create entities with auto-growing timelines
- [ ] Convert entities to agents with action capabilities
- [ ] Basic proximity bridging between entity timelines
- [ ] Automatic LOD promotion/demotion

### Phase 2 Success  
- [ ] All bridge types implemented and functional
- [ ] Memory bridges persist and influence future decisions
- [ ] Communication bridges handle message delays
- [ ] Causal bridges maintain action-at-distance relationships

### Phase 3 Success
- [ ] Multi-agent coordination emerges from timeline bridging
- [ ] Environmental events automatically propagate through entity network
- [ ] Performance remains stable with 100+ entities at mixed LOD levels
- [ ] Player interactions feel natural and responsive

### Integration Success
- [ ] ADR-085 Enhanced Scheduling solved through auto-growing timelines
- [ ] ADR-085 Multi-Agent Planning solved through timeline bridging  
- [ ] ADR-085 Processes & Events solved through environmental timeline integration
- [ ] ADR-085 Enhanced Timed Effects/Goals solved through living timeline system

## Consequences

### Benefits
- **Natural NPC Behavior**: NPCs coordinate and behave organically through timeline interactions
- **Scalable Performance**: LOD system ensures computational efficiency across entity scales
- **Emergent Coordination**: Complex multi-entity behaviors emerge from simple bridging rules
- **Living World Feel**: Entities feel truly alive with evolving timelines representing their existence
- **Solves Multiple Problems**: Addresses several ADR-085 unsolved problems simultaneously

### Risks
- **Implementation Complexity**: Significant architectural change requiring careful integration
- **Performance Tuning**: LOD and bridge management requires optimization for large entity counts
- **Debugging Difficulty**: Timeline interactions may create complex emergent behaviors hard to debug
- **Memory Management**: Bridge persistence and timeline growth may require active memory management

### Monitoring
- **Performance Metrics**: Timeline growth rates, bridge creation/destruction rates, LOD distribution
- **Behavior Quality**: NPC coordination quality, player interaction responsiveness
- **Resource Usage**: Memory consumption, computational load distribution across LOD levels

## Related ADRs

- **ADR-085**: Unsolved Planner Problems for NPCs (problems solved by this architecture)
- **ADR-078**: Timeline Module PC-2 STN Implementation (underlying constraint solving)
- **ADR-034**: Definitive Temporal Planner Architecture (integration point)
- **ADR-083**: STN Timeline Segmentation Strategy (superseded by dynamic LOD approach)
