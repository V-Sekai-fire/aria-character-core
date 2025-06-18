---
applyTo: "**"
textId: "INST-006"
---

## Reduce test log spam

Passing tests should be silent and produce no log output. This is a fundamental principle of good test design.

### The principle

Only failing tests (or tests with explicit verbose flags) should produce output. Passing tests should run silently.

### Exception for trace mode

**`mix test --trace` should provide normal logging output.** The `--trace` flag enables developers to see detailed test execution, including all IO.puts and IO.inspect statements. This allows for targeted debugging by running specific files or test lines with full visibility.

**Usage examples:**
- `mix test --trace` - Enable verbose output for all tests
- `mix test --trace test/specific_file_test.exs` - Verbose output for specific file
- `mix test --trace test/specific_file_test.exs:123` - Verbose output for specific test line

### Why this matters

- **Clean test output:** Makes it easy to spot actual problems
- **Faster debugging:** No need to scan through irrelevant output
- **Better signal-to-noise ratio:** Important information stands out
- **Professional appearance:** Clean, focused test runs

### Implementation approach

- **Remove unnecessary logging:** Don't log routine operations in tests
- **Use conditional logging:** Only log when tests fail or when explicitly requested
- **Test in quiet mode:** Verify that passing tests produce no output

### Benefits

- **Easier problem identification:** Failed tests are immediately visible
- **Cleaner CI/CD output:** Build logs focus on actual issues
- **Better developer experience:** Less noise when running tests locally

This follows the simple solutions principle - the simple solution is to make tests quiet by default.
