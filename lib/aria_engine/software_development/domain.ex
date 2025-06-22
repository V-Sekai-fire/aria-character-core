defmodule AriaEngine.SoftwareDevelopment.Domain do
  @moduledoc """
  Represents the domain of software development for planning purposes.
  This domain includes actions for implementing, testing, and documenting
  software modules, allowing the AriaEngine to plan its own development.
  """
  alias AriaEngine.Domain
  alias AriaEngine.StateV2

  def actions() do
    [
      :implement_module,
      :integrate_modules,
      :test_implementation,
      :document_module,
      :refactor_module,
      :verify_typespecs
    ]
  end

  def methods() do
    [
      "develop_module",
      "develop_system",
      "achieve_goal"
    ]
  end

  def build() do
    Domain.new("software_development")
    |> Domain.add_action(:implement_module, &implement_module/2, %{duration: "PT8H"})
    |> Domain.add_action(:integrate_modules, &integrate_modules/2, %{duration: "PT16H"})
    |> Domain.add_action(:test_implementation, &test_implementation/2, %{duration: "PT4H"})
    |> Domain.add_action(:document_module, &document_module/2, %{duration: "PT2H"})
    |> Domain.add_action(:refactor_module, &refactor_module/2, %{duration: "PT8H"})
    |> Domain.add_action(:verify_typespecs, &verify_typespecs/2, %{duration: "PT1H"})
    |> Domain.add_task_method("develop_module", &develop_module/2)
    |> Domain.add_task_method("develop_system", &develop_system/2)
    |> Domain.add_unigoal_method("status", &achieve_status_unigoal/2)
    |> Domain.add_unigoal_method("typespecs", &achieve_typespecs_unigoal/2)
  end

  def implement_module(state, [module_name]) do
    # Check current status - if already completed or beyond, don't re-implement
    current_status = State.get_fact(state, module_name, "status")

    if current_status in ["completed", "tested", "documented"] do
      state  # No change needed
    else
      # Check dependencies
      dependencies =
        state
        |> StateV2.to_triples()
        |> Enum.filter(fn {s, p, _o} -> s == module_name and p == "depends_on" end)
        |> Enum.map(fn {_s, _p, o} -> o end)

      all_deps_met = Enum.all?(dependencies, fn dep ->
        State.get_fact(state, dep, "status") == "documented"
      end)

      if all_deps_met do
        new_state = State.set_fact(state, module_name, "status", "completed")
        new_state
      else
        false
      end
    end
  end

  def integrate_modules(state, [modules]) do
    # For now, just marks the integration as done.
    # A more complex implementation could check for conflicts.
    State.set_fact(state, {:integration, modules}, "status", "completed")
  end

  def test_implementation(state, [module_name]) do
    current_status = State.get_fact(state, module_name, "status")

    if current_status == "completed" do
      new_state = State.set_fact(state, module_name, "status", "tested")
      new_state
    else
      false
    end
  end

  def document_module(state, [module_name]) do
    if State.get_fact(state, module_name, "status") == "tested" do
      State.set_fact(state, module_name, "status", "documented")
    else
      false
    end
  end

  def refactor_module(state, [module_name]) do
    # Assumes refactoring happens after initial implementation
    if State.get_fact(state, module_name, "status") in ["completed", "tested", "documented"] do
      State.set_fact(state, module_name, "status", "completed") # Needs re-testing and re-documenting
    else
      false
    end
  end

  def verify_typespecs(state, [module_name]) do
    # For now, this is a conceptual action.
    # In a real scenario, it might involve static analysis.
    if State.get_fact(state, module_name, "status") == "documented" do
      State.set_fact(state, module_name, "typespecs", "verified")
    else
      false
    end
  end

  # --- Methods ---

  # Unigoal methods following GTPyhop predicate-based pattern
  def achieve_status_unigoal(state, [subject, target_status]) do
    current_status = State.get_fact(state, subject, "status")

    if current_status == target_status do
      []  # Goal already achieved
    else
      case target_status do
        "completed" -> [{"develop_module", [subject]}]
        "tested" ->
          if current_status == "completed" do
            [{:test_implementation, [subject]}]
          else
            [{"develop_module", [subject]}]
          end
        "documented" ->
          case current_status do
            "tested" -> [{:document_module, [subject]}]
            "completed" -> [{:test_implementation, [subject]}, {:document_module, [subject]}]
            _ -> [{"develop_module", [subject]}]
          end
        _ -> false  # Unknown target status
      end
    end
  end

  def achieve_typespecs_unigoal(state, [subject, "verified"]) do
    current_typespecs = State.get_fact(state, subject, "typespecs")

    if current_typespecs == "verified" do
      []  # Goal already achieved
    else
      # Typespecs can only be verified after documentation
      current_status = State.get_fact(state, subject, "status")
      if current_status == "documented" do
        [{:verify_typespecs, [subject]}]
      else
        # Need to achieve documented status first
        [{"achieve_status_unigoal", [subject, "documented"]}, {:verify_typespecs, [subject]}]
      end
    end
  end

  def achieve_typespecs_unigoal(_state, [_subject, _target]) do
    false  # Only "verified" is supported for typespecs
  end

  # Legacy method for backward compatibility
  def achieve_goal(state, {subject, "status", "documented"}) do
    result = [
      [{"develop_module", [subject]}]
    ]
    result
  end

  def develop_module(state, module_name) do
    # Handle both single module name and list of module names
    actual_module_name = case module_name do
      [name] when is_binary(name) -> name
      name when is_binary(name) -> name
      _ -> module_name
    end

    result = [
      [
        {:implement_module, [actual_module_name]},
        {:test_implementation, [actual_module_name]},
        {:document_module, [actual_module_name]},
        {:verify_typespecs, [actual_module_name]}
      ]
    ]
    result
  end

  def develop_system(state, system_name) do
    modules = State.get_subjects_with_fact(state, "type", "module")

    tasks = Enum.map(modules, fn module_name ->
      {"develop_module", [module_name]}
    end)
    result = [tasks ++ [{:integrate_modules, [modules]}]]
    result
  end
end
