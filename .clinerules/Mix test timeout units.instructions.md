---
applyTo: "**"
textId: "INST-038"
---

## Mix test timeout units

When using `mix test --timeout`, the timeout value is specified in **seconds**, not milliseconds. This is a common source of confusion that can lead to absurdly long test timeouts.

### The principle

The `--timeout` flag for `mix test` expects values in seconds, unlike many other systems that use milliseconds. Misunderstanding this can result in tests running for hours instead of minutes.

### Common error

**Incorrect (thinking it's milliseconds):**
```
mix test --timeout 60000  # This is 16.67 hours, not 1 minute!
```

**Correct (understanding it's seconds):**
```
mix test --timeout 60     # This is 1 minute
```

### Recommended timeout values

- **Quick testing:** `--timeout 60` (1 minute)
- **Normal testing:** `--timeout 120` (2 minutes)
- **Comprehensive testing:** `--timeout 300` (5 minutes)
- **Long-running integration tests:** `--timeout 600` (10 minutes)

### Default behavior

- **Elixir default:** 60 seconds per test
- **Project requirement:** Always include `--timeout` flag (as per INST-034)

### Implementation approach

1. **Always specify timeout:** Include `--timeout` flag in all test commands
2. **Use reasonable values:** Choose timeouts appropriate for your test complexity
3. **Remember the units:** Timeout values are in seconds, not milliseconds
4. **Document long timeouts:** If tests genuinely need longer timeouts, document why

### Benefits

- **Prevents infinite test runs:** Reasonable timeouts catch hanging tests
- **Faster feedback:** Appropriate timeouts provide quick failure notification
- **Predictable CI/CD:** Consistent timeout behavior across environments
- **Developer efficiency:** Tests complete within expected timeframes

### Warning signs

- **Extremely large timeout values:** Numbers like 60000+ likely indicate unit confusion
- **Tests timing out frequently:** May indicate actual performance issues or too-aggressive timeouts
- **Inconsistent behavior:** Different timeout behavior between local and CI environments

This rule prevents the common mistake of treating timeout values as milliseconds when they are actually seconds.
