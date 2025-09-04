// Aria IK Solver - Three.js Frontend Application

class AriaIKSolver {
    constructor() {
        this.scene = null;
        this.camera = null;
        this.renderer = null;
        this.vrm = null;
        this.channel = null;
        this.selectedBone = null;
        this.targetSphere = null;
        this.boneFilters = new Map(); // For 1 euro filter smoothing
        this.raycaster = new THREE.Raycaster();
        this.mouse = new THREE.Vector2();

        this.init();
        this.setupWebSocket();
        this.setupEventListeners();
        this.animate();
    }

    init() {
        // Scene setup
        this.scene = new THREE.Scene();
        this.scene.background = new THREE.Color(0x1a1a1a);

        // Camera setup
        this.camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 1000);
        this.camera.position.set(0, 1.6, 3);

        // Renderer setup
        this.renderer = new THREE.WebGLRenderer({ antialias: true });
        this.renderer.setSize(window.innerWidth, window.innerHeight);
        this.renderer.setPixelRatio(window.devicePixelRatio);
        this.renderer.shadowMap.enabled = true;
        this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;

        const container = document.getElementById('scene');
        container.appendChild(this.renderer.domElement);

        // Lighting
        const ambientLight = new THREE.AmbientLight(0x404040, 0.6);
        this.scene.add(ambientLight);

        const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
        directionalLight.position.set(5, 5, 5);
        directionalLight.castShadow = true;
        this.scene.add(directionalLight);

        // Ground plane
        const planeGeometry = new THREE.PlaneGeometry(10, 10);
        const planeMaterial = new THREE.MeshLambertMaterial({ color: 0x333333 });
        const plane = new THREE.Mesh(planeGeometry, planeMaterial);
        plane.rotation.x = -Math.PI / 2;
        plane.receiveShadow = true;
        this.scene.add(plane);

        // Target sphere (invisible initially)
        const sphereGeometry = new THREE.SphereGeometry(0.05, 16, 16);
        const sphereMaterial = new THREE.MeshBasicMaterial({ color: 0xff0000, transparent: true, opacity: 0.7 });
        this.targetSphere = new THREE.Mesh(sphereGeometry, sphereMaterial);
        this.targetSphere.visible = false;
        this.scene.add(this.targetSphere);

        // Grid helper
        const gridHelper = new THREE.GridHelper(10, 10, 0x444444, 0x222222);
        this.scene.add(gridHelper);

