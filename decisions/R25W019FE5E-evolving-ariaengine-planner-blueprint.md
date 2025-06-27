# R25W019FE5E: Evolving AriaEngine Planner Blueprint

<!-- @adr_serial R25W019FE5E -->

## Status

**Deprecated** - Superseded by R25W0210AA3: Timeline-Based Temporal Planner Implementation Plan

## Date

2025-06-14

## Deprecation Note

This ADR is deprecated in favor of [R25W0210AA3: Timeline-Based Temporal Planner Implementation](038-timeline-based-temporal-planner-implementation.md) which provides a superior timeline-based implementation plan.

The durative action approach outlined in this ADR has been superseded by timeline-based temporal planning which offers:

- Better computational performance (O(V^t) vs O(A^n))
- More natural domain modeling for continuous resources
- Superior scalability and parallel processing capabilities
- Enhanced expressiveness for complex temporal scenarios

**This ADR is retained for historical reference only. All future development should follow R25W0210AA3.**

---

## Original ADR Content (Deprecated)

### Title: Evolving AriaEngine Planner

#### Original Date

2025-06-14

### Context

The AriaEngine requires evolution from its current non-temporal Goal-Task-Network (GTN) planner into a sophisticated, real-time temporal planner. This ADR documents the final, recommended architecture and phased implementation plan for this conversion, incorporating all design decisions made regarding data models, component architecture, and core algorithms.

## Decision

### Guiding Principles (The Core Philosophy)

Our design is guided by four core principles to ensure the final system is powerful, robust, and practical for a real-time application.

1. **Data as a First-Class Citizen (Data Model First):** We will represent all plans—both logical and scheduled—as a rich **dependency graph** using JSON-LD documents that can be processed with RDF semantics. This will be adopted from the very beginning of the conversion.

2. **Encapsulated Two-Tier Architecture:** The final planner will be a single, easy-to-use module (`AriaEngine.TemporalPlanner`). Internally, however, it will be composed of two distinct, decoupled components: a strategic **"General"** that determines _what_ to do, and a scheduling **"Lieutenant"** that determines _when_ to do it.

3. **High-Precision Tick-Based Time:** The planner will operate on a discrete, **tick-based time model** with a high resolution (e.g., **1ms per tick**). This provides a pragmatic balance of realism and performance, making the problem finite and computationally tractable.

4. **Provably Optimal Scheduling (Critical Path Method):** The "Lieutenant" will be implemented using the **Critical Path Method (CPM)**. This guarantees that the final schedules are the most time-efficient possible and provides invaluable "slack" information for dynamic replanning.

### The Final Two-Tier Architecture

The planner will be implemented as a single, public-facing Elixir module that encapsulates two private, specialized components.

#### A. The Public Facade: `TemporalPlanner.find_plan/2`

- **Responsibility:** To be the simple, clean entry point for the entire system.
- **Input:** A `goal` (including a `deadline_ticks`) and the current `state`.
- **Process:** It orchestrates the two-tiered process: first calling the strategic planner, then passing its output to the scheduler.
- **Output:** The final, enriched `RDF.Graph` of the plan, which can be serialized to a JSON-LD string.

#### B. The "General": `gtn_strategic_planner`

- **Responsibility:** High-level, logical, hierarchical planning. It answers the question: "What actions are needed and what are their logical dependencies?" **It has zero knowledge of time, schedules, or deadlines.**
- **Algorithm:** Your existing Goal-Task-Network (GTN) backtracking search logic.
- **Output:** A **partially-ordered `RDF.Graph`**. Each action is a node with properties like `agent` and `duration_ticks`. Dependencies are represented as `dependsOn` edges connecting the action nodes.

#### C. The "Lieutenant": `critical_path_scheduler`

