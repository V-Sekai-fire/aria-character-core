# ADR-067: Timestrike Lottie Frame Rendering Phoenix Server

**Status:** Proposed

**Date:** June 15, 2025

## Context

Timestrike requires sophisticated visual representation of temporal game states, character actions, and environmental changes. The current implementation lacks a robust rendering system that can handle complex animations and visual effects needed for an engaging real-time tactical experience.

Lottie (Bodymovin) animations provide a lightweight, scalable format for complex animations that can be exported from After Effects and rendered efficiently across platforms. This format is particularly well-suited for:

- Character action animations
- Environmental effect visualizations
- UI state transitions
- Real-time status indicators

**ThorVG Partnership Opportunity**: As development partners with ThorVG, we have access to their super lightweight vector graphics engine that natively supports Lottie rendering. ThorVG is already powering major platforms including Tizen OS, Godot, LVGL, and dotLottie player, making it an ideal foundation for our rendering needs.

The challenge is integrating ThorVG's Lottie rendering capabilities with Timestrike's real-time game state updates through a Phoenix server architecture that maintains performance and synchronization.

## Decision

Implement a Phoenix server-based Lottie frame rendering system leveraging our development partnership with ThorVG that:

1. **Integrates ThorVG as the core rendering engine** for native Lottie animation processing
2. **Serves as a rendering gateway** between Timestrike game state and visual representation
3. **Provides real-time frame data** to frontend clients via Phoenix channels
4. **Maintains animation state synchronization** across multiple connected clients
5. **Leverages ThorVG's proven performance** in production environments (Tizen OS, Godot, etc.)

## Implementation Plan

- [ ] **ThorVG Integration**
  - [ ] Set up ThorVG development environment and dependencies
  - [ ] Create Elixir NIF wrapper for ThorVG Lottie rendering functions
  - [ ] Implement basic Lottie file loading and parsing through ThorVG
  - [ ] Build frame extraction and rendering pipeline using ThorVG APIs

- [ ] **Phoenix Server Setup**
  - [ ] Create dedicated Phoenix application for ThorVG-powered rendering
  - [ ] Set up WebSocket channels for real-time frame data transmission
  - [ ] Implement HTTP endpoints for animation asset management
  - [ ] Create rendering job queue system for performance optimization

- [ ] **Timestrike Integration**
  - [ ] Define game state to animation mapping protocols
  - [ ] Implement real-time synchronization between game events and animation frames
  - [ ] Create animation trigger system based on temporal game state changes
  - [ ] Build fallback rendering for non-animated states

- [ ] **Performance Optimization**
  - [ ] Implement frame pre-rendering and caching strategies
  - [ ] Create animation pooling system for memory efficiency
  - [ ] Build adaptive quality system based on client capabilities
  - [ ] Optimize WebSocket message formats for minimal bandwidth usage

- [ ] **Testing and Validation**
  - [ ] Create test suite for Lottie parsing and frame extraction
  - [ ] Build integration tests with Timestrike game state changes
  - [ ] Performance testing under multiple client connections
  - [ ] Visual regression testing for animation accuracy

## Technical Considerations

### ThorVG Integration Approach

**Partnership Advantages:**

- **Native Lottie Support:** ThorVG provides optimized, battle-tested Lottie rendering
- **Production Proven:** Already powering major platforms and applications
- **Performance Optimized:** Super lightweight engine designed for real-time usage
- **Cross-Platform:** Consistent rendering across different target platforms
- **Active Development:** Ongoing partnership ensures continued support and improvements

**Integration Strategy:**

- **Elixir NIF Implementation:** Direct integration with ThorVG C++ APIs for maximum performance
- **Resource Management:** Leverage ThorVG's efficient memory management for animation assets
- **Rendering Pipeline:** Utilize ThorVG's optimized frame rendering for real-time updates

### Architecture Decisions

- **ThorVG as Core Engine:** Native performance with proven reliability
- **Phoenix Channel Communication:** Low-latency real-time updates to clients
- **State-Driven Animation:** Game state controls animation timing, not animation timelines
- **Horizontal Scaling:** Phoenix clustering with shared ThorVG rendering resources

## Success Criteria

- [ ] **Functional Requirements**
  - Phoenix server successfully integrates ThorVG for Lottie rendering
  - Real-time frame updates synchronized with Timestrike game state
  - Multiple clients receive consistent animation frames
  - Smooth animation playback with minimal latency (<100ms)
  - ThorVG rendering engine handles complex Lottie animations efficiently

- [ ] **Performance Requirements**
  - Support for at least 10 concurrent clients with 60fps animations
  - Memory usage remains stable under continuous operation
  - Frame rendering latency under 16ms for 60fps target
  - Graceful degradation under high load conditions

- [ ] **Integration Requirements**
  - Seamless integration with existing Timestrike architecture
  - No breaking changes to current game state management
  - Backwards compatibility with non-animated rendering modes
  - Clear API documentation for animation integration

## Risks and Mitigation

### Technical Risks

- **NIF Integration Complexity:** Elixir-ThorVG integration may require careful resource management
  - *Mitigation:* Start with simple integration, leverage ThorVG community support through partnership
- **Performance Under Load:** Real-time rendering may hit bottlenecks with multiple clients
  - *Mitigation:* Comprehensive load testing and ThorVG's proven optimization strategies
- **Animation Synchronization:** Complex animations may drift from game state timing
  - *Mitigation:* Implement robust state synchronization with ThorVG's precise frame control

### Implementation Risks

- **Partnership Dependencies:** Reliance on ThorVG development timeline and priorities
  - *Mitigation:* Maintain close communication through partnership, plan fallback approaches
- **Memory Management:** Large animation assets may consume excessive resources
  - *Mitigation:* Leverage ThorVG's efficient resource management and implement asset streaming
- **Platform Compatibility:** ThorVG integration across different deployment environments
  - *Mitigation:* Test across target platforms, utilize ThorVG's cross-platform design

## Related ADRs

- **ADR-005**: Timestrike Test Domain - Provides game domain context
- **ADR-006**: Game Engine Real-time Execution - Real-time requirements
- **ADR-008**: Web Interface Implementation - Frontend integration points
- **ADR-028**: ThreeJS 3D Visualization Architecture - Alternative visualization approach

## Future Considerations

- **ThorVG Feature Expansion:** Leverage additional ThorVG capabilities as they develop
- **Animation Authoring Integration:** Direct pipeline from design tools to ThorVG rendering
- **Dynamic Animation Generation:** Procedural animations using ThorVG's runtime capabilities
- **Multi-layer Composition:** Advanced animation layering through ThorVG's compositing features
- **Performance Analytics:** Real-time monitoring of ThorVG rendering performance
- **Cross-Platform Deployment:** Extend ThorVG integration to mobile and desktop clients

This ADR establishes the foundation for sophisticated visual representation in Timestrike using ThorVG's proven vector graphics engine, maintaining real-time performance requirements while benefiting from our development partnership.
