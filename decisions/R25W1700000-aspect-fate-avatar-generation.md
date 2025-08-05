# R25W1700000: ASPECT Fate Avatar Generation

<!-- @adr_serial R25W1700000 -->

## Status

Proposed

## Context

Build unified character sheet + avatar pipeline. Leverage existing Phoenix LiveView + FLUX API. Create commercial tabletop-to-VR character bridge.

## Decision

Build ASPECT: Fate SRD character creation → optimized FLUX prompts → 2D avatar art generation.

## Implementation (3-4 Hours)

**Features**: OAuth (Google/Discord/GitHub) + PostgreSQL sessions + raw text input + 300+ aspect dataset search + hybrid planner (Fly.io) + Replicate FLUX API + dual MCP servers + feedback collection + learning metrics

**Removed**: Multiple avatars, selection UI, character forms, templates

**Stack**: Phoenix LiveView + PostgreSQL on Fly.io, Ueberauth OAuth, HTTPoison, AriaHybridPlanner, Staff/User MCP servers

**Demo**: OAuth login → raw text → dataset search → hybrid planner → FLUX generation → learning metrics + feedback → improvement demonstration

**Commercial**: Character packages ($15-50), VTuber development, tabletop groups, RPG-to-VR bridge

**Related**: R25W009BCB5 (MVP), R25W119A759 (Godot MCP), Phoenix LiveView

**Timeline**: One afternoon → Phase 1 (Elixir) → Phase 2 (Python DIN) → Phase 3 (Multi-region GPU)

**Deployment**: Fly.io + PostgreSQL + OAuth + Replicate token + hybrid planner URL + dual MCP
