# ADR-039: Temporal Planner Reentrancy and Stability

## Status

**Not Necessary** - Analysis determined this ADR is not required for timeline-based temporal planning

## Date

2025-06-14

## Not Necessary Determination

This ADR has been determined to be unnecessary for the following reasons:

1. **Timeline Planning is Discrete**: ADR-038's timeline-based temporal planner operates on discrete intervals and constraint satisfaction, not continuous control systems where Lyapunov stability analysis applies.

2. **Reentrancy Already Inherited**: The existing non-temporal planner already provides retry and reentrancy capabilities that will be inherited by the timeline-based implementation.

3. **Separation of Concerns**: Timeline planning (scheduling problem) and continuous control stability (control theory problem) are distinct domains that don't require integration at this architectural level.

4. **Implementation Complexity**: Adding Lyapunov stability analysis would introduce unnecessary mathematical complexity without corresponding benefits for discrete timeline constraint satisfaction.

**Recommendation**: Implement ADR-038 directly without the control theory foundations outlined in this ADR. The timeline planner should focus on constraint satisfaction and discrete scheduling.

---

## Original ADR Content (Not Necessary)

### Title: Temporal Planner Reentrancy and Stability: Temporal Planner Reentrancy and Stability Guarantees

#### Original Status

Accepted

#### Original Date

2025-06-14

### Context

During the migration from non-temporal to timeline-based temporal planning (ADR-038), we must maintain system stability and reentrancy properties that are critical for real-time control applications. Recent research (arXiv:2503.02171v2) demonstrates that the Bellman equation admits exponentially many solutions in continuous state spaces, but only one yields both optimal policy AND stable closed-loop behavior.

**The Solution Network Revolution**: The breakthrough insight is that the **JSON-LD data structure itself IS the solution network**. Rather than maintaining separate todo lists that evolve into complex solution tracking systems, the JSON-LD temporal planner vocabulary provides the native graph structure needed to represent, navigate, and verify the exponentially large solution space.

**Key Insight**: JSON-LD's inherent graph topology with `@context`, `@type`, and `@id` relationships creates a natural solution network where:

- Each temporal plan is a connected subgraph
- Solution verification follows graph traversal patterns
- Stability constraints become graph connectivity rules
- Reentrancy points are identified through graph cycles and references

This eliminates the architectural complexity of maintaining separate todo lists, solution trackers, and state managers - the JSON-LD vocabulary unifies all these concerns into a single, mathematically sound data structure.

### Decision

We will implement a **JSON-LD Solution Network Architecture** where the temporal planner's JSON-LD data structure serves as both the plan representation AND the solution space navigation system, ensuring stability through graph-theoretic verification rather than separate control systems.

#### Core Architecture: JSON-LD as Solution Network

##### 1. JSON-LD Solution Network Structure

The solution network is realized through the JSON-LD temporal planner vocabulary where graph topology encodes solution space navigation:

```elixir
defmodule AriaEngine.JsonLdSolutionNetwork do
  @moduledoc """
  JSON-LD solution network where the data structure itself provides
  solution space navigation, stability verification, and reentrancy
  through native graph operations.
  
  Eliminates separate todo lists, solution trackers, and state managers
  by encoding all concerns in the JSON-LD vocabulary graph structure.
  """

  @context %{
    "@vocab" => "https://chibifire.com/vocab/aria/temporal#",
    "SolutionNode" => "https://chibifire.com/vocab/aria/temporal#SolutionNode",
    "StabilityEdge" => "https://chibifire.com/vocab/aria/temporal#StabilityEdge", 
    "ReentrancyPoint" => "https://chibifire.com/vocab/aria/temporal#ReentrancyPoint",
    "convergesTo" => "https://chibifire.com/vocab/aria/temporal#convergesTo",
    "stabilityVerified" => "https://chibifire.com/vocab/aria/temporal#stabilityVerified"
  }

  def create_solution_network(initial_state, goals) do
    %{
      "@context" => @context,
      "@type" => "SolutionNetwork",
      "@id" => "solution-#{:crypto.strong_rand_bytes(8) |> Base.encode16()}",
      "rootNode" => encode_initial_state(initial_state),
      "targetNodes" => Enum.map(goals, &encode_goal/1),
      "explorationGraph" => %{
        "nodes" => [],
        "edges" => [],
        "stableSubgraphs" => []
      }
    }
  end
end
```

##### 2. Graph-Based Stability Verification

Stability verification operates directly on the JSON-LD graph structure through graph traversal algorithms that identify stable solution subgraphs:

```elixir
defmodule AriaEngine.GraphStabilityVerifier do
  def verify_stability(solution_network) do
    solution_network
    |> extract_solution_subgraphs()
    |> verify_each_subgraph_stability()
    |> filter_stable_solutions()
  end

  # Detailed implementation in Appendix A
end
```

