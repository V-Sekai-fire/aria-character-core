## AriaCore External API Compliance Status

**Current State**: AriaCore.ex provides basic delegation functions but is missing critical ADR-specified APIs

**Target State**: Full compliance with ADR R25W1398085 unified durative action specification

### Missing Critical APIs

- [x] `plan/3` - Plan generation without execution
- [x] `run_lazy/3` - Planning + execution in one step  
- [x] `run_lazy_tree/3` - Execute pre-made solution tree

### Incomplete Method Type Support

- [ ] Verify @multigoal_method delegation  
- [ ] Verify @multitodo_method delegation
- [ ] Add missing method type documentation

### Temporal Pattern Coverage Gaps

- [ ] Test all 8 temporal patterns from ADR
- [ ] Verify ISO 8601 duration parsing
- [ ] Validate constraint checking logic

### Entity Model Compliance

- [ ] Verify capability-based entity matching
- [ ] Test "everything is an entity" pattern
- [ ] Validate entity registry integration

### State Validation Compliance  

- [ ] Enforce {predicate, subject, value} goal format
- [ ] Verify direct fact checking pattern
- [ ] Remove any complex state evaluation functions

### Integration Testing Requirements

- [ ] End-to-end domain creation workflow
- [ ] Complete cooking domain example from ADR
- [ ] Cross-app communication via external API only
