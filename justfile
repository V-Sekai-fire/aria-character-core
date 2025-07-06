# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Justfile for Widget Assembly Solver Benchmarking
# Uses hyperfine for performance measurement

# Default recipe - show available commands
default:
    @just --list

# Run MiniZinc solver with timing
minizinc:
    @echo "🔧 Running MiniZinc Widget Assembly Solver"
    @echo "=" | tr '\n' '=' | head -c 50 && echo
    @echo "📊 Solution Output:"
    @minizinc --solver org.minizinc.mip.coin-bc widget_assembly.mzn
    @echo "✅ MiniZinc execution completed"

# Benchmark MiniZinc solver with hyperfine
bench-minizinc:
    @echo "⚡ Benchmarking MiniZinc Widget Assembly Solver"
    @echo "=" | tr '\n' '=' | head -c 50 && echo
    hyperfine --warmup 3 --runs 10 \
        --show-output \
        --export-json minizinc_benchmark.json \
        --export-markdown minizinc_benchmark.md \
        'minizinc --solver org.minizinc.mip.coin-bc widget_assembly.mzn'

# MCP commands - DISCONNECTED/PAUSED (ADR-188)
# Uncomment and implement when MCP functionality is re-enabled
# See ADR-188 for disconnection details and re-enablement process

# Run MCP solver (PAUSED - ADR-188)
mcp:
    @echo "🚀 MCP Widget Assembly Solver - CURRENTLY PAUSED"
    @echo "=" | tr '\n' '=' | head -c 50 && echo
    @echo "❌ MCP functionality is disconnected per ADR-188"
    @echo "📋 To re-enable: See ADR-188 re-enablement process"
    @echo "🔧 Current status: Infrastructure preserved but disconnected"

# Benchmark MCP solver (PAUSED - ADR-188)
bench-mcp:
    @echo "⚡ MCP Benchmarking - CURRENTLY PAUSED"
    @echo "=" | tr '\n' '=' | head -c 50 && echo
    @echo "❌ MCP benchmarking is disconnected per ADR-188"
    @echo "📋 To re-enable: See ADR-188 re-enablement process"

# Compare both solvers with hyperfine
bench-compare:
    @echo "🔍 Comparing MiniZinc vs MCP Solvers"
    @echo "=" | tr '\n' '=' | head -c 50 && echo
    hyperfine --warmup 3 --runs 10 \
        --export-json comparison_benchmark.json \
        --export-markdown comparison_benchmark.md \
        --command-name "MiniZinc" 'minizinc --solver org.minizinc.mip.coin-bc widget_assembly.mzn' \
        --command-name "MCP" 'elixir scripts/test_widget_assembly_mcp.exs'

# Run both solvers and compare solutions
test-both:
    @echo "🧪 Testing Both Solvers"
    @echo "=" | tr '\n' '=' | head -c 50 && echo
    @echo "📋 MiniZinc Solution:"
    @just minizinc
    @echo
    @echo "🚀 MCP Solution:"
    @just mcp

# Clean benchmark files
clean:
    @echo "🧹 Cleaning benchmark files"
    rm -f *.json *.md

# Show benchmark results
results:
    @echo "📊 Benchmark Results"
    @echo "=" | tr '\n' '=' | head -c 50 && echo
    @if [ -f "comparison_benchmark.md" ]; then \
        echo "🔍 Comparison Results:"; \
        cat comparison_benchmark.md; \
    elif [ -f "minizinc_benchmark.md" ]; then \
        echo "⚡ MiniZinc Results:"; \
        cat minizinc_benchmark.md; \
    else \
        echo "No benchmark results found. Run 'just bench-minizinc' or 'just bench-compare' first."; \
    fi

# MCP validation commands - DISCONNECTED/PAUSED (ADR-188)
# These commands reference MCPToolsV2 which is part of the paused MCP infrastructure

# Test MCP validation pipeline (PAUSED - ADR-188)
test-validation:
    @echo "🔍 MCP Validation Pipeline - CURRENTLY PAUSED"
    @echo "=" | tr '\n' '=' | head -c 50 && echo
    @echo "❌ MCP validation functionality is disconnected per ADR-188"
    @echo "📋 MCPToolsV2 module is part of paused MCP infrastructure"
    @echo "🔧 To re-enable: See ADR-188 re-enablement process"

# Test MCP validation pipeline with custom problem (PAUSED - ADR-188)
test-validation-problem PROBLEM_NAME:
    @echo "🔍 MCP Validation Pipeline for {{PROBLEM_NAME}} - CURRENTLY PAUSED"
    @echo "=" | tr '\n' '=' | head -c 50 && echo
    @echo "❌ MCP validation functionality is disconnected per ADR-188"
    @echo "📋 MCPToolsV2 module is part of paused MCP infrastructure"
    @echo "🔧 To re-enable: See ADR-188 re-enablement process"

# Show verified ground truth solution
solution:
    @echo "✅ Verified Ground Truth Solution"
    @echo "=" | tr '\n' '=' | head -c 50 && echo
    @if [ -f "widget_assembly_solution.json" ]; then \
        echo "📋 Widget Assembly Optimal Solution:"; \
        cat widget_assembly_solution.json | jq '.expected_solution.schedule[] | "  \(.id): start=\(.start_time), end=\(.end_time), duration=\(.duration)"' -r; \
        echo; \
        echo "📊 Performance Summary:"; \
        cat widget_assembly_solution.json | jq '"  Makespan: \(.expected_solution.analysis.makespan) minutes"' -r; \
        cat widget_assembly_solution.json | jq '"  Solver Time: \(.verification.performance.mean_time_ms)ms ± \(.verification.performance.std_dev_ms)ms"' -r; \
        cat widget_assembly_solution.json | jq '"  Resource Utilization: \(.expected_solution.resource_utilization.workstation.utilization * 100)%"' -r; \
    else \
        echo "❌ Ground truth solution file not found."; \
    fi

# Validate MiniZinc installation and solvers
check:
    @echo "🔍 Checking MiniZinc Installation"
    @echo "=" | tr '\n' '=' | head -c 50 && echo
    @echo "MiniZinc version:"
    @minizinc --version
    @echo
    @echo "Available solvers:"
    @minizinc --solvers
    @echo
    @echo "Hyperfine version:"
    @hyperfine --version

# Quick test - just run MiniZinc once
quick:
    @just minizinc

# Full workflow - check, test, benchmark
full:
    @just check
    @echo
    @just test-both
    @echo
    @just bench-compare
    @echo
    @just results
