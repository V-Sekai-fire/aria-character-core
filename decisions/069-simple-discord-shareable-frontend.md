---
date: 2025-06-15
status: proposed
---

# ADR-069: Simplest Shareable Front-end for Discord

## Context

The project needs a simple, visually comprehensible front-end that can be easily shared with friends on Discord for feedback and demonstration. The primary goal is simplicity of implementation and ease of sharing, not feature completeness or visual polish.

We have considered several front-end technologies in the past, including a Terminal User Interface (TUI), a Godot engine client, and various web technologies.

## Decision

We will implement a web-based front-end, as a URL is the most accessible and frictionless way to share a project on Discord. A standalone client (like Godot) or a command-line TUI creates too much friction for casual viewing.

### Technology Ranking

The following web technologies have been considered and are ranked from simplest to most complex:

1. **Emoji/UTF-8 Text (Highest Recommendation):**
    * **Pros:** The absolute simplest implementation. Can be rendered in a basic Phoenix LiveView with plain HTML and CSS. It is universally supported, expressive, and incredibly easy to make dynamic.
    * **Cons:** Limited visual fidelity.

2. **SVG (Scalable Vector Graphics):**
    * **Pros:** Excellent for rendering simple, scalable 2D graphics and diagrams. Can be directly manipulated with CSS and JavaScript.
    * **Cons:** Becomes complex to manage for highly dynamic or interactive scenes.

3. **Lottie Animations:**
    * **Pros:** Allows for high-quality, pre-rendered vector animations. Great for polished, non-interactive visual sequences.
    * **Cons:** Not suitable for real-time, interactive displays. The rendering pipeline (e.g., using ThorVG on the server) adds significant complexity.

4. **Three.js:**
    * **Pros:** A powerful library for rich 3D experiences.
    * **Cons:** Very high complexity and a steep learning curve. Previous ADRs have noted this was too complex for rapid prototyping under tight time constraints.

Given the primary goal of simplicity, the **Emoji/UTF-8 Text** approach is the recommended starting point.

## Implementation Plan

* [ ] Create a new Phoenix application, `aria_interface`, to serve as the web front-end.
* [ ] Implement a basic Phoenix LiveView to render the core game state.
* [ ] Use simple Emoji and UTF-8 text within the LiveView to represent game elements and status.
* [ ] Ensure the application can be easily run in a development environment and served over the local network for testing.
* [ ] Document the process for sharing the interface with others (e.g., using a tunneling service like `ngrok` for easy Discord sharing).

## Success Criteria

* A working web interface is created that renders the game state.
* The interface is accessible via a URL.
* The implementation is simple enough to be completed quickly, focusing on core functionality over visual polish.
