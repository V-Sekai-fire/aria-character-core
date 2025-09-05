# R25W1900000 - Neon Frontlines Domain Adaptation

## Status
Proposed

## Context
The Neon Frontlines City Block simulator requires adapting the existing Vsekai.GameDomain from `apps/aria_viewer/decisions/draft_vsekai_domain.exs` to work within a single neon-lit city block environment focused on cyberpunk logistics warfare.

## Decision
Adapt Vsekai.GameDomain to AriaNeonFrontlines.GameDomain with the following modifications:

1. **Namespace Migration**: Move from Vsekai.GameDomain to AriaNeonFrontlines.GameDomain
2. **Block Transfer Protocol**: Replace world hopping with fast in-memory block transfers
3. **Operative Archetypes**: Adapt 4 player archetypes for cyberpunk logistics warfare
4. **City Block Environment**: Single contained urban space with buildings, alleys, and chokepoints

## Implementation Plan

### Phase 1: Domain Structure Migration
- [ ] Create `apps/aria_neon_frontlines/lib/aria_neon_frontlines/game_domain.ex`
- [ ] Copy Vsekai.GameDomain structure and adapt namespace
- [ ] Update module references to AriaNeonFrontlines
- [ ] Test basic domain loading and validation

### Phase 2: Archetype Adaptation
- [ ] Local Socializer: join_world → command_squad → log_tactical_decision
- [ ] Block Explorer: visit_new_world → transfer_supplies (block transfer)
- [ ] Local Achiever: refine_resource → allocate_resources for logistics optimization
- [ ] Block Competitor: engage_in_combat → coordinate_firefight for tactical advantage

### Phase 3: Block Transfer Implementation
- [ ] Implement zero-IOPS in-memory state hand-off
- [ ] Replace world-based movement with local destination transfers
- [ ] Add block location metadata to all domain actions
- [ ] Test transfer performance and state consistency

## Consequences

### Positive
- **Single Responsibility**: Domain focused solely on Neon Frontlines city block
- **Performance**: Block transfers provide zero-IOPS local movement
- **Cyberpunk Theme**: Archetypes adapted for logistics warfare setting
- **Modular Design**: Clean separation from original Vsekai domain

### Negative
- **Breaking Changes**: Incompatible with original Vsekai.GameDomain
- **Migration Effort**: Requires complete domain rewrite and testing
- **Scope Limitation**: Cannot handle multi-world scenarios

## Success Criteria
- [ ] Domain loads successfully in AriaNeonFrontlines namespace
- [ ] All 4 operative archetypes function with block transfer protocol
- [ ] Zero-IOPS performance for local destination movement
- [ ] Full compatibility with AriaHybridPlanner.Domain framework

## Related Decisions
- R25W1900001: Operative Archetypes Implementation
- R25W1900002: Block Transfer Protocol Design
- R25W1900005: Simulation Engine Architecture
