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
    |> Domain.add_unigoal_method("status", &achieve_goal/2)
  end

  def implement_module(state, [module_name]) do
    require Logger
    Logger.error("IMPLEMENT_MODULE called with module_name: #{inspect(module_name)}")
    Logger.error("IMPLEMENT_MODULE state: #{inspect(StateV2.to_triples(state))}")

    # Check dependencies
    dependencies =
      state
      |> StateV2.to_triples()
      |> Enum.filter(fn {s, p, _o} -> s == module_name and p == "depends_on" end)
      |> Enum.map(fn {_s, _p, o} -> o end)

    Logger.error("IMPLEMENT_MODULE dependencies: #{inspect(dependencies)}")

    all_deps_met = Enum.all?(dependencies, fn dep ->
      StateV2.get_fact(state, dep, "status") == "documented"
    end)

    Logger.error("IMPLEMENT_MODULE all_deps_met: #{inspect(all_deps_met)}")

    if all_deps_met do
      new_state = StateV2.set_fact(state, module_name, "status", "completed")
      Logger.error("IMPLEMENT_MODULE SUCCESS - new state: #{inspect(StateV2.to_triples(new_state))}")
      new_state
    else
      Logger.error("IMPLEMENT_MODULE FAILED - dependencies not met")
      false
    end
  end

  def integrate_modules(state, [modules]) do
    # For now, just marks the integration as done.
    # A more complex implementation could check for conflicts.
    StateV2.set_fact(state, {:integration, modules}, "status", "completed")
  end

  def test_implementation(state, [module_name]) do
    require Logger
    Logger.error("TEST_IMPLEMENTATION called with module_name: #{inspect(module_name)}")
    Logger.error("TEST_IMPLEMENTATION state: #{inspect(StateV2.to_triples(state))}")

    current_status = StateV2.get_fact(state, module_name, "status")
    Logger.error("TEST_IMPLEMENTATION current_status: #{inspect(current_status)}")

    if current_status == "completed" do
      new_state = StateV2.set_fact(state, module_name, "status", "tested")
      Logger.error("TEST_IMPLEMENTATION SUCCESS - new state: #{inspect(StateV2.to_triples(new_state))}")
      new_state
    else
      Logger.error("TEST_IMPLEMENTATION FAILED - status not 'completed'")
      false
    end
  end

  def document_module(state, [module_name]) do
    if StateV2.get_fact(state, module_name, "status") == "tested" do
      StateV2.set_fact(state, module_name, "status", "documented")
    else
      false
    end
  end

  def refactor_module(state, [module_name]) do
    # Assumes refactoring happens after initial implementation
    if StateV2.get_fact(state, module_name, "status") in ["completed", "tested", "documented"] do
      StateV2.set_fact(state, module_name, "status", "completed") # Needs re-testing and re-documenting
    else
      false
    end
  end

  def verify_typespecs(state, [module_name]) do
    # For now, this is a conceptual action.
    # In a real scenario, it might involve static analysis.
    if StateV2.get_fact(state, module_name, "status") == "documented" do
      StateV2.set_fact(state, module_name, "typespecs", "verified")
    else
      false
    end
  end

  # --- Methods ---

  def achieve_goal(state, {subject, "status", "documented"}) do
    require Logger
    Logger.error("ACHIEVE_GOAL called with state: #{inspect(StateV2.to_triples(state))}")
    Logger.error("ACHIEVE_GOAL goal: #{inspect({subject, "status", "documented"})}")

    result = [
      [{"develop_module", [subject]}]
    ]
    Logger.error("ACHIEVE_GOAL returning: #{inspect(result)}")
    result
  end

  def develop_module(state, module_name) do
    require Logger
    Logger.error("DEVELOP_MODULE called with state: #{inspect(StateV2.to_triples(state))}")
    Logger.error("DEVELOP_MODULE module_name: #{inspect(module_name)}")

    # Handle both single module name and list of module names
    actual_module_name = case module_name do
      [name] when is_binary(name) -> name
      name when is_binary(name) -> name
      _ -> module_name
    end

    Logger.error("DEVELOP_MODULE actual_module_name: #{inspect(actual_module_name)}")

    result = [
      [
        {:implement_module, [actual_module_name]},
        {:test_implementation, [actual_module_name]},
        {:document_module, [actual_module_name]},
        {:verify_typespecs, [actual_module_name]}
      ]
    ]
    Logger.error("DEVELOP_MODULE returning: #{inspect(result)}")
    result
  end

  def develop_system(state, system_name) do
    require Logger
    Logger.error("DEVELOP_SYSTEM called with state: #{inspect(StateV2.to_triples(state))}")
    Logger.error("DEVELOP_SYSTEM system_name: #{inspect(system_name)}")

    modules = StateV2.get_subjects_with_fact(state, "type", "module")
    Logger.error("DEVELOP_SYSTEM found modules: #{inspect(modules)}")

    tasks = Enum.map(modules, fn module_name ->
      {"develop_module", [module_name]}
    end)
    result = [tasks ++ [{:integrate_modules, [modules]}]]
    Logger.error("DEVELOP_SYSTEM returning: #{inspect(result)}")
    result
  end
end
