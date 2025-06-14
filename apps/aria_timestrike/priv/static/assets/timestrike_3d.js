// TimeStrike Three.js 3D Scene Manager with Godot Coordinate System
// Godot Conventions: +X = right, +Y = up, +Z = forward (toward camera)
class TimeStrike3D {
  constructor(containerId) {
    this.container = document.getElementById(containerId);
    this.scene = null;
    this.camera = null;
    this.renderer = null;
    this.agents = {};
    this.animationId = null;
    
    this.init();
    this.setupEventListeners();
  }

  init() {
    // Create scene
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x0a0a0a);

    // Create camera using Godot conventions
    // In Godot: +X = right, +Y = up, +Z = forward (toward camera)
    // Camera positioned to look down at the tactical map
    const aspect = this.container.clientWidth / this.container.clientHeight;
    const frustumSize = 15;
    this.camera = new THREE.OrthographicCamera(
      -frustumSize * aspect / 2, frustumSize * aspect / 2,
      frustumSize / 2, -frustumSize / 2,
      0.1, 1000
    );
    
    // Position camera above and slightly forward of the battlefield
    // Looking down at the Y=0 plane (ground level)
    this.camera.position.set(12.5, 15, 8);  // X=center, Y=high, Z=forward
    this.camera.lookAt(12.5, 0, 5);         // Look at center of battlefield
    
    // Create renderer
    this.renderer = new THREE.WebGLRenderer({ antialias: true });
    this.renderer.setSize(this.container.clientWidth, this.container.clientHeight);
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.container.appendChild(this.renderer.domElement);