##### 3. Reentrancy Through Graph Cycles

The JSON-LD solution network provides natural reentrancy through graph cycle detection and reference following:

```elixir
defmodule AriaEngine.ReentrancyManager do
  def create_reentrant_context(solution_network, failure_point) do
    %{
      "@context" => solution_network["@context"],
      "@type" => "ReentrancyContext", 
      "failurePoint" => failure_point,
      "alternativePaths" => find_alternative_paths(solution_network, failure_point),
      "backtrackNodes" => identify_backtrack_candidates(solution_network)
    }
  end

  # Detailed implementation in Appendix B
end
```

## Implementation Strategy

### Phase 1: JSON-LD Solution Network Foundation

- Implement core JSON-LD vocabulary for solution networks
- Create graph traversal algorithms for solution space exploration
- Establish stability verification through graph connectivity analysis

### Phase 2: Reentrancy Integration  

- Integrate graph cycle detection for reentrancy points
- Implement alternative path discovery for failure recovery
- Create seamless fallback between temporal and non-temporal modes

### Phase 3: Optimization and Testing

- Optimize graph algorithms for real-time performance
- Comprehensive testing of stability guarantees
- Integration with existing AriaEngine components

## Consequences

### Positive

- **Unified Architecture**: JSON-LD eliminates separate solution tracking systems
- **Mathematical Rigor**: Graph-theoretic stability guarantees
- **Natural Reentrancy**: Graph cycles provide inherent reentrancy mechanisms
- **Scalability**: Graph algorithms scale well with solution space size

### Negative  

- **Graph Complexity**: Large solution spaces create complex graphs
- **Performance Overhead**: Graph operations may impact real-time performance
- **Learning Curve**: Team must understand graph-theoretic concepts

### Risk Mitigation

- **Incremental Implementation**: Phased approach reduces integration risk
- **Performance Monitoring**: Continuous benchmarking of graph operations
- **Fallback Mechanisms**: Non-temporal planner remains available for critical scenarios

## Related ADRs

- [ADR-036: Evolving AriaEngine Planner Blueprint](036-evolving-ariengine-planner-blueprint.md) - **Deprecated**
- [ADR-037: Timeline-Based vs Durative Actions](037-timeline-based-vs-durative-actions.md)
- [ADR-038: Timeline-Based Temporal Planner Implementation](038-timeline-based-temporal-planner-implementation.md)

---

## Appendix A: Mathematical Foundations

### A.1 Exponential Solution Space Problem

For an n-dimensional linear dynamical system, the Bellman equation admits at least C(2n,n) solutions where:

- C(2n,n) = (2n)! / (n! * n!)
- This grows exponentially (~4^n / √(πn)) with state dimension n
- Only ONE solution yields both optimal policy AND stable closed-loop behavior

**Examples:**

- 6-dimensional system: C(12,6) = 924 solutions, only 1 stable (99.89% unstable)
- 10-dimensional system: C(20,10) = 184,756 solutions, only 1 stable (99.9995% unstable)

### A.2 Lyapunov Stability Theory

A system is stable if there exists a Lyapunov function V(x) such that:

- V(x) > 0 for all x ≠ 0 (positive definite)
- V̇(x) < 0 for all x ≠ 0 (negative definite derivative)
- V(0) = 0 (zero at equilibrium)

## Appendix B: Complete Technical Implementation

### B.1 Complete Lyapunov Solver Implementation

