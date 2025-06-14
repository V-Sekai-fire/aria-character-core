# ADR-030: Console TUI Implementation

## Status

Accepted

**Date**: June 14, 2025
**Supersedes**: ADR-027 (Web Interface Implementation), ADR-028 (Three.js 3D Visualization Architecture)

## Context

During weekend implementation, Three.js 3D visualization and Phoenix LiveView web interface proved too complex for the available timeline. The temporal planner needs a working demonstration interface that can be implemented reliably within weekend constraints while still showcasing core temporal planning capabilities.

## Decision

Implement a console-based Terminal User Interface (TUI) for the temporal planner demonstration, abandoning the web interface approach.

## Rationale

- **Implementation Speed**: Console TUI can be implemented much faster than web interface
- **Weekend Viability**: Proven terminal interface patterns reduce implementation risk
- **Focus on Core**: Removes frontend complexity to focus on temporal planning logic
- **Demonstration Capability**: Terminal interface still provides clear visualization of temporal planning
- **Existing Expertise**: Project already has TUI experience from aria_tui application

## Implementation

### Console Interface Design

- **Real-time Display**: Terminal-based real-time updates showing agent positions and actions
- **ASCII Grid**: Simple ASCII representation of the battlefield grid
- **Status Information**: Current agent positions, action progress, and timing information
- **Input Handling**: Keyboard input for interruption and tactical commands

### Technical Stack

- **Elixir Console**: Native Elixir terminal I/O for cross-platform compatibility
- **ASCII Rendering**: Simple character-based grid display
- **Real-time Updates**: Terminal screen refresh for animation effects
- **Keyboard Input**: Asynchronous input handling for real-time interaction

### Display Format

```
TimeStrike - Temporal Planner Demo
================================

Battlefield (25x10):
. . . . . A . . . . . . . . . . . . . . . . . . G
. . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . .
...

Alex (A): Position {5,0} -> {24,0} | ETA: 4.2s | Progress: ████████░░ 80%
Maya (M): Position {3,2} -> {8,2}  | ETA: 1.8s | Progress: ██████░░░░ 60%

Actions:
- [12:34:15.432] Alex moving to position {24,0}
- [12:34:16.123] Maya moving to position {8,2}

Press SPACEBAR to interrupt Alex | Press Q to quit
```

### Weekend Implementation Scope

- **Basic Grid**: ASCII battlefield representation
- **Agent Movement**: Real-time position updates
- **Action Display**: Current actions and timing information
- **Interruption**: SPACEBAR interrupt functionality
- **Status Updates**: ETA and progress indicators

## Benefits Over Web Interface

- **Rapid Implementation**: No frontend JavaScript development required
- **Cross-Platform**: Works on any terminal without browser dependencies
- **Lower Complexity**: Fewer moving parts and integration points
- **Debugging Ease**: Direct terminal output easier to debug
- **Resource Efficiency**: No web server or browser overhead

## Limitations Accepted

- **Visual Appeal**: Less polished than 3D web interface
- **Streaming Quality**: Terminal interface less engaging for stream viewers
- **Mobile Access**: Not accessible on mobile devices
- **Future Expansion**: Limited scalability compared to web platform

## Implementation Plan

1. **Terminal Setup**: Basic terminal screen management and input handling
2. **Grid Display**: ASCII battlefield rendering with agent positions
3. **Real-time Updates**: Screen refresh system for movement animation
4. **Input Processing**: Asynchronous keyboard input for interruptions
5. **Status Display**: Action progress and timing information

## Consequences

### Positive

- **Achievable Timeline**: Can be implemented within weekend constraints
- **Focus on Core Logic**: Removes frontend distractions from temporal planning
- **Reliable Demonstration**: Terminal interface has fewer failure modes
- **Development Speed**: Faster iteration cycle for temporal planner logic

### Negative

- **Reduced Visual Impact**: Less impressive than 3D web interface
- **Limited Streaming Appeal**: Terminal interface less engaging for viewers
- **Platform Limitations**: Terminal capabilities vary across systems
- **Future Migration Cost**: Eventually need to rebuild interface for production

## Related Decisions

- **Supersedes**: ADR-027 (Web Interface Implementation)
- **Supersedes**: ADR-028 (Three.js 3D Visualization Architecture)
- **Links to**: ADR-016 (Weekend Implementation Scope) - prioritizes achievable functionality
- **Links to**: ADR-024 (Absolute Minimum Success Criteria) - ensures working demonstration
- **Links to**: ADR-026 (Implementation Risk Mitigation) - reduces complexity risk
