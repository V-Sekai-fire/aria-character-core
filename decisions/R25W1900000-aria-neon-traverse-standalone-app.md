## Announcing: "Operation Neon Spike" - A 2-Week Tech Sprint

This isn't a normal development phase; it's a focused **two-week internal sprint** with a single objective: to build a live, playable "greybox" demo that proves our two riskiest technologies work together. We're treating this like a game jam—fast, focused, and functional over flashy.

### The Mission

In two weeks, we will build a live, multi-shard micro-MMO to prove our core tech is ready for prime time. By the end, we'll have a running demo that validates our architecture for seamless world traversal and a secure player economy.

### The Playground (Our "Game")

We're building the simplest possible "game" to act as a testbed. Think of it as a **live technical stress test**, not a polished slice.

- **The World:** Two barren, greybox zones: `shard-01` and `shard-02`. Each runs as a completely independent server process. A glowing red line on the floor is the "Shard Boundary."
- **The "Gameplay":**
  1.  Players can run between the two zones.
  2.  Players are given one item: a "Widget."
  3.  Players can trade this "Widget" with each other.

### Sprint Goal #1: The Shard Jump

This is the main event. We need to build a **real, functional shard transfer** that hands off a player's connection and state between two live server processes.

- **The Challenge:** When a player crosses the red line from `shard-01` to `shard-02`, the system must save their state, disconnect them from the first process, and seamlessly reconnect them to the second process with all their data intact.
- **Definition of Done:** We can demo a player running back and forth across the boundary with **no visible loading screen** and **zero data loss**. The entire transfer feels instant.

---

### Sprint Goal #2: The Secure Swap

This tests if our economy's foundation is solid. We'll implement a barebones, server-authoritative trading system.

- **The Challenge:** The backend must handle trade requests for the "Widget" as a single, unbreakable transaction.
- **Definition of Done:** Two players can trade Widgets, and we can prove it's **100% immune to duplication**. The system must pass a "Chaos Test," where an automated script bombards the server with thousands of trade requests to try and break it.

### The "Jam" Rules (Ruthless Scoping)

To finish in two weeks, we are explicitly **NOT** building:

- **Fancy Art:** The world will be untextured cubes and planes.
- **Complex UI:** We'll use placeholder buttons and text.
- **Sound, Music, or Animations:** Characters will glide. The world is silent.
- **Anything Else:** If it doesn't directly serve to test the **Shard Jump** or the **Secure Swap**, it's cut.

This sprint will give us the hard data and confidence we need to move forward, proving our foundational tech is not just a theory, but a reality. Let's get it done. 🚀
