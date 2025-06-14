# ADR-027: Web Interface Implementation

## Status
Accepted

## Context
The final temporal planner demonstration requires a modern, professional interface that showcases 3D visualization capabilities while supporting real-time updates and user interaction.

## Decision
Phoenix LiveView web interface with Three.js 3D visualization replaces CLI for the final implementation (phx.server is standard).

## Rationale
- **Professional Presentation**: 3D web interface provides superior demonstration value over terminal CLI
- **Standard Deployment**: `mix phx.server` and navigate to `/timestrike` for instant demo
- **Streaming Compatibility**: 3D web interface inherently more streaming-friendly than CLI
- **Future Integration**: Three.js knowledge and coordinate system transfers directly to Godot

## Implementation Benefits
### Technology Advantages
- **Familiar Stack**: Builds on existing Phoenix LiveView expertise in the project
- **Superior Visualization**: Three.js 3D graphics vastly superior to ASCII terminal display
- **Easy Sharing**: Web URL easier to share than terminal application
- **GPU Acceleration**: Hardware-accelerated rendering for smooth 60+ FPS performance

### Demonstration Advantages
- **Professional Appearance**: 3D web interface looks more polished for demonstrations
- **Immersive Experience**: 3D tactical maps with camera controls and lighting effects
- **Real-time Updates**: WebSocket connections provide smoother real-time feedback than terminal
- **Touch/Mobile Ready**: Web interface works on tablets and phones for broader accessibility

### Development Advantages
- **Standard Phoenix Patterns**: Follow existing AriaEngine web interface conventions
- **Future Extensibility**: 3D platform supports advanced features like procedural terrain and particle effects
- **Resolution 19 Compliance**: Native 3D coordinate system fully supports Godot conventions

## Technical Implementation
### Phoenix LiveView Integration
- **Real-time Communication**: WebSocket connections for immediate state updates
- **Event Handling**: User clicks and hotkeys send messages to LiveView process
- **State Synchronization**: Game state changes pushed to browser in real-time

### Three.js 3D Scene
- **3D Coordinate Native Support**: Direct mapping of `{x, y, z}` coordinates to `THREE.Vector3`
- **Camera Controls**: Orbital controls for tactical viewing angles
- **Lighting Effects**: Directional lighting with shadows for depth perception
- **Agent Rendering**: 3D capsule geometries with team color materials

### URL Structure
```
http://localhost:4000/timestrike
```

## Implementation Requirements
### Frontend Components
- **Three.js Library**: ~600KB compressed, loaded from CDN
- **TWEEN.js**: Animation library for smooth movement
- **OrbitControls**: Camera control library
- **Basic Geometries**: Capsules for agents, planes for terrain

### Phoenix Integration
```elixir
# LiveView real-time updates
def handle_info({:agent_moved, agent_id, position}, socket) do
  {:noreply, push_event(socket, "agent_moved", %{
    agent_id: agent_id,
    position: position,
    duration: 1.5
  })}
end
```

```javascript
// Three.js update handling
window.addEventListener("phx:agent_moved", (event) => {
  const {agent_id, position, duration} = event.detail;
  animateAgentMovement(agent_id, position, duration);
});
```

## Risk Mitigation
- **Fallback Option**: Can revert to SVG if Three.js proves too complex
- **Progressive Enhancement**: Start with basic 3D, add features incrementally
- **Performance Monitoring**: Frame rate tracking to ensure smooth operation
- **Mobile Compatibility**: WebGL detection with fallback for unsupported devices

## Consequences
### Positive
- Professional 3D visualization for superior demonstrations
- Standard web deployment model familiar to developers
- GPU-accelerated performance for smooth real-time updates
- Future-proof foundation for advanced 3D features
- Streaming-optimized visual presentation

### Negative
- Increased complexity over simple CLI interface
- WebGL compatibility requirements for client devices
- Higher bandwidth usage for real-time 3D updates
- Additional frontend development time and expertise required
- Dependency on browser performance for smooth operation

## Related Decisions
- Supersedes earlier CLI interface decisions
- Implements ADR-008 (Web Interface Implementation Details)
- Links to ADR-028 (Three.js 3D Visualization Architecture)
- Supports ADR-018 (MVP Definition) with professional presentation
- Enables ADR-014 (Twitch Streaming Optimization) with 3D visual appeal
