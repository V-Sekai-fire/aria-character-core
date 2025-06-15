# AriaTimestrike

**TimeStrike Tactical Domain Implementation**

This app provides the TimeStrike tactical scenario implementation for AriaEngine, including domain definitions, actions, and planning scenarios. It serves as both the reference implementation for temporal planning development and the production domain for TimeStrike gameplay.

## Architecture

- TimeStrike domain definition with hostage rescue scenarios
- Classical AriaEngine integration with PSO state representation  
- Provider pattern for domain configuration and action implementation
- Test scenarios and baseline performance benchmarks
- Foundation for temporal planner development per ADR-049

## Current Status

Currently uses classical AriaEngine planning capabilities. Temporal planning enhancements are being developed per ADRs 045-050, with staged implementation beginning from the current codebase baseline.

## Installation

Add `aria_timestrike` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:aria_timestrike, "~> 0.1.0"}
  ]
end
```

## Documentation

See the complete TimeStrike documentation at `docs/aria_timestrike/` including:

- Scenario specifications and requirements
- Architecture Decision Records (ADRs) for temporal planning
- Design documentation and implementation guides

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/aria_timestrike>.
