# R25W044B3F2: Entity-Agent Timeline Graph Architecture

<!-- @adr_serial R25W044B3F2 -->

**Status:** Proposed (June 17, 2025)

## Context

ADR-085 identified several unsolved NPC planning problems requiring enhanced scheduling, multi-agent coordination, processes & events, and enhanced timed effects. The current architecture treats timelines as constraint-solving tools rather than living entities that grow and evolve with their owners.

**Current Problems:**

1. **Static Timeline Creation**: STN timelines are manually constructed for specific planning problems, not owned by entities
2. **No Agent Abstraction**: We have State (world facts) and STN (constraint networks), but no first-class Agent entity
3. **Manual LOD Management**: Level of detail changes require explicit calls, not automatic adaptation based on relevance
4. **Disconnected Coordination**: Multi-agent planning requires manual coordination rather than natural timeline bridging

**Key Insight:** Everything in the world is an entity with capabilities. Timelines are owned by entities and grow automatically based on their capabilities and interactions.

## Decision

Implement a pure Entity Timeline Graph Architecture where:

1. **Everything is an Entity** (following game networking ECS patterns)
2. **Capabilities determine behavior** (action capabilities = agent behavior)
3. **Every Entity owns an auto-growing timeline**
4. **Timelines automatically bridge during interactions**
5. **LOD scales dynamically based on relevance**
6. **No manual timeline management required**

### Core Architecture

```elixir
# Everything is an Entity - capabilities determine behavior
chair = AgentEntity.create_entity("chair_1", "Wooden Chair", %{type: "furniture", material: "wood"})
# Timeline grows when: moved, used, damaged, properties change

# NPCs are entities with action capabilities  
npc = AgentEntity.create_entity("guard_npc", "Tower Guard", %{type: "humanoid"})
|> AgentEntity.add_capabilities([:patrol, :investigate, :decision_making])
# is_currently_agent?(npc) -> true (has action capabilities)
# Timeline grows when: planning, executing actions, reacting, plus all entity triggers

# Players are entities with comprehensive action capabilities
player = AgentEntity.create_entity("player", "Hero", %{type: "player"}) 
|> AgentEntity.add_capabilities([:movement, :combat, :magic, :decision_making, :communication])
# Ultra-high LOD timeline with millisecond precision

# Environmental objects are entities that can gain capabilities dynamically
door = AgentEntity.create_entity("castle_door", "Main Gate", %{type: "portal", state: "closed"})
# Initially passive entity - timeline grows from environmental events
# Later: door |> AgentEntity.add_capabilities([:autonomous_operation]) -> automated door
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

### Phase 0: State System Modernization (FOUNDATION)

- [ ] **AriaEngine.State Refactoring** - Subject-Predicate-Fact migration for entity-centric architecture
  - [ ] Change internal storage from `{predicate, subject}` to `{subject, predicate}` key format
  - [ ] Update all API functions to natural entity-first order: `get_fact(state, subject, predicate)`
  - [ ] Refactor quantifiers: `exists?(state, subject_filter, predicate, fact_value)`
  - [ ] Update condition evaluation to `{subject, predicate, fact_value}` format
  - [ ] Migrate all existing domains, methods, and action definitions
  - [ ] Update comprehensive test suites for new API
  - [ ] Maintain backward compatibility during transition period

### Phase 1: Core Entity-Agent System (builds on existing AriaEngine.Timeline.AgentEntity)

- [ ] **Timeline Integration** - Connect existing AgentEntity with auto-growing timelines
  - [ ] Automatic timeline attachment when entities are created via `AgentEntity.create_entity/4`
  - [ ] Timeline growth triggers for capability transitions via `AgentEntity.add_capabilities/2`
  - [ ] Agent timeline growth when `AgentEntity.is_currently_agent?/1` returns true
  - [ ] Integration with modernized AriaEngine.State subject-predicate-fact system

- [ ] **Enhanced AgentEntity Integration** - Extend existing capability-based system
  - [ ] Timeline ownership: Every entity gets timeline on creation
  - [ ] Agent behavior: Timeline grows when capabilities indicate agency
  - [ ] Natural transitions: `transition_to_agent/2` and `transition_to_entity/1` trigger timeline LOD changes
  - [ ] Property-timeline bridge: `get_property/2` and `set_property/3` operations affect timeline growth

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

- Agent timelines automatically extend with arbitrary temporal patterns (micro-patterns to annual cycles)
- Multi-scale scheduling: minutes (guard checks) → hourly (rounds) → daily (meals) → weekly (market days) → seasonal (harvests) → annual (festivals)
- Dynamic pattern recognition: entities learn and adapt their own scheduling behaviors
- Conditional scheduling: weather-dependent, resource-driven, social-context activities
- Cross-entity pattern influence: schedule interconnections and emergent coordination
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
- **apps/aria_timeline/decisions/R25W0389D35**: Timeline Module PC-2 STN Implementation (underlying constraint solving)
- **R25W017DEAF**: Definitive Temporal Planner Architecture (integration point)
- **apps/aria_timeline/decisions/R25W040602B**: STN Timeline Segmentation Strategy (superseded by dynamic LOD approach)
