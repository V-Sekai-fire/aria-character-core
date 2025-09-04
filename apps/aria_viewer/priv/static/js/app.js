// Aria Real-Time IK Solver Frontend
class AriaIKSolver {
    constructor() {
        this.scene = null;
        this.camera = null;
        this.renderer = null;
        this.vrm = null;
        this.channel = null;
        this.currentModel = null;
        this.targetHelper = null;

        this.init();
        this.setupWebSocket();
        this.setupEventListeners();
    }

    init() {
        // Initialize Three.js scene
        this.scene = new THREE.Scene();
        this.camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
        this.renderer = new THREE.WebGLRenderer({ antialias: true });
        this.renderer.setSize(window.innerWidth, window.innerHeight);
        this.renderer.setClearColor(0x1a1a1a);

        const container = document.getElementById('container');
        container.appendChild(this.renderer.domElement);

        // Setup camera
        this.camera.position.set(0, 1.5, 3);
        this.camera.lookAt(0, 1, 0);

        // Add lighting
        const ambientLight = new THREE.AmbientLight(0x404040, 0.6);
        this.scene.add(ambientLight);

        const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
        directionalLight.position.set(1, 1, 1);
        this.scene.add(directionalLight);

        // Add grid helper
        const gridHelper = new THREE.GridHelper(10, 10);
        this.scene.add(gridHelper);

        // Create target position helper
        this.createTargetHelper();

        this.animate();
        this.updateStatus('Three.js initialized');
    }

    createTargetHelper() {
        // Create a sphere to show target position
        const geometry = new THREE.SphereGeometry(0.05, 16, 16);
        const material = new THREE.MeshBasicMaterial({ color: 0xff0000 });
        this.targetHelper = new THREE.Mesh(geometry, material);
        this.targetHelper.position.set(0.5, 1.2, 0.3);
        this.scene.add(this.targetHelper);
    }

    setupWebSocket() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
        const wsUrl = `${protocol}//${window.location.host}/socket`;

        this.socket = new Phoenix.Socket(wsUrl);
        this.socket.connect();

        this.channel = this.socket.channel("ik:lobby", {});
        this.channel.join()
            .receive("ok", resp => {
                console.log("Joined IK channel successfully", resp);
                this.updateWebSocketStatus('Connected');
            })
            .receive("error", resp => {
                console.log("Unable to join IK channel", resp);
                this.updateWebSocketStatus('Connection Failed');
            });

        // Listen for pose updates
        this.channel.on("new_pose", payload => {
            console.log("Received new pose:", payload);
            this.applyPoseUpdate(payload.joints);
        });
    }

    setupEventListeners() {
        // Update target button
        document.getElementById('update-target').addEventListener('click', () => {
            this.updateTarget();
        });

        // Load VRMA button
        document.getElementById('load-vrma').addEventListener('click', () => {
            this.showDropZone();
        });

        // File input
        document.getElementById('file-input').addEventListener('change', (event) => {
            const file = event.target.files[0];
            if (file) {
                this.loadVRMFile(file);
            }
        });

        // Drag and drop
        const dropZone = document.getElementById('drop-zone');
        dropZone.addEventListener('click', () => {
            document.getElementById('file-input').click();
        });

        ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
            dropZone.addEventListener(eventName, this.preventDefaults, false);
        });

        ['dragenter', 'dragover'].forEach(eventName => {
            dropZone.addEventListener(eventName, () => {
                dropZone.classList.add('dragover');
            });
        });

        ['dragleave', 'drop'].forEach(eventName => {
            dropZone.addEventListener(eventName, () => {
                dropZone.classList.remove('dragover');
            });
        });

        dropZone.addEventListener('drop', (e) => {
            const file = e.dataTransfer.files[0];
            if (file) {
                this.loadVRMFile(file);
            }
        });

        // Window resize
        window.addEventListener('resize', () => {
            this.camera.aspect = window.innerWidth / window.innerHeight;
            this.camera.updateProjectionMatrix();
            this.renderer.setSize(window.innerWidth, window.innerHeight);
        });
    }

    preventDefaults(e) {
        e.preventDefault();
        e.stopPropagation();
    }

    updateTarget() {
        const boneSelect = document.getElementById('bone-select');
        const x = parseFloat(document.getElementById('target-x').value);
        const y = parseFloat(document.getElementById('target-y').value);
        const z = parseFloat(document.getElementById('target-z').value);

        const endEffector = boneSelect.value;
        const position = { x, y, z };

        // Update target helper position
        this.targetHelper.position.set(x, y, z);

        // Send to backend
        this.channel.push("update_target", {
            endEffector: endEffector,
            position: position
        });

        this.updateStatus(`Updated target for ${endEffector}`);
    }

    showDropZone() {
        const dropZone = document.getElementById('drop-zone');
        dropZone.classList.add('visible');
    }

    hideDropZone() {
        const dropZone = document.getElementById('drop-zone');
        dropZone.classList.remove('visible');
    }

    async loadVRMFile(file) {
        this.updateStatus(`Loading VRM file: ${file.name}`);
        this.hideDropZone();

        try {
            const arrayBuffer = await file.arrayBuffer();
            const vrm = await THREE.VRMLoader.loadAsync(arrayBuffer);

            // Remove existing model
            if (this.currentModel) {
                this.scene.remove(this.currentModel);
            }

            // Add new model
            this.currentModel = vrm.scene;
            this.scene.add(this.currentModel);

            // Store VRM instance for bone manipulation
            this.vrm = vrm;

            this.updateModelStatus(`${file.name} loaded`);
            this.updateStatus('VRM model loaded successfully');

            // Load model on backend
            this.channel.push("load_model", {
                model_path: `/static/${file.name}`
            });

        } catch (error) {
            console.error('Error loading VRM:', error);
            this.updateStatus(`Error loading VRM: ${error.message}`);
        }
    }

    applyPoseUpdate(joints) {
        if (!this.vrm) {
            console.warn('No VRM model loaded');
            return;
        }

        joints.forEach(joint => {
            try {
                const bone = this.vrm.humanoid.getBoneNode(joint.bone);
                if (bone && joint.rotation && joint.rotation.length === 4) {
                    const [x, y, z, w] = joint.rotation;
                    bone.quaternion.set(x, y, z, w);
                }
            } catch (error) {
                console.warn(`Could not apply rotation to bone ${joint.bone}:`, error);
            }
        });

        this.updateStatus(`Applied pose update with ${joints.length} joint rotations`);
    }

    animate() {
        requestAnimationFrame(() => this.animate());

        // Add subtle rotation to target helper
        if (this.targetHelper) {
            this.targetHelper.rotation.y += 0.01;
        }

        this.renderer.render(this.scene, this.camera);
    }

    updateStatus(message) {
        const statusDiv = document.getElementById('status');
        const timestamp = new Date().toLocaleTimeString();
        statusDiv.innerHTML = `
            Status: ${message}<br>
            WebSocket: <span id="ws-status">${document.getElementById('ws-status').textContent}</span><br>
            Model: <span id="model-status">${document.getElementById('model-status').textContent}</span><br>
            Time: ${timestamp}
        `;
    }

    updateWebSocketStatus(status) {
        document.getElementById('ws-status').textContent = status;
    }

    updateModelStatus(status) {
        document.getElementById('model-status').textContent = status;
    }
}

// Initialize when page loads
document.addEventListener('DOMContentLoaded', () => {
    new AriaIKSolver();
});
