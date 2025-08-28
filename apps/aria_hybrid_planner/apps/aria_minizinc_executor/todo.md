## Final Architecture Specification

Here's the complete implementation plan for converting `apps/aria_minizinc_executor` into a Unifex C node:

### Core Requirements Met

✅ **Embed libminizinc** as library (not CLI)  
✅ **Maintain exact same API** for backward compatibility  
✅ **Keep EEx template rendering** in Elixir  
✅ **Bundle libminizinc** for easy deployment  
✅ **Maintain detailed error reporting** (timing, raw output, etc.)  
✅ **Support configurable solvers** via options

## Complete Implementation Plan

### Phase 1: Project Structure Setup (1-2 hours)

**New Dependencies in `mix.exs`:**

```elixir
defp deps do
  [
    {:unifex, "~> 1.1"},
    {:bundlex, "~> 1.3"},
    # ... existing deps
  ]
end
```

**New Directory Structure:**

```
apps/aria_minizinc_executor/
├── lib/aria_minizinc_executor/
│   ├── native.ex                 # New: Unifex spec
│   └── unifex_executor.ex        # New: NIF wrapper
├── c_src/
│   ├── aria_minizinc_native.spec.exs  # Unifex specification
│   ├── aria_minizinc_native.cpp       # Main NIF implementation
│   ├── minizinc_wrapper.h/.cpp        # libminizinc integration
│   └── bundlex.exs                    # Build configuration
└── bundled/
    └── libminizinc/              # Bundled library
```

### Phase 2: Unifex Integration (2-3 hours)

**Unifex Spec (`c_src/aria_minizinc_native.spec.exs`):**

```elixir
module AriaMinizincExecutor.Native do
  spec solve_raw(model_content :: string, options :: payload) ::
    {:ok, {status :: atom, solution :: payload, metadata :: payload}} |
    {:error, {error_type :: atom, details :: payload}}

  spec check_availability() ::
    {:ok, version :: string} |
    {:error, reason :: string}

  spec list_solvers() ::
    {:ok, solvers :: [string]} |
    {:error, reason :: string}
end
```

### Phase 3: C++ Implementation (4-6 hours)

**Core NIF Functions (`aria_minizinc_native.cpp`):**

```cpp
#include <minizinc/solvers/MIP/MIP_wrap.hh>
#include <minizinc/solver.hh>
#include <chrono>

UNIFEX_TERM solve_raw(UnifexEnv* env, char* model_content, UnifexPayload* options) {
  auto start_time = std::chrono::steady_clock::now();

  // Parse options (solver, timeout, output_mode, etc.)
  SolverOptions solver_opts = parse_unifex_options(options);

  // Initialize MiniZinc model and solver
  MiniZinc::Model* model = parse_model_string(model_content);
  MiniZinc::Solver solver = create_solver(solver_opts.solver_name);

  // Execute solving with timeout
  SolutionResult result = solve_with_timeout(model, solver, solver_opts);

  auto end_time = std::chrono::steady_clock::now();

  // Build detailed response matching current format
  return create_unifex_result(env, result, start_time, end_time);
}
```

**libminizinc Wrapper (`minizinc_wrapper.cpp`):**

```cpp
class MinizincSolver {
private:
  std::unique_ptr<MiniZinc::Solver> solver_;
  std::chrono::milliseconds timeout_;

public:
  SolutionResult solve(const std::string& model_content,
                      const SolverOptions& options);
  std::vector<std::string> available_solvers();
  std::string version_info();
};
```

### Phase 4: Elixir Integration Layer (2-3 hours)

**NIF Wrapper (`unifex_executor.ex`):**

```elixir
defmodule AriaMinizincExecutor.UnifexExecutor do
  use AriaMinizincExecutor.Native

  @behaviour AriaMinizincExecutor.ExecutorBehaviour

  def exec_raw(minizinc_content, opts \\ []) do
    options_payload = build_options_payload(opts)

    case __MODULE__.solve_raw(minizinc_content, options_payload) do
      {:ok, {status, solution, metadata}} ->
        {:ok, format_solution_result(status, solution, metadata)}
      {:error, {error_type, details}} ->
        {:error, format_error_result(error_type, details)}
    end
  end

  def check_availability do
    __MODULE__.check_availability()
  end

  # Format results to match exact current API
  defp format_solution_result(status, solution, metadata) do
    %{
      status: status,
      solution: parse_solution_data(solution),
      solving_start: metadata.solving_start,
      solving_end: metadata.solving_end,
      duration: metadata.duration,
      solve_time_ms: metadata.solve_time_ms,
      raw_output: metadata.raw_output
    }
  end
end
```

**Main Module Update (`aria_minizinc_executor.ex`):**

```elixir
# Just change the executor implementation:
defmodule AriaMinizincExecutor do
  # ... same public API ...

  defp executor_impl, do: AriaMinizincExecutor.UnifexExecutor

  def exec_raw(minizinc_content, options \\ []) do
    executor_impl().exec_raw(minizinc_content, options)
  end

  # ... rest unchanged, TemplateRenderer stays the same
end
```

### Phase 5: Build Configuration (1-2 hours)

**Bundlex Configuration (`bundlex.exs`):**

```elixir
defmodule AriaMinizincExecutor.BundlexProject do
  use Bundlex.Project

  def project do
    [
      nifs: nifs()
    ]
  end

  defp nifs do
    [
      aria_minizinc_native: [
        sources: ["aria_minizinc_native.cpp", "minizinc_wrapper.cpp"],
        includes: ["bundled/libminizinc/include"],
        libs: ["bundled/libminizinc/lib/libminizinc", "stdc++"],
        pkg_configs: [],
        language: :cpp,
        cpp_std: 17
      ]
    ]
  end
end
```

### Phase 6: Testing & Validation (2-3 hours)

**Test Compatibility:**

- All existing tests should pass unchanged
- Add NIF-specific integration tests
- Performance benchmarking vs current Porcelain approach
- Memory leak testing for long-running processes

### Implementation Benefits

1. **Performance**: ~10-50x faster (no process spawning, direct library calls)
2. **Memory**: Lower memory overhead (no temporary files, subprocess pipes)
3. **Reliability**: Better error handling, no subprocess race conditions
4. **Deployment**: Single artifact with bundled dependencies
5. **Compatibility**: Exact drop-in replacement, zero breaking changes

### Estimated Timeline: 10-15 hours total

This plan maintains full backward compatibility while delivering significant performance improvements through embedded libminizinc. The hybrid approach keeps the complexity manageable by preserving Elixir template rendering while moving only the execution to C++.
