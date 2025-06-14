# AriaTimestrike Core

**Foundational TimeStrike implementation using classical AriaEngine planning**

This is the core/foundational implementation of the TimeStrike tactical scenario using the classical AriaEngine planner without temporal extensions. It serves as the baseline reference implementation for comparison with the temporal planner version.

## Architecture

- Uses classical AriaEngine state representation (PSO triples)
- IPyHOP hierarchical task network planning
- No temporal reasoning or backtracking capabilities
- Serves as the stable baseline for temporal planner development

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `aria_timestrike_core` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:aria_timestrike_core, "~> 0.1.0"}
  ]
end
```

## Documentation

See the main TimeStrike design document at `apps/aria_timestrike/docs/readme.md` for the complete scenario specification and requirements.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/aria_timestrike_core>.
