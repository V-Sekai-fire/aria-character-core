# ADR-072: Gamified Project Completion Sparkline in Website Masthead

**Status:** Active (June 15, 2025)

## Context

The Aria Character Core project needs a gamification element to provide visual feedback on project progress and maintain engagement. A sparkline chart displaying project completion metrics would serve as an effective progress indicator while adding a game-like element to the user experience.

The current project lacks visual progress indicators, making it difficult for users to understand overall completion status and feel a sense of accomplishment as work progresses. A sparkline in the website masthead would provide immediate, persistent feedback on project health and completion.

This decision supersedes ADR-069, which covered general project status visualization approaches, by focusing specifically on gamified sparkline implementation using Phoenix's native capabilities.

## Decision

Implement a project completion sparkline chart as a gamification element in the website game's masthead/flash message area, generated server-side using Phoenix (Elixir) and displayed as a graphic visualization.

The sparkline will:

- Display real-time project completion metrics
- Serve as a persistent gamification element in the masthead
- Update dynamically based on actual project progress
- Be generated as a proper graphic (not Unicode text)
- Provide visual feedback that encourages continued engagement

## Implementation Plan

### Phase 1: Core Sparkline Generation

- [ ] Create `AriaInterface.Components.Sparkline` module for generating sparkline graphics
- [ ] Implement SVG-based sparkline generation with Phoenix LiveView
- [ ] Design project completion metrics calculation system
- [ ] Create sparkline data pipeline from project status sources

### Phase 2: Masthead Integration

- [ ] Integrate sparkline component into website masthead layout
- [ ] Implement flash message system for sparkline display
- [ ] Add real-time updates using Phoenix LiveView
- [ ] Style sparkline for optimal visibility and gamification appeal

### Phase 3: Gamification Features

- [ ] Add completion milestone indicators to the sparkline
- [ ] Implement color-coded progress states (progress, achievements, blockers)
- [ ] Create hover/interaction states for detailed progress information
- [ ] Add animation effects for progress updates

### Phase 4: Data Integration

- [ ] Connect to ADR completion tracking system
- [ ] Integrate with test suite pass/fail metrics
- [ ] Include code coverage and quality metrics
- [ ] Implement real-time data refresh mechanism

## Success Criteria

- [ ] Sparkline displays as a proper graphic (SVG) in the website masthead
- [ ] Chart updates in real-time based on actual project completion metrics
- [ ] Visual design effectively gamifies the project progress experience
- [ ] Performance impact is minimal (sub-100ms rendering time)
- [ ] Sparkline data accurately reflects current project status
- [ ] Implementation supersedes and improves upon ADR-069 approaches

## Consequences

### Positive

- **Enhanced engagement:** Gamification elements encourage continued project work
- **Visual progress feedback:** Immediate understanding of project health and completion
- **Phoenix-native solution:** Leverages existing framework capabilities
- **Real-time updates:** LiveView provides dynamic, responsive progress visualization
- **Professional appearance:** SVG graphics maintain quality at all scales

### Risks

- **Performance impact:** Real-time calculations and rendering could affect page load times
- **Data complexity:** Accurate project completion metrics require robust data aggregation
- **Maintenance overhead:** Sparkline accuracy depends on keeping metrics systems current
- **Visual design challenges:** Balancing gamification appeal with professional appearance

## Related ADRs

- **ADR-069**: Project Status Visualization (superseded by this ADR)
- **ADR-071**: Project Status Summary Comprehensive Review (context and metrics foundation)

## Monitoring

- Track sparkline rendering performance in production
- Monitor user engagement with gamified progress elements
- Verify accuracy of completion metrics against actual project status
- Assess visual effectiveness and user feedback on gamification elements
