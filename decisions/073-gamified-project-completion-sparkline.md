# ADR-073: Gamified Project Completion Sparkline

**Status:** Paused (June 15, 2025)

## Context

The project needs a real-time visualization of actual project completion progress that gamifies the development experience. This supersedes ADR-069's approach of removing interface components in favor of a positive, engaging visualization that uses real project metrics.

**Note:** This project is currently paused to focus on core game development priorities. Implementation will resume once the core game architecture is stable.

## Decision

Implement a gamified project completion sparkline in the Phoenix masthead flash message that:

1. **Uses real project metrics** - Not demo data or placeholders
2. **Displays as a true sparkline** - Small, inline chart suitable for masthead display
3. **Gamifies progress** - Presents completion data in an engaging, achievement-oriented way
4. **Updates dynamically** - Reflects current project state in real-time

## Implementation Plan

- [x] Create ADR-072 documenting the gamified sparkline approach
- [ ] Implement project metrics collection from real data sources
  - [ ] ADR completion percentage calculation
  - [ ] Test coverage metrics from actual test suites
  - [ ] Code implementation progress from git statistics
- [ ] Create sparkline generation service
  - [ ] Generate SVG sparkline from metrics data
  - [ ] Apply gamification styling (colors, achievement indicators)
  - [ ] Ensure inline display compatibility
- [ ] Integrate into Phoenix masthead flash message
  - [ ] Add sparkline to aria_coordinate layout template
  - [ ] Implement real-time updates via LiveView
  - [ ] Apply appropriate styling for masthead display
- [ ] Test with real project data
  - [ ] Verify accuracy of metrics collection
  - [ ] Confirm sparkline renders correctly in masthead
  - [ ] Validate gamification elements enhance user experience

## Related ADRs

- **ADR-069**: Aria Interface Removal (superseded by this approach)
- **ADR-071**: Project Status Summary Comprehensive Review (contains previous visualization experiments)

## Success Criteria

1. **Real metrics integration**: Sparkline displays actual project completion data
2. **True sparkline format**: Small, inline chart appropriate for masthead display
3. **Gamification elements**: Visual design encourages continued progress
4. **Phoenix integration**: Seamlessly embedded in aria_coordinate web interface
5. **Performance**: Updates efficiently without impacting page load times

## Consequences

### Positive

- Provides engaging, real-time project progress visibility
- Gamifies development workflow to encourage completion
- Uses actual data rather than placeholder content
- Integrates naturally into existing Phoenix web interface

### Risks

- Metrics calculation performance impact
- Sparkline rendering complexity
- Maintaining accuracy of real-time data

## Monitoring

Track the effectiveness of the gamified sparkline through:

- Developer engagement with progress visualization
- Accuracy of metrics representation
- Performance impact on Phoenix application
