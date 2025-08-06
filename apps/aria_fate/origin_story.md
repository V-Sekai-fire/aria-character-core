# AriaFate

AriaFate is a Fate Core RPG character sheet generator and game master assistant that leverages the aria_hybrid_planner for systematic character creation and narrative planning.

## Origin Story - The 5 Ws

**Who:** iFire and lito (developers)

**What:** Create aria_fate app using CC-BY SRDs for character sheet generation via hybrid temporal planner

**When:** Current development phase

**Where:** aria-character-core umbrella project

**Why:** LLMs forget decisions, can't follow instructions, won't complete task lists - need temporal planner for AI game director functionality

## Problem Statement

LLMs have fundamental limitations:

- Forget previous decisions
- Can't follow instructions consistently
- Given task lists, won't complete them

This application addresses these problems by using the hybrid temporal planner to generate consistent character sheets following Fate Core rules and serve as an AI game director similar to Left 4 Dead's Director AI.

## Solution Approach

Hybrid temporal planner generates character sheets using:

- Third-party CC-BY SRDs as source material
- Temporal planning for consistent decision tracking
- AI game director capabilities (Left4Dead style)

## Features

- **Character Sheet Generation**: Creates complete Fate Core character sheets with aspects, skills, stunts, and stress tracks
- **SRD Integration**: Uses CC-BY licensed Fate SRDs for rule-compliant character generation
- **Temporal Planning**: Leverages aria_hybrid_planner for consistent decision-making across character creation steps
- **Narrative Planning**: Plans character arcs and story beats using temporal constraints

## Technical Goals

- Character sheet generation from SRD data
- Temporal planner domain integration
- AI game director functionality
- Simple index card output format
- PostgreSQL compatible database for persistent character data storage
- Model Context Protocol (MCP) servers to expose character data to large language models:
  - Staff MCP server with full administrative access
  - User MCP server with restricted player access

## Dependencies

- **Floki**: For parsing HTML SRD documents
- **Jason**: For JSON data handling
- **aria_hybrid_planner**: For systematic task planning and execution

## Usage

```elixir
# Generate a basic character sheet
{:ok, character} = AriaFate.generate_character()

# Generate character with specific constraints
{:ok, character} = AriaFate.generate_character(%{
  concept: "Wizard Detective",
  trouble: "Magic Always Leaves a Trail",
  refresh: 3
})

# Plan a character arc
{:ok, arc} = AriaFate.plan_character_arc(character, episodes: 5)
```

## Character Sheet Structure

Generated characters follow standard Fate Core format:
- High Concept and Trouble aspects
- Three additional aspects from character phases
- Skill pyramid with appropriate ratings
- Stunts based on character concept
- Stress and consequence tracks

## Implementation Notes

Character sheet creation achievable through:

- Excel scripting equivalent functionality
- SRD parser integration
- Planner domain methods
- Consistent state management

## Integration with Hybrid Planner

The hybrid temporal planner ensures:
- Consistent aspect generation that supports the character concept
- Skill selection that matches the character's background
- Stunt creation that enhances the character's abilities
- Narrative planning that creates compelling story arcs

This systematic approach prevents the common LLM problems of forgetting previous decisions or failing to complete task lists.
