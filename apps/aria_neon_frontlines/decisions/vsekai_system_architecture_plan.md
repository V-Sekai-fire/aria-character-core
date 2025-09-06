## Announcing: "Project Metropolis" - The Genesis Block Sprint

This isn't a game alpha; it's a **focused technical sprint** with one objective: to build a live, persistent city block that proves our riskiest technologies can create emergent, intelligent life. We're treating this like a simulation stress test—functional, deep, and data-driven over flashy.

### The Mission

In this sprint, we will build a live, single-instance micro-verse to prove our core architecture is ready for prime time. By the end, we'll have a running server that validates our **AI Planning Engine** can manage a complex economy and our **Erlang backend** can handle massive concurrency.

### The Playground (Our "Genesis Block")

We're building the simplest possible "city" to act as a testbed. Think of it as a **live ecosystem stress test**, not a polished game slice.

- **The World:** One greybox city block, running as a single, persistent server process.
- **The "Inhabitants":** Hundreds of AI agents driven by our goal-task temporal planner, alongside a handful of player-observers.
- **The "Gameplay":** Players don't complete missions; they observe the simulation. They can interact with the world by placing resource orders or tactical objectives to see how the AI agents adapt and coordinate.

### Sprint Goal #1: The Emergent Ecosystem

This is the main event. We need to build a **real, functional AI-driven economy** that operates without direct developer intervention.

- **The Challenge:** The Hierarchical Task Network (HTN) must coordinate dozens of multi-agent plans for gathering, crafting, and distribution. The system must intelligently schedule complex tasks, manage resource contention, and adapt to changing conditions.
- **Definition of Done:** We can demo an AI-run supply chain operating for 24 hours straight. "Gatherer" AIs deplete resource nodes, "Crafter" AIs process materials, and "Tactician" AIs coordinate security patrols. The system must demonstrate **stable, complex, multi-step problem-solving** in real-time with **zero collapses**.

---

### Sprint Goal #2: The Concurrent Hive

This tests if our server architecture is solid. We'll implement a barebones slice of the world and flood it with actors.

- **The Challenge:** The Erlang backend must handle thousands of lightweight processes—one for every AI and player—on a single server instance. The in-memory state must sync flawlessly across this massive population with zero-IOPS transfers.
- **Definition of Done:** The Genesis Block can sustain **5,000 concurrent AI and player processes** while maintaining a stable server tick rate. The system must pass a "Chaos Test," where an automated script bombards the server with thousands of planning requests and state changes to try and crash the BEAM VM.

### The "Sim" Rules (Ruthless Scoping)

To finish this, we are explicitly **NOT** building:

- **High-Fidelity Art:** The world will be untextured cubes. Agents will be capsules.
- **Player-Facing UI:** We'll use a web-based text interface and debug overlays to interact with the simulation.
- **Sound, Music, or Animations:** Agents will glide. The world is silent.
- **Direct Player Combat:** The "Combatant" role exists only as a set of behaviors for the AI to test tactical planning.
- **Anything Else:** If it doesn't directly serve to test the **Emergent Ecosystem** or the **Concurrent Hive**, it's cut.

This sprint will give us the hard data and confidence we need to move forward, proving our foundational tech is not just a theory, but a living, breathing reality. Let's build the block. 🚀