        this.updateStatus('Scene initialized - ready for VRM loading');
    }

    setupWebSocket() {
        const socket = new Phoenix.Socket("/socket");
        socket.connect();

        this.channel = socket.channel("ik:lobby", {});
        this.channel.join()
            .receive("ok", resp => {
                console.log("Joined IK channel successfully", resp);
                this.updateStatus('Connected to IK solver backend', 'success');
            })
            .receive("error", resp => {
                console.log("Unable to join IK channel", resp);
                this.updateStatus('Failed to connect to backend', 'error');
            });

        // Listen for pose updates
        this.channel.on("new_pose", payload => {
            this.applyPoseUpdate(payload.joints);
        });
    }

    setupEventListeners() {
        // Window resize
        window.addEventListener('resize', () => {
            this.camera.aspect = window.innerWidth / window.innerHeight;
            this.camera.updateProjectionMatrix();
            this.renderer.setSize(window.innerWidth, window.innerHeight);
        });

        // Mouse events for bone selection
        this.renderer.domElement.addEventListener('mousedown', (event) => {
            this.onMouseDown(event);
        });

        // Drag and drop for VRM files
        const dropZone = document.getElementById('drop-zone');
        const container = document.getElementById('container');

        // Show drop zone when dragging files over
        ['dragenter', 'dragover'].forEach(eventName => {
            container.addEventListener(eventName, (e) => {
                e.preventDefault();
                dropZone.style.display = 'block';
                dropZone.classList.add('dragover');
            });
        });

        ['dragleave', 'drop'].forEach(eventName => {
            container.addEventListener(eventName, (e) => {
                e.preventDefault();
                dropZone.classList.remove('dragover');
            });
        });

        // Hide drop zone when not dragging
        container.addEventListener('dragleave', (e) => {
            if (!container.contains(e.relatedTarget)) {
                dropZone.style.display = 'none';
            }
        });

        // Handle file drop
        container.addEventListener('drop', (e) => {
            e.preventDefault();
            dropZone.style.display = 'none';

            const files = e.dataTransfer.files;
            if (files.length > 0) {
                this.loadVRMFile(files[0]);
            }
        });

        // UI controls
        document.getElementById('update-target').addEventListener('click', () => {
            this.sendIKTarget();
        });

        document.getElementById('bone-select').addEventListener('change', (e) => {
            this.selectedBone = e.target.value;
            this.updateTargetSphere();
        });

        // Target position inputs
        ['target-x', 'target-y', 'target-z'].forEach(id => {
            document.getElementById(id).addEventListener('input', () => {
                this.updateTargetSphere();
            });
        });
    }

    async loadVRMFile(file) {
        if (!file.name.toLowerCase().endsWith('.vrm')) {
            this.updateStatus('Please select a .vrm file', 'error');
            return;
        }

        this.updateStatus('Loading VRM file...', 'info');

        try {
            const arrayBuffer = await file.arrayBuffer();
            const vrm = await THREE.VRMLoader.loadAsync(arrayBuffer);

            // Remove existing VRM if present
            if (this.vrm) {
                this.scene.remove(this.vrm.scene);
            }

            this.vrm = vrm;
            this.scene.add(vrm.scene);

            // Position the model
            vrm.scene.position.set(0, 0, 0);
            vrm.scene.rotation.set(0, 0, 0);

            // Setup bone filters for smoothing
            this.setupBoneFilters();

            // Notify backend about model loading
            this.channel.push("load_model", { model_path: file.name });

            this.updateStatus(`VRM loaded: ${file.name}`, 'success');

            // Hide drop zone and show UI
            document.getElementById('drop-zone').style.display = 'none';
            document.getElementById('ui').style.display = 'block';

        } catch (error) {
            console.error('Error loading VRM:', error);
            this.updateStatus('Failed to load VRM file', 'error');
        }
    }

    setupBoneFilters() {
        if (!this.vrm) return;

        // Initialize 1 euro filters for each bone
        this.vrm.humanoid.humanBones.forEach((bone, name) => {
            if (bone) {
                this.boneFilters.set(name, new OneEuroFilter(0.001, 0.007, 0.1));
            }
        });
    }

    onMouseDown(event) {
        // Convert mouse position to normalized device coordinates
        this.mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
        this.mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;

        // Update the raycaster
        this.raycaster.setFromCamera(this.mouse, this.camera);

        // Check for intersections with VRM bones
        if (this.vrm) {
            const intersects = this.raycaster.intersectObjects(this.vrm.scene.children, true);

            if (intersects.length > 0) {
                // Find the bone that was clicked
                const clickedBone = this.findBoneFromIntersection(intersects[0]);
                if (clickedBone) {
                    this.selectBone(clickedBone);
                }
            }
        }
    }

    findBoneFromIntersection(intersection) {
        // Walk up the hierarchy to find a bone
        let object = intersection.object;
        while (object) {
            if (object.userData && object.userData.boneName) {
                return object.userData.boneName;
            }
            object = object.parent;
        }
        return null;
    }

    selectBone(boneName) {
        this.selectedBone = boneName;
        document.getElementById('bone-select').value = boneName;
        this.updateTargetSphere();

        this.updateStatus(`Selected bone: ${boneName}`, 'info');
    }

    updateTargetSphere() {
        if (!this.selectedBone || !this.vrm) {
            this.targetSphere.visible = false;
            return;
        }

        const bone = this.vrm.humanoid.getBoneNode(this.selectedBone);
        if (bone) {
            // Position target sphere at current bone position
            bone.getWorldPosition(this.targetSphere.position);
            this.targetSphere.visible = true;
        }
    }

    sendIKTarget() {
        if (!this.selectedBone || !this.channel) return;

        const x = parseFloat(document.getElementById('target-x').value) || 0;
        const y = parseFloat(document.getElementById('target-y').value) || 0;
        const z = parseFloat(document.getElementById('target-z').value) || 0;

        const message = {
            endEffector: this.selectedBone,
            position: { x, y, z }
        };

        this.channel.push("update_target", message);
        this.updateStatus(`Sent IK target for ${this.selectedBone}`, 'info');

        // Update target sphere position
        this.targetSphere.position.set(x, y, z);
        this.targetSphere.visible = true;
    }

    applyPoseUpdate(joints) {
        if (!this.vrm) return;

        joints.forEach(joint => {
            const bone = this.vrm.humanoid.getBoneNode(joint.bone);
            if (bone) {
                // Apply 1 euro filter for smooth interpolation
                const smoothedRotation = this.smoothBoneRotation(joint.bone, joint.rotation);

                // Apply the smoothed rotation
                bone.quaternion.set(...smoothedRotation);
            }
        });

        this.updateStatus(`Applied pose update for ${joints.length} joints`, 'success');
    }

    smoothBoneRotation(boneName, newRotation) {
        const filter = this.boneFilters.get(boneName);
        if (!filter) return newRotation;

        const timestamp = performance.now();
        const smoothed = [];

        // Apply filter to each quaternion component
        for (let i = 0; i < 4; i++) {
            smoothed[i] = filter.filter(newRotation[i], timestamp);
        }

        return smoothed;
    }

    updateStatus(message, type = 'info') {
        const statusEl = document.getElementById('status');
        statusEl.textContent = message;
        statusEl.className = type;
    }

    animate() {
        requestAnimationFrame(() => this.animate());

        // Update any animations or interactions here
        if (this.vrm) {
            // Update VRM
            this.vrm.update();
        }

        this.renderer.render(this.scene, this.camera);
    }
}

// 1 Euro Filter implementation for smooth pose interpolation
class OneEuroFilter {
    constructor(alpha, minCutoff, beta) {
        this.alpha = alpha;
        this.minCutoff = minCutoff;
        this.beta = beta;
        this.prevValue = null;
        this.prevDeriv = 0;
        this.prevTimestamp = 0;
    }

    filter(value, timestamp) {
        if (this.prevValue === null) {
            this.prevValue = value;
            this.prevTimestamp = timestamp;
            return value;
        }

        const dt = timestamp - this.prevTimestamp;
        if (dt <= 0) return this.prevValue;

        const deriv = (value - this.prevValue) / dt;
        const cutoff = this.minCutoff + this.beta * Math.abs(deriv);
        const alpha = this.alpha / (this.alpha + dt * cutoff);

        const filteredValue = alpha * value + (1 - alpha) * this.prevValue;

        this.prevValue = filteredValue;
        this.prevDeriv = deriv;
        this.prevTimestamp = timestamp;

        return filteredValue;
    }
}

// Initialize the application when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new AriaIKSolver();
});
