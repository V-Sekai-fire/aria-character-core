# R25W005553D: Web Interface Implementation Details

<!-- @adr_serial R25W005553D -->

## Status

Accepted

## Context

The temporal planner needs a responsive web interface that can display real-time updates and support 3D visualization for enhanced tactical display and streaming appeal.

## Decision

Use Phoenix LiveView with WebSocket updates and Three.js 3D visualization for future-proof tactical display.

## Rationale

- **Real-time Communication**: Phoenix LiveView handles real-time WebSocket communication with minimal latency
- **3D Visualization**: Three.js 3D scene provides immersive tactical visualization with native 3D coordinate support
- **Synchronized Updates**: LiveView updates synchronized with game ticks, pushing 3D position updates to Three.js renderer
- **Precise Timing**: ETA calculations based on current time + remaining action duration with sub-millisecond precision
- **Responsive Input**: User input (clicks, hotkeys) sends messages to LiveView process with minimal latency
- **Streaming Optimization**: Real-time 3D updates provide responsive feedback for temporal planning visualization

## Implementation

- **Phoenix LiveView**: WebSocket-based real-time communication
- **Three.js Integration**: 3D scene rendering with GPU acceleration
- **Position Updates**: Real-time synchronization of agent positions
- **User Interaction**: Click and hotkey support for tactical commands
- **Camera Controls**: Dynamic viewing angles for enhanced streaming appeal
- **Future Compatibility**: Shared 3D coordinate system with Godot engine integration

## Technical Details

- **GPU Acceleration**: Hardware-accelerated rendering supports complex battlefields with 100+ agents
- **Dynamic Cameras**: Camera controls enable dynamic viewing angles for enhanced streaming appeal
- **Future Integration**: Compatible with Godot engine integration through shared 3D coordinate system

## Consequences

### Positive

- Professional 3D visualization for demonstrations
- Responsive real-time updates for tactical gameplay
- Streaming-friendly visual presentation
- Future-proof 3D coordinate support
- Standard web deployment model

### Negative

- Increased complexity over simple CLI interface
- WebGL compatibility requirements for clients
- Higher bandwidth usage for real-time updates
- Additional frontend development overhead

## Related Decisions

- Implements ADR-019 (3D Coordinates with Godot Conventions) for coordinate system
- Links to ADR-027 (Web Interface Implementation) → ADR-030 (Console TUI, superseded) → ADR-069 (Web Interface, current)
- Supports ADR-028 (Three.js 3D Visualization Architecture) for 3D rendering
- Enables ADR-014 (Twitch Streaming Optimization) with visual appeal
- Builds on ADR-006 (Game Engine Real-time Execution) for synchronized updates
- Enables ADR-014 (Twitch Streaming Optimization)
