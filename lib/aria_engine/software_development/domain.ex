defmodule AriaEngine.SoftwareDevelopment.Domain do
  @moduledoc """
  Represents the domain of software development for planning purposes.
  This domain includes actions for implementing, testing, and documenting
  software modules, allowing the AriaEngine to plan its own development.
  """
  alias AriaEngine.Domain
  alias AriaEngine.StateV2

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
    # Check dependencies
    dependencies =
      state
      |> StateV2.to_triples()
      |> Enum.filter(fn {s, p, _o} -> s == module_name and p == "depends_on" end)
      |> Enum.map(fn {_s, _p, o} -> o end)

    all_deps_met = Enum.all?(dependencies, fn dep ->
      StateV2.get_fact(state, dep, "status") == "documented"
    end)

    if all_deps_met do
      StateV2.set_fact(state, module_name, "status", "completed")
    else
      false
    end
  end

  def integrate_modules(state, [modules]) do
    # For now, just marks the integration as done.
    # A more complex implementation could check for conflicts.
    StateV2.set_fact(state, {:integration, modules}, "status", "completed")
  end

  def test_implementation(state, [module_name]) do
    if StateV2.get_fact(state, module_name, "status") == "completed" do
      StateV2.set_fact(state, module_name, "status", "tested")
    else
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

  def achieve_goal(_state, {subject, "status", "documented"}) do
    [
      [{"develop_module", [subject]}]
    ]
  end

  def develop_module(_state, module_name) do
    [
      [
        {:implement_module, [module_name]},
        {:test_implementation, [module_name]},
        {:document_module, [module_name]},
        {:verify_typespecs, [module_name]}
      ]
    ]
  end

  def develop_system(state, _system_name) do
    modules = StateV2.get_subjects_with_fact(state, "type", "module")

    tasks = Enum.map(modules, fn module_name ->
      {"develop_module", [module_name]}
    end)
    [tasks ++ [{:integrate_modules, [modules]}]]
  end
end