- **Responsibility:** To take the logical "recipe" from the General and create the most efficient possible schedule.
- **Algorithm:** The **Critical Path Method (CPM)**.

  1. **Topological Sort:** Perform a topological sort on the action dependency graph using a native Elixir implementation.
  2. **Forward Pass:** Iterate through the sorted actions to calculate the Earliest Start Tick (EST) and Earliest Finish Tick (EFT) for each one, determining the plan's optimal completion time (makespan).
  3. **Backward Pass:** Iterate in reverse to calculate the Latest Start Tick (LST), Latest Finish Tick (LFT), and most importantly, the **"slack"** for each action (`slack = LST - EST`).

- **Output:** The same `RDF.Graph`, but now **enriched** with new triples for each action node: `startTick`, `endTick`, and `slack`.

### The Phased Implementation Roadmap

This is the recommended, step-by-step path for the conversion.

#### Phase 1: Refactor the Existing Planner to the New Data Model

Upgrade your current non-temporal planner to speak the language of RDF graphs _before_ adding any temporal logic.

1. **Define a Vocabulary:** Create a centralized module for your JSON-LD `@context`, defining terms like `vocab:MoveAction`, `vocab:dependsOn`, `vocab:isPerformedBy`, etc.

2. **Add RDF Libraries:** Add `{:rdf, "~> 1.1"}` and `{:jsonld, "~> 1.0"}` to your `mix.exs` dependencies.

3. **Modify GTN Planner Output:** Change the core logic of your existing planner to construct and return an in-memory `RDF.Graph` object representing the logical plan with `dependsOn` edges.

**✅ Milestone:** Your planner's logic is unchanged, but its "thoughts" are now represented in a formal, robust, and extensible JSON-LD format that can be processed with RDF semantics when needed.

#### Phase 2: Enrich the Data Model with Temporal Concepts

Teach the data model the raw materials needed for scheduling.

1. **Update Vocabulary:** Add `vocab:durationTicks`, `vocab:deadlineTicks`, `vocab:startTick`, `vocab:endTick`, and `vocab:slack` to your vocabulary/context file.

2. **Add Durations to the Document:** Modify the `gtn_strategic_planner`. When it creates an action in the JSON-LD document, it must also add a `vocab:durationTicks` property.

3. **Update Goal Input:** The input to your planner must now be a structure that includes the `deadline_ticks`.

**✅ Milestone:** Your planner now produces a complete, but unscheduled, temporal problem description in JSON-LD format.

#### Phase 3: Implement the Critical Path Scheduler

Build the new temporal engine as a private component.

1. **Implement Native Topological Sorter:** Create the `TopologicalSorter` Elixir module. This module will be used by the scheduler to correctly order actions based on their dependencies. It takes a list of items and a custom comparator function, dynamically builds the dependency graph, and performs a true topological sort using Kahn's algorithm.

```elixir
defmodule TopologicalSorter do
  @doc """
  Sorts a list of items based on a custom comparator function that defines dependencies.
  The comparator function should take two items (a, b) and return:
  - `:lt` if `a` must come before `b`
  - `:gt` if `b` must come before `a`
  - `:eq` or any other value if there is no dependency
  """
  def sort(items, comparator) do
    items
    |> build_graph(comparator)
    |> do_kahn_sort()
  end

  # --- Phase 1: Build the Dependency Graph ---
  defp build_graph(items, comparator) do
    unique_items = Enum.uniq(items)
    pairs = for a <- unique_items, b <- unique_items, a != b, do: {a, b}
    initial_graph = Map.from_keys(unique_items, MapSet.new())

    Enum.reduce(pairs, initial_graph, fn {a, b}, graph ->
      case comparator.(a, b) do
        :lt -> Map.update!(graph, a, &MapSet.put(&1, b))
        :gt -> Map.update!(graph, b, &MapSet.put(&1, a))
        _ -> graph
      end
    end)
  end

  # --- Phase 2: Perform Kahn's Algorithm for Topological Sort ---
  defp do_kahn_sort(graph) do
    in_degrees = Enum.reduce(graph, Map.from_keys(Map.keys(graph), 0), fn {_, adjs}, acc ->
      Enum.reduce(adjs, acc, fn adj, inner_acc -> Map.update!(inner_acc, adj, &(&1 + 1)) end)
    end)

    queue = Enum.filter(in_degrees, fn {_, degree} -> degree == 0 end) |> Enum.map(&elem(&1, 0))

    process_queue(queue, [], in_degrees, graph)
  end

  defp process_queue(queue, sorted, degrees, graph) do
    case queue do
      [] ->
        if Map.values(degrees) |> Enum.any?(&(&1 > 0)) do
          {:error, :cycle_detected, Enum.reverse(sorted)}
        else
          {:ok, Enum.reverse(sorted)}
        end
      [node | rest_of_queue] ->
        neighbors = Map.get(graph, node, MapSet.new())
        new_degrees = Enum.reduce(neighbors, degrees, &Map.update!(&2, &1, fn d -> d - 1 end))
        newly_ready = Enum.filter(new_degrees, fn {n, d} -> d == 0 && Enum.member?(neighbors, n) end) |> Enum.map(&elem(&1, 0))
        process_queue(rest_of_queue ++ newly_ready, [node | sorted], new_degrees, graph)
    end
  end
end
```

