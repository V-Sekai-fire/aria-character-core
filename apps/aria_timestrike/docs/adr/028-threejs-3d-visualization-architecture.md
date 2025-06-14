# ADR-028: Three.js 3D Visualization Architecture

## Status
Superseded by ADR-030 (Console TUI Implementation)

**Superseded Date**: June 14, 2025
**Reason**: Three.js 3D visualization complexity exceeded weekend timeline constraints. Console TUI provides more reliable path to working demonstration.

## Context
The temporal planner web interface requires sophisticated 3D visualization to showcase tactical gameplay and provide professional streaming appeal, replacing simpler SVG approaches.

## Decision
Implement Three.js 3D visualization as the primary tactical display system, replacing SVG for future-proof 3D coordinate support and enhanced streaming appeal.

## Rationale
- **Future-Proof Visualization**: Native 3D rendering prepares for eventual Godot integration
- **Professional Presentation**: GPU-accelerated 3D graphics create compelling demonstrations
- **Streaming Enhancement**: Dynamic camera angles and effects enhance viewer engagement
- **Coordinate System Alignment**: Direct Three.js integration with Godot coordinate conventions

## Technical Architecture
### Phoenix LiveView Integration
- **Real-time Communication**: Three.js scene receives position updates via WebSocket
- **Event Synchronization**: LiveView pushes agent positions, Three.js interpolates smooth movement
- **Bidirectional Control**: User interactions in 3D scene send commands back to LiveView

### 3D Coordinate Native Support
- **Direct Mapping**: `{x, y, z}` coordinates map directly to `THREE.Vector3`
- **No Transformation Layer**: Eliminates coordinate conversion overhead
- **Godot Compatibility**: Shared coordinate system enables seamless future integration

### Performance Optimization
- **GPU Acceleration**: Hardware-accelerated rendering for smooth 60+ FPS performance
- **Efficient Updates**: Only update changed objects, not entire scene
- **LOD Support**: Level-of-detail rendering for complex scenes with many agents

## Implementation Pattern
```javascript
// Phoenix LiveView → Three.js integration
window.addEventListener("phx:agent_moved", (event) => {
  const {agent_id, position, duration} = event.detail;
  animateAgentMovement(agent_id, position, duration);
});

// Smooth position interpolation
function animateAgentMovement(agentId, targetPos, duration) {
  const agent = scene.getObjectByName(agentId);
  new TWEEN.Tween(agent.position)
    .to(targetPos, duration * 1000)
    .easing(TWEEN.Easing.Linear.None)
    .start();
}

// Coordinate system alignment
function createAgent(id, position) {
  const geometry = new THREE.CapsuleGeometry(0.2, 1.0);
  const material = new THREE.MeshPhongMaterial({color: 0x00ff00});
  const agent = new THREE.Mesh(geometry, material);
  
  // Direct coordinate mapping (no transformation)
  agent.position.set(position.x, position.y, position.z);
  agent.name = id;
  
  scene.add(agent);
  return agent;
}
```

## Visual Features
### Agent Representation
- **3D Capsules**: Three.js capsule geometries for agent models
- **Team Colors**: Material colors distinguish team members and enemies
- **Height Positioning**: Agents positioned above ground plane for visibility

### Environment Rendering
- **Grid System**: Wireframe grid matching game coordinate system
- **Terrain Features**: Basic geometry for cover, obstacles, and terrain
- **Lighting System**: Directional lighting with shadows for depth perception

### Camera System
- **Orbital Controls**: Mouse-controlled camera positioning and rotation
- **Dynamic Focus**: Automatic camera focus on action sequences
- **Multiple Angles**: Switch between tactical overview and close-up action views

### UI Integration
- **HTML Overlays**: Game status and controls overlaid on 3D canvas
- **Context Menus**: Right-click interactions for tactical commands
- **HUD Elements**: Health bars, timers, and status indicators

## Streaming Enhancements
### Visual Appeal
- **Particle Effects**: Explosion effects for combat actions
- **Smooth Animations**: GPU-accelerated tweening for professional appearance
- **Cinematic Lighting**: Dynamic lighting effects for dramatic presentation

### Camera Work
- **Action Following**: Camera automatically tracks important events
- **Dramatic Angles**: Multiple viewpoints for enhanced visual storytelling
- **Zoom Controls**: Seamless zoom between tactical and detail views

## Weekend Implementation Scope
### Phase 1: Basic Scene
- **Scene Setup**: Basic Three.js scene with orthographic camera
- **Agent Rendering**: Simple capsule geometries for agents
- **Grid Display**: Wireframe grid for coordinate reference

### Phase 2: Movement Animation
- **Position Updates**: Real-time agent position synchronization
- **Smooth Interpolation**: TWEEN.js for smooth movement animation
- **LiveView Integration**: WebSocket event handling for state changes

### Phase 3: Camera Controls
- **Orbital Controls**: Mouse-controlled camera positioning
- **Basic Lighting**: Simple directional lighting for depth
- **Visual Polish**: Materials, colors, and basic effects

### Phase 4 (If Time Permits)
- **Enhanced Effects**: Particle systems and advanced lighting
- **Multiple Cameras**: Different viewing modes and angles
- **UI Polish**: Professional interface elements and controls

## Asset Requirements
- **Three.js Library**: ~600KB compressed, loaded from CDN
- **TWEEN.js**: Animation library for smooth movement (~20KB)
- **OrbitControls**: Camera control library (~15KB)
- **No 3D Models**: Use procedural geometries to avoid asset pipeline complexity

## Technical Benefits
- **ADR-019 Compliance**: Full 3D coordinate system support with Godot conventions
- **Future Godot Integration**: Shared coordinate conventions and 3D knowledge transfer
- **Scalable Performance**: GPU acceleration handles 100+ agents efficiently
- **Professional Presentation**: Dramatic improvement over SVG for demonstrations

## Consequences
### Positive
- Professional 3D visualization creates compelling demonstrations
- GPU-accelerated performance supports complex tactical scenarios
- Future-proof architecture for advanced 3D features
- Enhanced streaming appeal with cinematic presentation
- Direct Godot coordinate compatibility

### Negative
- Increased complexity over simple 2D approaches
- WebGL requirement limits compatibility with older devices
- Additional JavaScript expertise required for 3D development
- Higher bandwidth requirements for real-time 3D updates
- Potential performance issues on lower-end hardware

## Related Decisions
- Implements ADR-027 (Web Interface Implementation) with 3D visualization
- Links to ADR-019 (3D Coordinates with Godot Conventions) for coordinate alignment
- Supports ADR-014 (Twitch Streaming Optimization) with enhanced visual appeal
- Enables ADR-029 (Godot Coordinate Convention) through native 3D support
