defmodule AriaEngine.CharacterGenerator.PlanTestHelper do
  @moduledoc """
  Helper for testing plan-based character generation and backtracking.
  
  Updated to use the new hierarchical planning architecture.
  """
  alias AriaEngine
  alias AriaEngine.CharacterGenerator.{Generator, Domain, Plans}

  @doc """
  Runs the full plan for character generation with given attributes (or preset).
  
  ## Parameters
  - `attrs_or_opts`: Map of attributes or options including :preset
  
  ## Returns
  - `{:ok, plan}` on success
  - `{:error, reason}` on failure
  """
  def plan_character_with(attrs_or_opts) do
    try do
      domain = Domain.build_demo_character_domain()
      char_id = UUID.uuid4(:default)
      preset = Map.get(attrs_or_opts, :preset) || Map.get(attrs_or_opts, "preset")
      
      # Create TODO list using the new Plans module
      todos = Plans.demo_character_generation_plan(char_id, preset)
      
      state = AriaEngine.create_state()
      
      # Set any provided attributes in the state
      attrs = if is_map(attrs_or_opts), do: attrs_or_opts, else: %{}
      state = Enum.reduce(attrs, state, fn {k, v}, acc ->
        case k do
          :preset -> acc  # Skip preset, it's handled in the plan
          "preset" -> acc  # Skip preset, it's handled in the plan
          _ -> AriaEngine.set_fact(acc, "character:" <> to_string(k), char_id, v)
        end
      end)
      
      result = AriaEngine.plan(domain, state, todos, verbose: 0)
      case result do
        {:ok, plan} ->
          case AriaEngine.execute_plan(domain, state, plan) do
            {:ok, _final_state} -> {:ok, plan}
            {:error, reason} -> {:error, reason}
            {:fail, reason} -> {:error, reason}
          end
        {:error, reason} -> {:error, reason}
        {:fail, reason} -> {:error, reason}
        new_todos when is_list(new_todos) ->
          # Handle case where planner returns new todos
          plan_character_with(attrs_or_opts)
        other ->
          {:error, "Unexpected planner result: #{inspect(other)}"}
      end
    rescue
      e in CaseClauseError -> {:error, Exception.message(e)}
      e in RuntimeError -> {:error, Exception.message(e)}
    end
  end

  @doc """
  Test various planning workflows for character generation.
  
  ## Parameters
  - `workflow`: The workflow to test (:basic, :comprehensive, :validation, etc.)
  - `opts`: Options for the workflow
  
  ## Returns
  - `{:ok, result}` on success
  - `{:error, reason}` on failure
  """
  def test_workflow(workflow, opts \\ %{}) do
    try do
      char_id = UUID.uuid4(:default)
      
      domain = case workflow do
        :validation -> Domain.build_validation_domain()
        :preset -> Domain.build_preset_domain()
        _ -> Domain.build_character_generation_domain()
      end
      
      state = AriaEngine.create_state()
      
      # Get appropriate plan for workflow
      todos = case workflow do
        :basic -> Plans.basic_character_generation_plan(char_id, opts)
        :comprehensive -> Plans.comprehensive_character_generation_plan(char_id, opts, [])
        :validation -> Plans.validation_only_plan(char_id)
        :preset -> Plans.preset_application_plan(char_id, Map.get(opts, :preset), opts)
        :batch -> Plans.batch_generation_plan(Map.get(opts, :count, 1))
        _ -> Plans.basic_character_generation_plan(char_id, opts)
      end
      
      case AriaEngine.plan(domain, state, todos, verbose: 0) do
        {:ok, plan} ->
          case AriaEngine.execute_plan(domain, state, plan) do
            {:ok, final_state} -> 
              {:ok, %{plan: plan, state: final_state, character_id: char_id}}
            error -> 
              {:error, "Execution failed: #{inspect(error)}"}
          end
        error -> 
          {:error, "Planning failed: #{inspect(error)}"}
      end
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  @doc """
  Test backtracking with conflicting constraints.
  
  ## Parameters
  - `conflicting_attrs`: Map of conflicting attributes to test
  
  ## Returns
  - `{:ok, resolution}` if conflicts were resolved
  - `{:error, reason}` if resolution failed
  """
  def test_backtracking(conflicting_attrs \\ %{}) do
    try do
      domain = Domain.build_validation_domain()
      char_id = UUID.uuid4(:default)
      state = AriaEngine.create_state()
      
      # Set conflicting attributes
      state = Enum.reduce(conflicting_attrs, state, fn {k, v}, acc ->
        AriaEngine.set_fact(acc, "character:" <> to_string(k), char_id, v)
      end)
      
      # Create a plan that will require backtracking
      todos = [
        {"validate_attributes", [char_id]},
        {"resolve_conflicts", [char_id]},
        {"validate_attributes", [char_id]}
      ]
      
      case AriaEngine.plan(domain, state, todos, verbose: 1) do
        {:ok, plan} ->
          case AriaEngine.execute_plan(domain, state, plan) do
            {:ok, final_state} ->
              {:ok, %{
                plan: plan, 
                final_state: final_state,
                character_id: char_id,
                backtracking_occurred: length(plan) > length(todos)
              }}
            error ->
              {:error, "Backtracking execution failed: #{inspect(error)}"}
          end
        error ->
          {:error, "Backtracking planning failed: #{inspect(error)}"}
      end
    rescue
      e -> {:error, Exception.message(e)}
    end
  end
end