2. **Implement the Two-Pass CPM Algorithm:** Create the `critical_path_scheduler` function. It will take the JSON-LD document and `deadline_ticks` as input.

   - **Internal Conversion & Sort:** Convert the JSON-LD document into a simple list of actions and use the `TopologicalSorter` to get the correct processing order.
   - **Pass 1 (Forward):** Iterate through the sorted actions to calculate the Earliest Start Tick (EST) and Earliest Finish Tick (EFT) for every action. Determine the final plan makespan.
   - **Pass 2 (Backward):** Iterate through the actions in reverse sorted order to calculate the Latest Start Tick (LST), Latest Finish Tick (LFT), and the `slack` for every action.
   - **Enrich the Document:** For each action, add the calculated `startTick` (using its EST), `endTick`, and `slack` values back into the original JSON-LD document.

**✅ Milestone:** You have a standalone component that can take an unscheduled plan document and produce a perfectly optimal, fully scheduled version.

#### Phase 4: Integrate and Finalize the Encapsulated Planner

Assemble all the pieces into the final, cohesive module.

1. **Create the `AriaEngine.TemporalPlanner` Module:** This is the new public API.

2. **Place Components Inside:** Move your refactored `gtn_strategic_planner` and your new `critical_path_scheduler` inside this module as private functions.

3. **Implement the Public `find_plan/2` Function:** This orchestrator will call the strategic planner, then the scheduler, check the final makespan against the deadline, and return the final enriched JSON-LD document.

**✅ Final Milestone:** You have a fully converted, end-to-end temporal planner that is robust, produces optimal schedules, and hides its internal complexity behind a simple, clean interface.

## Consequences

### Positive

- **Clear Implementation Path:** The phased approach provides a concrete roadmap from current state to final temporal planner
- **Provably Optimal Scheduling:** CPM guarantees optimal schedules and provides valuable slack information
- **Clean Architecture:** Two-tier design separates concerns while maintaining simple public API
- **Robust Data Model:** JSON-LD provides formal, extensible representation of plans with RDF processing capabilities when needed
- **Integer Time Ticks:** Discrete time model makes the problem computationally tractable

### Negative

- **Implementation Complexity:** Requires significant refactoring of existing planner
- **New Dependencies:** Adds RDF and JSON-LD libraries to the project
- **Learning Curve:** Team needs to understand CPM algorithms and RDF concepts

### Neutral

- **Performance Implications:** Need to measure impact of RDF graph operations vs current data structures
- **Backward Compatibility:** May require migration path for existing planner users

## Related ADRs

- [R25W017DEAF: Definitive Temporal Planner Architecture](034-definitive-temporal-planner-architecture.md)
- [R25W0183367: Canonical Temporal Backtracking Problem](035-canonical-temporal-backtracking-problem.md)

## Implementation Notes

This blueprint should be implemented in conjunction with the canonical temporal backtracking problem defined in R25W0183367, ensuring that the integer time tick system is consistently applied throughout the implementation.

The TopologicalSorter implementation provided serves as a reference for the critical path scheduling component, emphasizing the importance of proper dependency ordering in temporal planning.
