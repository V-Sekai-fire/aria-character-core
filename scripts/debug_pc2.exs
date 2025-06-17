defmodule PC2Debug do
  alias AriaEngine.Timeline.STN
  alias AriaEngine.Timeline.STN.PC2

  @moduledoc """
  Debug script for AriaEngine.Timeline.STN.PC2 module.
  Usage: mix run scripts/debug_pc2.exs
  """

  def run do
    IO.puts("=== Running PC2 Debug Scenarios ===")

    # Scenario 1: Simple Consistent STN
    IO.puts("\n--- Scenario 1: Simple Consistent STN ---")
    stn1 = %STN{
      time_points: MapSet.new(["A", "B", "C"]),
      constraints: %{
        {"A", "B"} => {1, 2},
        {"B", "C"} => {1, 2},
        {"A", "C"} => {2, 4}
      }
    }
    test_scenario(stn1, "Initial STN 1")

    # Scenario 2: Inconsistent STN (A->B (1,2), B->A (3,4))
    IO.puts("\n--- Scenario 2: Inconsistent STN ---")
    stn2 = %STN{
      time_points: MapSet.new(["A", "B"]),
      constraints: %{
        {"A", "B"} => {1, 1},
        {"B", "A"} => {1, 1}
      }
    }
    test_scenario(stn2, "Initial STN 2")

    # Scenario 3: More complex path consistency
    IO.puts("\n--- Scenario 3: Complex Path Consistency ---")
    stn3 = %STN{
      time_points: MapSet.new(["A", "B", "C", "D"]),
      constraints: %{
        {"A", "B"} => {1, 1},
        {"B", "C"} => {1, 1},
        {"C", "D"} => {1, 1},
        {"A", "D"} => {5, 5} # This should make it inconsistent or tighten other constraints
      }
    }
    test_scenario(stn3, "Initial STN 3")

    # Scenario 4: Two-Point Contradictory Inconsistency (from stn_inconsistency_test.exs)
    IO.puts("\n--- Scenario 4: Two-Point Contradictory Inconsistency ---")
    stn4 = %STN{
      time_points: MapSet.new(["A", "B"]),
      constraints: %{
        {"A", "B"} => {10, 20},
        {"B", "A"} => {5, 15}
      }
    }
    test_scenario(stn4, "Initial STN 4")
  end

  defp test_scenario(stn, description) do
    IO.puts("#{description}:")
    IO.inspect(stn, pretty: true, label: "Input STN")

    # Apply PC2
    updated_stn = PC2.apply_pc2(stn)

    IO.inspect(updated_stn, pretty: true, label: "Output STN")
    IO.puts("Consistent: #{updated_stn.consistent}")
  end
end

PC2Debug.run()