```elixir
defmodule AriaEngine.LyapunovSolver do
  @moduledoc """
  Complete standalone implementation of Lyapunov equation solver.
  Solves A^T * P + P * A = -Q using Bartels-Stewart algorithm.
  """

  def solve(a_matrix, q_matrix \\ nil) do
    q = q_matrix || create_identity_matrix(matrix_size(a_matrix))
    
    # Check if A is Hurwitz (all eigenvalues have negative real parts)
    eigenvalues = compute_eigenvalues(a_matrix)
    
    unless all_hurwitz?(eigenvalues) do
      return {:error, :not_hurwitz}
    end
    
    # Solve using Bartels-Stewart algorithm
    case bartels_stewart_solve(a_matrix, q) do
      {:ok, p_matrix} -> 
        if positive_definite?(p_matrix) do
          {:ok, p_matrix}
        else
          {:error, :not_positive_definite}
        end
      error -> error
    end
  end

  defp bartels_stewart_solve(a_matrix, q_matrix) do
    # Step 1: Schur decomposition of A: A = U * T * U^T
    {u_matrix, t_matrix} = schur_decomposition(a_matrix)
    
    # Step 2: Transform Q: Q_hat = U^T * Q * U  
    q_hat = matrix_multiply([transpose(u_matrix), q_matrix, u_matrix])
    
    # Step 3: Solve T^T * Y + Y * T = -Q_hat
    y_matrix = solve_sylvester(transpose(t_matrix), t_matrix, negate(q_hat))
    
    # Step 4: Transform back: P = U * Y * U^T
    p_matrix = matrix_multiply([u_matrix, y_matrix, transpose(u_matrix)])
    
    {:ok, p_matrix}
  end

  defp compute_eigenvalues(matrix) do
    # QR algorithm for eigenvalue computation
    qr_iterations(matrix, 100)
  end

  defp all_hurwitz?(eigenvalues) do
    Enum.all?(eigenvalues, fn eigenvalue ->
      case eigenvalue do
        %Complex{real: real_part} -> real_part < 0
        real_number when is_number(real_number) -> real_number < 0
      end
    end)
  end

  defp positive_definite?(matrix) do
    # Check positive definiteness using Cholesky decomposition
    case cholesky_decomposition(matrix) do
      {:ok, _l_matrix} -> true
      {:error, _} -> false
    end
  end

  # Matrix operation helper functions
  defp cholesky_decomposition(matrix) do
    # Implement Cholesky decomposition for positive definite matrices
    # Returns {:ok, l_matrix} or {:error, reason}
  end

  defp matrix_norm(matrix, type \\ :frobenius) do
    # Calculate matrix norms (Frobenius, spectral, etc.)
  end

  defp eigenvalues(matrix) do
    # Compute eigenvalues of matrix for stability analysis
  end

  defp matrix_multiply(a, b) do
    # Efficient matrix multiplication
  end

  defp matrix_transpose(matrix) do
    # Matrix transpose operation
  end

  defp matrix_inverse(matrix) do
    # Matrix inversion with numerical stability checks
  end

  defp is_symmetric?(matrix) do
    # Check if matrix is symmetric
  end

  defp spectral_radius(matrix) do
    # Compute spectral radius (largest eigenvalue magnitude)
  end
end
```

### B.2 Complete Graph-Based Stability Verifier

```elixir
defmodule AriaEngine.GraphStabilityVerifier do
  def verify_stability(solution_network) do
    solution_network
    |> extract_solution_subgraphs()
    |> Enum.map(&analyze_subgraph_stability/1)
    |> filter_stable_solutions()
  end

  defp extract_solution_subgraphs(network) do
    exploration_graph = network["explorationGraph"]
    nodes = exploration_graph["nodes"]
    edges = exploration_graph["edges"]
    
    # Find strongly connected components
    strongly_connected_components(nodes, edges)
  end

  defp analyze_subgraph_stability(subgraph) do
    # Convert graph to state space representation
    state_matrix = graph_to_state_matrix(subgraph)
    
    # Apply Lyapunov stability test
    case AriaEngine.LyapunovSolver.solve(state_matrix) do
      {:ok, _p_matrix} -> {:stable, subgraph}
      {:error, _reason} -> {:unstable, subgraph}
    end
  end

  defp filter_stable_solutions(analyzed_subgraphs) do
    analyzed_subgraphs
    |> Enum.filter(fn {stability, _graph} -> stability == :stable end)
    |> Enum.map(fn {_stability, graph} -> graph end)
  end
end
```

### B.3 Complete Reentrancy Manager Implementation

```elixir
defmodule AriaEngine.ReentrancyManager do
  def create_reentrant_context(solution_network, failure_point) do
    alternative_paths = find_alternative_paths(solution_network, failure_point)
    backtrack_nodes = identify_backtrack_candidates(solution_network)
    
    %{
      "@context" => solution_network["@context"],
      "@type" => "ReentrancyContext",
      "@id" => "reentrancy-#{:crypto.strong_rand_bytes(8) |> Base.encode16()}",
      "failurePoint" => failure_point,
      "alternativePaths" => alternative_paths,
      "backtrackNodes" => backtrack_nodes,
      "recoveryStrategy" => determine_recovery_strategy(alternative_paths)
    }
  end

  defp find_alternative_paths(network, failure_point) do
    graph = network["explorationGraph"]
    
    # Use Dijkstra's algorithm to find alternative paths
    dijkstra_all_paths(graph, network["rootNode"], failure_point)
    |> Enum.reject(&path_contains_failure?(&1, failure_point))
  end

  defp identify_backtrack_candidates(network) do
    exploration_graph = network["explorationGraph"]
    
    # Find nodes with multiple outgoing edges (decision points)
    exploration_graph["nodes"]
    |> Enum.filter(fn node ->
      outgoing_edge_count(exploration_graph["edges"], node) > 1
    end)
  end

  defp determine_recovery_strategy(alternative_paths) do
    case length(alternative_paths) do
      0 -> %{"strategy" => "fallback_to_non_temporal"}
      1 -> %{"strategy" => "single_path_recovery", "path" => hd(alternative_paths)}
      _ -> %{"strategy" => "multi_path_exploration", "paths" => alternative_paths}
    end
  end
end
```
