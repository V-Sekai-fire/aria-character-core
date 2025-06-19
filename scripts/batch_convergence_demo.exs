#!/usr/bin/env elixir

# Batch Convergence Processing Demo
# This script demonstrates the new batch processing capabilities for multiple timelines

alias AriaEngine.Convergence

IO.puts("=== Batch Convergence Processing Demo ===\n")

# Demo 1: Batch STN solving for multiple NPC timelines
IO.puts("1. Batch STN Solving for Multiple NPC Timelines")
IO.puts("=" |> String.duplicate(50))

npc_timelines = [
  %{
    id: "guard_patrol",
    constraints: %{
      {{"start_patrol", "checkpoint_1"}, {5, 10}},
      {{"checkpoint_1", "checkpoint_2"}, {8, 15}},
      {{"checkpoint_2", "end_patrol"}, {5, 12}}
    }
  },
  %{
    id: "merchant_routine", 
    constraints: %{
      {{"open_shop", "first_customer"}, {2, 5}},
      {{"first_customer", "lunch_break"}, {60, 120}},
      {{"lunch_break", "close_shop"}, {30, 45}}
    }
  },
  %{
    id: "blacksmith_work",
    constraints: %{
      {{"heat_forge", "start_work"}, {10, 15}},
      {{"start_work", "finish_item"}, {45, 90}},
      {{"finish_item", "cool_down"}, {20, 30}}
    }
  },
  %{
    id: "tavern_keeper",
    constraints: %{
      {{"prepare_drinks", "evening_rush"}, {30, 60}},
      {{"evening_rush", "last_call"}, {180, 240}}
    }
  }
]

IO.puts("Processing #{length(npc_timelines)} NPC timelines...")

# Benchmark different approaches
{time_nx, result_nx} = :timer.tc(fn ->
  Convergence.solve_stn_batch(npc_timelines, approach: :nx, use_pytorch: false, batch_size: 4)
end)

{time_flow, result_flow} = :timer.tc(fn ->
  Convergence.solve_stn_batch(npc_timelines, approach: :flow, batch_size: 2)
end)

IO.puts("\nResults:")
IO.puts("Nx approach: #{time_nx / 1000} ms - #{result_nx.successful_count}/#{result_nx.total_count} successful")
IO.puts("Flow approach: #{time_flow / 1000} ms - #{result_flow.successful_count}/#{result_flow.total_count} successful")

# Demo 2: Batch activity scheduling for multiple projects
IO.puts("\n\n2. Batch Activity Scheduling for Multiple Projects")
IO.puts("=" |> String.duplicate(50))

project_activities = [
  %{
    id: "game_development",
    activities: [
      %{id: "design", duration: 10, resources: ["designer"]},
      %{id: "programming", duration: 20, resources: ["programmer"], dependencies: ["design"]},
      %{id: "art", duration: 15, resources: ["artist"], dependencies: ["design"]},
      %{id: "testing", duration: 8, resources: ["tester"], dependencies: ["programming", "art"]},
      %{id: "release", duration: 2, resources: ["manager"], dependencies: ["testing"]}
    ]
  },
  %{
    id: "website_redesign",
    activities: [
      %{id: "wireframes", duration: 5, resources: ["designer"]},
      %{id: "frontend", duration: 12, resources: ["frontend_dev"], dependencies: ["wireframes"]},
      %{id: "backend", duration: 8, resources: ["backend_dev"]},
      %{id: "integration", duration: 4, resources: ["fullstack_dev"], dependencies: ["frontend", "backend"]},
      %{id: "deployment", duration: 2, resources: ["devops"], dependencies: ["integration"]}
    ]
  },
  %{
    id: "mobile_app",
    activities: [
      %{id: "ui_design", duration: 8, resources: ["ui_designer"]},
      %{id: "ios_dev", duration: 15, resources: ["ios_developer"], dependencies: ["ui_design"]},
      %{id: "android_dev", duration: 15, resources: ["android_developer"], dependencies: ["ui_design"]},
      %{id: "testing", duration: 6, resources: ["qa_engineer"], dependencies: ["ios_dev", "android_dev"]},
      %{id: "store_submission", duration: 3, resources: ["product_manager"], dependencies: ["testing"]}
    ]
  }
]

IO.puts("Processing #{length(project_activities)} project activity sets...")

{time_activities_nx, result_activities_nx} = :timer.tc(fn ->
  Convergence.solve_activities_batch(project_activities, approach: :nx, use_pytorch: false, batch_size: 3)
end)

{time_activities_flow, result_activities_flow} = :timer.tc(fn ->
  Convergence.solve_activities_batch(project_activities, approach: :flow, batch_size: 2)
end)

IO.puts("\nResults:")
IO.puts("Nx approach: #{time_activities_nx / 1000} ms - #{result_activities_nx.successful_count}/#{result_activities_nx.total_count} successful")
IO.puts("Flow approach: #{time_activities_flow / 1000} ms - #{result_activities_flow.successful_count}/#{result_activities_flow.total_count} successful")

# Demo 3: Performance comparison with single vs batch processing
IO.puts("\n\n3. Performance Comparison: Single vs Batch Processing")
IO.puts("=" |> String.duplicate(50))

# Single processing
{time_single, _} = :timer.tc(fn ->
  Enum.each(npc_timelines, fn timeline ->
    Convergence.solve_stn(timeline.constraints, approach: :nx, use_pytorch: false)
  end)
end)

# Batch processing
{time_batch, _} = :timer.tc(fn ->
  Convergence.solve_stn_batch(npc_timelines, approach: :nx, use_pytorch: false, batch_size: 4)
end)

speedup = time_single / time_batch
IO.puts("Single processing: #{time_single / 1000} ms")
IO.puts("Batch processing: #{time_batch / 1000} ms")
IO.puts("Speedup: #{Float.round(speedup, 2)}x faster with batch processing")

# Demo 4: System information
IO.puts("\n\n4. System Information")
IO.puts("=" |> String.duplicate(50))

info = Convergence.info()
IO.puts("PyTorch available: #{info.system.pytorch_available}")
IO.puts("Architecture: #{info.system.architecture}")
IO.puts("Recommended approach: #{info.system.recommended_approach}")

IO.puts("\nAvailable approaches:")
Enum.each(info.approaches, fn {name, details} ->
  IO.puts("  #{name}: #{details.description}")
  IO.puts("    Backend: #{details.backend}")
  IO.puts("    Strengths: #{Enum.join(details.strengths, ", ")}")
end)

IO.puts("\n=== Demo Complete ===")
IO.puts("The batch processing system successfully handles multiple timelines and activity sets")
IO.puts("with improved performance through vectorized operations and parallel processing.")
