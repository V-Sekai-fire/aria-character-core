# AriaFate

Character generation and management system for Fate RPG system integration.

## Purpose

AriaFate provides character generation, domain modeling, and SRD parsing capabilities for Fate-based role-playing game systems. It handles character sheet generation, planner domain integration, and System Reference Document processing.

## Setup

This app is part of the aria-character-core umbrella project. Run commands from the umbrella root:

```bash
# Compile the app
mix compile

# Run tests
mix test apps/aria_fate

# Run specific tests
mix test apps/aria_fate/test/aria_fate_test.exs
```

## Usage

### Character Generation

```elixir
# Generate a character
character = AriaFate.Character.generate()

# Create character with specific aspects
character = AriaFate.Character.create(%{
  name: "Example Character",
  high_concept: "Skilled Detective",
  trouble: "Too Curious for Own Good"
})
```

### Planner Domain Integration

```elixir
# Get planner domain configuration
domain = AriaFate.PlannerDomain.get_domain()

# Process domain actions
actions = AriaFate.PlannerDomain.get_actions()
```

### SRD Processing

```elixir
# Parse SRD content
parsed_data = AriaFate.SrdParser.parse(srd_content)

# Extract specific elements
skills = AriaFate.SrdParser.extract_skills(parsed_data)
```

## Developer Information

- **Module Structure**: External API through `AriaFate` module with internal implementation in `AriaFate.*` modules
- **Dependencies**: Uses Jason for JSON processing
- **Testing**: Comprehensive test coverage for character generation and domain processing
