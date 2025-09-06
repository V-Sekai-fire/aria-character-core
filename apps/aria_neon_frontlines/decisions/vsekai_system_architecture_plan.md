## Announcing: "Project Metropolis" - The Genesis Block Sprint

This is a focused technical sprint with a clear objective: to build a live, persistent city block that proves our core technology can create a resilient system of multiple AI agents working together to complete complex missions. We are treating this as a simulation stress test, prioritizing deep, data-driven functionality over visual polish.

### The Mission

In this sprint, we will build a live, single-instance environment to prove our core architecture is ready. By the end, we'll have a running server that validates our AI Planning Engine can manage a diverse team of specialized agents and that our Erlang backend can handle the massive concurrency this model requires.

### The Playground (Our "Genesis Block")

We're building a minimalist "city" to act as a testbed for a hybrid "Mothership-Scout" architecture. This concept blends the robustness of a primary controlling asset (the "Mothership") with the resilience of a disposable, multi-agent team (the "Scouts").

- **The World:** One greybox city block, running as a single, persistent server process. It will include areas with simulated communication "dead zones."
- **The "Inhabitants":** A diverse team of AI agents operating under a "Mothership" controller, alongside a handful of human observers. The team will consist of specialized "Scout" units, such as fast recon drones and rugged ground vehicles.
- **The "Gameplay":** Human observers will act as a single supervisor for the entire operation. They will issue high-level strategic commands to the Mothership AI, testing its ability to autonomously task its scout team and adapt to changing conditions.

### Sprint Goal #1: The Resilient Swarm

This is the main event. We need to build a functional AI-driven ecosystem that can achieve its objectives even when individual units fail, demonstrating resilience through redundancy.

- **The Challenge:** The AI's central planner must coordinate a diverse team of specialized scout agents deployed from the "Mothership." The system must demonstrate dynamic re-tasking, manage shared resources, and ensure the mission continues even when agents are lost.
- **Definition of Done:** We can demo an AI-run mission operating for 24 hours straight that successfully demonstrates the following capabilities:

  - **Heterogeneous Teaming:** A "Mothership" AI successfully deploys and coordinates at least two different types of "Scout" agents (e.g., a fast aerial drone for recon and a rugged ground vehicle for transport) to complete a multi-step objective.
  - **Tactical Comms Extension:** One scout agent successfully deploys a "comm relay" module, enabling a second scout to operate in and return data from a simulated communication dead zone.
  - **Resilience to Attrition:** During the test, we will manually disable a scout agent mid-task. The Mothership AI must detect the loss, re-task a remaining asset (or deploy a new one), and complete the original objective, proving the system can tolerate agent failure.

### Sprint Goal #2: The Concurrent Hive

This tests if our server architecture is solid enough to support this advanced multi-agent model. We'll implement the Genesis Block and flood it with actors.

- **The Challenge:** The Erlang backend must handle thousands of lightweight processes—one for every Mothership, Scout, and human supervisor—on a single server instance. The in-memory state must sync flawlessly and instantly across this massive, diverse population of agents.
- **Definition of Done:** The Genesis Block can sustain **5,000 concurrent AI and human-observer processes** while maintaining a stable server tick rate. The system must pass a "Chaos Test," where an automated script bombards the server with thousands of planning requests, state changes, and simulated scout failures to try and crash the system.

### The "Sim" Rules (Ruthless Scoping)

To finish this, we are explicitly **NOT** building:

- **High-Fidelity Art:** The world will be untextured cubes. Agents will be capsules.
- **Complex Player UI:** We will use a simple, web-based text interface and debug overlays. The goal is to test a "sliding autonomy" model where the human supervisor can issue high-level commands, not to build a polished game interface.
- **Sound, Music, or Animations:** Agents will glide. The world is silent.
- **Complex Failure Physics:** Agent "loss" will be an instantaneous state change, not a physically simulated destruction sequence.
- **Anything Else:** If it doesn't directly serve to test the **Resilient Swarm** or the **Concurrent Hive**, it's cut.

This sprint will give us the hard data and confidence we need to move forward, proving our foundational tech is not just a theory, but a living, breathing, and resilient reality. Let's build the block. 🚀
