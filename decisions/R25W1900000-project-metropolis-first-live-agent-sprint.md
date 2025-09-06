# R25W1900000 - Project Metropolis: The First Live Agent Sprint

**Status:** Proposed

**Date:** September 6, 2025

## Context & Background

To de-risk the core architecture of V-Sekai, this foundational sprint will deliver a complete, end-to-end proof-of-concept. The objective is to validate the entire technology stack in a single, integrated loop: from the AI planner and persistent world database on the backend to the real-time 3D client rendering. This sprint will prove that a stateful Elixir agent can autonomously interact with its world and that these actions can be visually represented in a Godot client using a UDP-based ENet networking layer.

## Primary Objective

By the end of this two-week sprint, a live, end-to-end demonstration will be delivered. An autonomous AI agent, running on the Elixir backend, will execute a plan that permanently alters the world state in a PostgreSQL database, and this change will be reflected in real-time in a 3D Godot client.

## Key Deliverables & Success Criteria

### Key Result #1: The Backend Simulation Loop is Functional

* **Description:** The Elixir application must manage the full lifecycle of an agent's decision-making process, from perception to action and consequence.
* **Success Criteria:**
    * An AI agent (`GenServer`) spawns with a predefined goal (e.g., `acquire_wood`).
    * The agent successfully reads the initial world state from the PostgreSQL database (e.g., a tree with wood exists).
    * The agent uses the HTN planner to generate a valid plan (e.g., `[GoTo(tree), Chop(tree)]`).
    * The agent executes the plan, resulting in a permanent state change written back to the PostgreSQL database (e.g., the tree no longer has wood, the agent now has wood).
    * Upon successful action, the agent **broadcasts the state change** to the ENet network hub.

### Key Result #2: The Godot Visualization Client is Live

* **Description:** A Godot client must connect to the Elixir server and act as a "dumb" visualizer for the world state.
* **Success Criteria:**
    * A simple 3D scene exists containing a capsule (`agent_01`) and a cube (`tree_01`).
    * The Godot client successfully connects to the Elixir ENet hub on startup using the `enet-godot` library.
    * The client receives the `tree_01` state-change broadcast from the server.
    * Upon receiving the message, the corresponding `tree_01` cube in the 3D scene is hidden or removed.

### The Final Test (End-to-End Verification)

> Triggering the agent's logic on the backend results in the "tree" cube disappearing in the running Godot client, with no user interaction in the client itself. This verifies the entire loop is functional.

## Rules of Engagement (Scope Boundaries)

* **Viewer Only:** The Godot client is a passive viewer. No player input or controls.
* **Minimalist Art:** The world is untextured cubes and capsules. No animations.
* **Backend is Truth:** All game logic, state, and planning resides in Elixir.
* **Happy Path Focus:** We will not build complex reconnect logic or error handling.
* **One Agent, One Goal:** This sprint focuses on a single agent to prove the pipeline.

## Resources & Timeline

* **Team:** 1 Engineer
* **Sprint Duration:** **2 Weeks** (10 working days)
* **Total Capacity:** 10 Person-Days
* **Estimated Effort:** **8 Person-Days**
    * *(~4 days for Backend Loop + HTN + DB Integration)*
    * *(~4 days for ENet Hub + Godot Client Integration)*
* **Buffer:** **2 Person-Days**
* **Note on Risk:** The primary risk is the initial integration of three complex, distinct systems (AI Planner, Database, ENet Networking). The 2-day buffer is tight and requires a sharp focus on the defined success criteria to avoid scope creep.

## Implementation Plan

### Phase 1: Backend Simulation Loop (Days 1-4)

- [ ] Set up PostgreSQL database schema for world state
- [ ] Implement AI agent GenServer with goal processing
- [ ] Integrate HTN planner for plan generation
- [ ] Add database read/write operations for state changes
- [ ] Implement ENet broadcast mechanism for state changes
- [ ] Test backend loop end-to-end without client

### Phase 2: Godot Visualization Client (Days 5-8)

- [ ] Create basic 3D scene with agent capsule and tree cube
- [ ] Set up ENet connection to Elixir server
- [ ] Implement message reception for state change broadcasts
- [ ] Add logic to hide/remove tree cube on state change
- [ ] Test client connection and message handling

### Phase 3: Integration & Testing (Days 9-10)

- [ ] Connect backend and client systems
- [ ] Perform end-to-end integration testing
- [ ] Verify state changes propagate from backend to client
- [ ] Document setup and run procedures
- [ ] Final demonstration preparation

## Decision

We will implement this as a unified sprint combining backend AI agent logic with real-time 3D visualization, using ENet for networking between Elixir and Godot. The focus will be on proving the complete technology stack integration rather than building production-ready features.

## Consequences/Risks

### Positive Consequences
- Validates the entire V-Sekai technology stack in one integrated proof-of-concept
- Provides clear evidence of feasibility for autonomous agents with visual representation
- Establishes patterns for future agent-world interactions
- Demonstrates real-time state synchronization between backend and client

### Negative Consequences
- Tight timeline with minimal buffer may lead to rushed implementation
- Minimalist scope may not reveal edge cases in production scenarios
- Focus on happy path may miss error handling requirements
- Single agent/single goal may not scale to multi-agent scenarios

### Risks
- **High Risk:** Integration of three complex systems (AI Planner, Database, ENet) in short timeframe
- **Medium Risk:** ENet-Godot library compatibility and performance
- **Low Risk:** PostgreSQL schema design is straightforward for this scope

## Success Criteria

### Must-Have (Critical Path)
- [ ] Backend agent successfully executes HTN plan and modifies database state
- [ ] State change is broadcast via ENet to connected clients
- [ ] Godot client receives broadcast and updates 3D scene accordingly
- [ ] End-to-end test passes: agent action → database change → client visualization

### Should-Have (Important but not critical)
- [ ] Clean separation between backend logic and client visualization
- [ ] Documented setup and run procedures
- [ ] Basic error logging for debugging

### Nice-to-Have (If time permits)
- [ ] Multiple agent types with different goals
- [ ] Additional world objects beyond tree/agent
- [ ] Basic animation for state changes

## Related ADRs

- **ADR-XXX:** Temporal Planner Architecture (for HTN integration)
- **ADR-YYY:** Database Schema Design (for world state persistence)
- **ADR-ZZZ:** Godot Integration Patterns (for client visualization)

## Notes

This sprint serves as the foundation for V-Sekai's agent-driven world simulation. Success here will de-risk the core architecture and provide confidence for scaling to multiple agents and complex world interactions.
