---
applyTo: "**"
textId: "INST-034"
---

## Mix Test Timeout

All `mix test` commands must include a `--timeout` flag to prevent tests from running indefinitely.

### Process

1.  When executing `mix test`, always include the `--timeout` flag.
2.  The default timeout should be 60 seconds.
3.  If a specific test requires a longer or shorter timeout, it can be explicitly overridden.

### Rationale

This ensures that test runs complete within a reasonable timeframe, preventing CI/CD pipelines from hanging and providing faster feedback on test failures.