    // Add lights
    const ambientLight = new THREE.AmbientLight(0x404040, 0.3);
    this.scene.add(ambientLight);

    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.7);
    directionalLight.position.set(15, 20, 10);  // Godot-style lighting position
    directionalLight.castShadow = true;
    this.scene.add(directionalLight);

    // Create battlefield grid and terrain
    this.createBattlefield();
    
    // Create initial agents using Godot coordinates
    this.createAgent('Alex', { x: 2, y: 0, z: 3 }, 0x4CAF50);    // Y=0 ground level
    this.createAgent('Maya', { x: 3, y: 0, z: 5 }, 0xFF9800);    // Y=0 ground level  
    this.createAgent('Jordan', { x: 4, y: 0, z: 6 }, 0x2196F3);  // Y=0 ground level

    // Start render loop
    this.animate();
  }

  createBattlefield() {
    // Create tactical grid on the Y=0 plane (Godot ground level)
    // Grid extends from X=0 to X=25, Z=0 to Z=10
    const gridHelper = new THREE.GridHelper(25, 25, 0x00ff00, 0x004400);
    gridHelper.position.set(12.5, 0, 5);  // Center the grid
    this.scene.add(gridHelper);

    // Create ground plane at Y=0 (Godot ground level)
    const groundGeometry = new THREE.PlaneGeometry(25, 10);
    const groundMaterial = new THREE.MeshLambertMaterial({ 
      color: 0x001100, 
      transparent: true, 
      opacity: 0.8 
    });
    const ground = new THREE.Mesh(groundGeometry, groundMaterial);
    ground.rotation.x = -Math.PI / 2;  // Rotate to lie flat on XZ plane
    ground.position.set(12.5, -0.01, 5);  // Slightly below Y=0 to avoid z-fighting
    ground.receiveShadow = true;
    this.scene.add(ground);

    // Add coordinate system visualizer for debugging
    this.createCoordinateSystem();
  }

  createCoordinateSystem() {
    // Create axis helpers to visualize Godot coordinate system
    const axesHelper = new THREE.AxesHelper(5);
    axesHelper.position.set(0, 0, 0);
    this.scene.add(axesHelper);
    
    // Add coordinate labels (simple boxes for MVP)
    // Red = +X (right), Green = +Y (up), Blue = +Z (forward)
    const labelGeometry = new THREE.BoxGeometry(0.5, 0.5, 0.5);
    
    // X-axis label (red)
    const xLabel = new THREE.Mesh(labelGeometry, new THREE.MeshBasicMaterial({ color: 0xff0000 }));
    xLabel.position.set(3, 0.5, 0);
    this.scene.add(xLabel);
    
    // Y-axis label (green) 
    const yLabel = new THREE.Mesh(labelGeometry, new THREE.MeshBasicMaterial({ color: 0x00ff00 }));
    yLabel.position.set(0, 3, 0);
    this.scene.add(yLabel);
    
    // Z-axis label (blue)
    const zLabel = new THREE.Mesh(labelGeometry, new THREE.MeshBasicMaterial({ color: 0x0000ff }));
    zLabel.position.set(0, 0.5, 3);
    this.scene.add(zLabel);
  }

  createAgent(name, position, color) {
    // Create agent geometry - simple capsule standing upright
    const geometry = new THREE.CapsuleGeometry(0.2, 0.6, 4, 8);
    const material = new THREE.MeshLambertMaterial({ color: color });
    const agent = new THREE.Mesh(geometry, material);
    
    // Position agent using Godot coordinates directly
    // Agent capsule is 0.6 tall, so position at Y=0.3 to stand on ground
    agent.position.set(position.x, position.y + 0.3, position.z);
    agent.castShadow = true;
    agent.name = name;
    
    // Add simple label above agent
    const labelGeometry = new THREE.BoxGeometry(0.15, 0.15, 0.15);
    const labelMaterial = new THREE.MeshBasicMaterial({ color: color });
    const label = new THREE.Mesh(labelGeometry, labelMaterial);
    label.position.set(0, 0.5, 0);  // Above agent
    agent.add(label);
    
    this.scene.add(agent);
    this.agents[name] = agent;
  }

  // Update agent position using Godot coordinates
  updateAgentPosition(agentName, position, duration = 1000) {
    const agent = this.agents[agentName];
    if (!agent) {
      console.warn(`Agent ${agentName} not found`);
      return;
    }

    // Convert Godot position to Three.js position
    const startPos = agent.position.clone();
    const endPos = new THREE.Vector3(
      position.x,           // X coordinate (right)
      position.y + 0.3,     // Y coordinate (up) + agent height offset
      position.z            // Z coordinate (forward)
    );
    
    console.log(`Moving ${agentName} from ${startPos.x},${startPos.y},${startPos.z} to ${endPos.x},${endPos.y},${endPos.z}`);
    
    const startTime = Date.now();
    
    const animate = () => {
      const elapsed = Date.now() - startTime;
      const progress = Math.min(elapsed / duration, 1);
      
      // Smooth linear interpolation
      agent.position.lerpVectors(startPos, endPos, progress);
      
      if (progress < 1) {
        requestAnimationFrame(animate);
      } else {
        console.log(`${agentName} reached position ${endPos.x},${endPos.y},${endPos.z}`);
      }
    };
    
    animate();
  }

  setupEventListeners() {
    // Handle window resize
    window.addEventListener('resize', () => {
      const aspect = this.container.clientWidth / this.container.clientHeight;
      const frustumSize = 15;
      
      this.camera.left = -frustumSize * aspect / 2;
      this.camera.right = frustumSize * aspect / 2;
      this.camera.top = frustumSize / 2;
      this.camera.bottom = -frustumSize / 2;
      this.camera.updateProjectionMatrix();
      
      this.renderer.setSize(this.container.clientWidth, this.container.clientHeight);
    });

    // Handle Phoenix LiveView events with Godot coordinates
    window.addEventListener('phx:agent_moved', (event) => {
      const { agent_id, position, duration } = event.detail;
      console.log(`Received agent_moved event: ${agent_id} to ${position.x},${position.y},${position.z}`);
      this.updateAgentPosition(agent_id, position, duration * 1000);
    });

    // Handle mouse controls for camera orbit around battlefield center
    let mouseDown = false;
    let mouseX = 0;
    let mouseY = 0;

    this.renderer.domElement.addEventListener('mousedown', (event) => {
      mouseDown = true;
      mouseX = event.clientX;
      mouseY = event.clientY;
    });

    this.renderer.domElement.addEventListener('mouseup', () => {
      mouseDown = false;
    });

    this.renderer.domElement.addEventListener('mousemove', (event) => {
      if (!mouseDown) return;

      const deltaX = event.clientX - mouseX;
      const deltaY = event.clientY - mouseY;

      // Orbit camera around battlefield center using Godot coordinates
      const centerX = 12.5;  // Center of battlefield
      const centerY = 0;     // Ground level
      const centerZ = 5;     // Center of battlefield
      
      const radius = 20;
      
      // Horizontal rotation (around Y axis)
      const horizontalAngle = deltaX * 0.01;
      const currentAngle = Math.atan2(this.camera.position.z - centerZ, this.camera.position.x - centerX);
      const newAngle = currentAngle + horizontalAngle;
      
      // Vertical adjustment
      const verticalChange = deltaY * 0.1;
      const newY = Math.max(5, Math.min(25, this.camera.position.y - verticalChange));
      
      this.camera.position.x = centerX + Math.cos(newAngle) * radius;
      this.camera.position.y = newY;
      this.camera.position.z = centerZ + Math.sin(newAngle) * radius;
      this.camera.lookAt(centerX, centerY, centerZ);

      mouseX = event.clientX;
      mouseY = event.clientY;
    });
  }

  animate() {
    this.animationId = requestAnimationFrame(() => this.animate());
    this.renderer.render(this.scene, this.camera);
  }

  dispose() {
    if (this.animationId) {
      cancelAnimationFrame(this.animationId);
    }
    if (this.renderer) {
      this.renderer.dispose();
    }
  }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  // Wait for Three.js to load
  if (typeof THREE !== 'undefined') {
    window.timeStrike3D = new TimeStrike3D('timestrike-3d-container');
  } else {
    console.error('Three.js not loaded');
  }
});

// Export for module systems
if (typeof module !== 'undefined' && module.exports) {
  module.exports = TimeStrike3D;
}
