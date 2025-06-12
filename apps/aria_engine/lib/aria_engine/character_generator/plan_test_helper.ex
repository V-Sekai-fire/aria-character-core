defmodule AriaEngine.CharacterGenerator.PlanTestHelper do
  @moduledoc """
  Helper for testing plan-based character generation and backtracking.
  """
  alias AriaEngine
  alias AriaEngine.CharacterGenerator.Generator

  # Runs the full plan for character generation with given attributes (or preset)
  # Returns {:ok, plan} or {:error, reason}
  def plan_character_with(attrs_or_opts) do
    try do
      # Build the domain and initial state for planning
      domain = AriaEngine.CharacterGenerator.Domain.build_demo_character_domain()
      char_id = UUID.uuid4(:default)
      preset = Map.get(attrs_or_opts, :preset) || Map.get(attrs_or_opts, "preset")
      # Compose initial TODOs for the planner
      todos = [
        {"generate_character_with_constraints", %{char_id: char_id, preset: preset}},
        {"validate_character_coherence", %{char_id: char_id}},
        {"generate_character_prompt", %{char_id: char_id}}
      ]
      state = AriaEngine.create_state()
      # Optionally inject custom attributes as facts
      attrs = if is_map(attrs_or_opts), do: attrs_or_opts, else: %{}
      state = Enum.reduce(attrs, state, fn {k, v}, acc ->
        AriaEngine.set_fact(acc, "character:" <> k, char_id, v)
      end)
      # Run the planner
      result = AriaEngine.plan(domain, state, todos, verbose: 0)
      case result do
        {:ok, plan} ->
          case AriaEngine.execute_plan(domain, state, plan) do
            {:ok, _final_state} -> {:ok, plan}
            {:error, reason} -> {:error, reason}
            {:fail, reason} -> {:error, reason} # Should not happen if planner is correct
          end
        {:error, reason} -> {:error, reason}
        {:fail, reason} -> {:error, reason} # Should not happen if planner is correct
      end
    rescue
      e in CaseClauseError -> {:error, Exception.message(e)}
      e in RuntimeError -> {:error, Exception.message(e)}
    end
  end
end
