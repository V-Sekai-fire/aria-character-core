# R25W1700000: ASPECT Fate Avatar Generation

<!-- @adr_serial R25W1700000 -->

## Status

Proposed

## Context

Build unified character sheet + avatar pipeline. Leverage existing Phoenix LiveView + FLUX API. Create commercial tabletop-to-VR character bridge.

## Decision

Build ASPECT: Fate SRD character creation → optimized FLUX prompts → 2D avatar art generation.

## Implementation Plan (One Afternoon) - Bitter Lesson Aligned

### Core Components (3-4 Hour Target)

**Essential Features**:

- [ ] OAuth login (Google/Discord/GitHub via Ueberauth)
- [ ] PostgreSQL user session tracking (Ecto schemas)
- [ ] Raw text character input (no structured forms)
- [ ] Search-based code name generation (300+ aspect examples dataset)
- [ ] Hybrid planner conversation optimization (Fly.io service)
- [ ] Replicate.com FLUX API integration (existing models)
- [ ] User MCP server (character generation, feedback submission)
- [ ] Staff MCP server (dataset management, analytics, system monitoring)
- [ ] Feedback collection (thumbs up/down → PostgreSQL)
- [ ] Learning metrics display (search space + improvement tracking)

**Removed Scope**: Multiple avatars, selection UI, character forms, templates

**Data Models**: generation_feedbacks, user_sessions (PostgreSQL schemas)

**Architecture**: Hybrid planner + aspect dataset search + learning from user feedback

**Aspect Dataset Approach**: 300+ existing aspect examples → computational pattern discovery → no hardcoded naming rules

## Technical Stack

**Infrastructure**: Phoenix LiveView + PostgreSQL on Fly.io
**Auth**: Google/Discord/GitHub OAuth via Ueberauth  
**API**: Replicate.com FLUX models via HTTPoison
**Planner**: AriaHybridPlanner service on Fly.io
**MCP Servers**: Staff MCP (admin/analytics) + User MCP (generation/feedback)
**Learning**: Aspect dataset search + collaborative filtering → LibRecommender DIN (Phase 2)
**Dataset**: 300+ aspect examples for computational pattern discovery

## Success Criteria (Bitter Lesson Aligned)

**Demo Flow**:

1. OAuth login → raw text input → search-generated code name
2. Search 300+ aspect dataset for character patterns (no hardcoded rules)
3. Hybrid planner optimizes LLM conversation until requirements captured
4. Single FLUX generation via Replicate API
5. Display with learning metrics + dataset search results
6. Demonstrate improvement over multiple generations

**Validation**: Dataset search algorithms, learning from feedback, computational scaling potential

## Commercial Value

**Revenue**: Character packages ($15-50), VTuber development, tabletop groups
**Market**: Bridge tabletop RPG + VR communities, professional character tools

## Related ADRs

- R25W009BCB5: Concrete MVP Definition
- R25W119A759: Godot MCP Server
- Phoenix LiveView infrastructure

## Timeline

**One Afternoon (3-4 hours)**:

- Fly.io deployment + PostgreSQL + OAuth
- Search/learning algorithms + Replicate integration
- Hybrid planner service + feedback collection

**Scaling Path**:

- Phase 1: Simplified Elixir algorithms
- Phase 2: Python LibRecommender DIN integration
- Phase 3: Multi-region + GPU acceleration

**Deployment**: Fly.io with PostgreSQL, OAuth config, Replicate API token, hybrid planner URL, dual MCP servers (staff/user)

**MCP Architecture**:

- **Staff MCP**: Dataset management, learning system tuning, analytics dashboard, system monitoring
- **User MCP**: Character generation, avatar creation, feedback submission, basic metrics viewing
