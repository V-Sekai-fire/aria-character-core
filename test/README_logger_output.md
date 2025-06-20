# Test Output Policy: Logger-Only

All test output in this project is routed through the Elixir `Logger` module, including custom helpers like `TestOutput.trace_puts` and `TestOutput.trace_inspect`.  
Direct use of `IO.puts`, `IO.inspect`, or similar functions is not permitted in test files.

## Guidelines

- Use `Logger` for all test diagnostics, debugging, and trace output.
- Use the `TestOutput` helpers to ensure output only appears in `mix test --trace` mode, keeping passing test runs silent.
- Do not add `IO.puts`, `IO.inspect`, or other direct output calls to tests.

## Rationale

- Ensures clean, professional test output.
- Passing tests remain silent, as required by project guidelines.
- Trace/debug output is available when needed via `--trace`.

## Current Status

As of June 2025, all test output is fully converted to use Logger.  
No further conversion is required.
