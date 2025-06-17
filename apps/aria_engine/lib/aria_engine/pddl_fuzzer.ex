defmodule AriaEngine.PddlFuzzer do
  @moduledoc """
  Generates random PDDL/HDDL domain and problem structures for fuzzing.
  """

  alias AriaEngine.Pddl.Domain
  alias AriaEngine.Pddl.Domain.{Action, Type, Task, Method, Parameter}
  alias AriaEngine.Pddl.Problem
  alias AriaEngine.Pddl.Problem.{Object, InitFact, Goal}

  @max_elements 5
  @max_params 3
  @max_depth 2

  # Public API
  def generate_random_domain() do
    Domain.new(
      random_atom(),
      requirements: [:strips, :typing], # Simplified for now
      types: generate_types(),
      predicates: generate_predicates(),
      functions: generate_functions(),
      actions: generate_actions(),
      tasks: generate_tasks(),
      methods: generate_methods()
    )
  end

  def generate_random_problem(domain_name \\ :fuzz_domain) do
    Problem.new(
      random_atom(),
      domain_name,
      generate_objects(),
      generate_init_facts(),
      generate_goals()
    )
  end

  # Private generation functions
  defp random_atom(prefix \\ "item") do
    String.to_atom("#{prefix}_#{:rand.uniform(1000)}")
  end

  defp random_list(generator, max_count \\ @max_elements) do
    count = :rand.uniform(max_count)
    Enum.map(1..count, fn _ -> generator.() end)
  end

  defp generate_types() do
    random_list(fn ->
      Type.new(random_atom("type"), if(:rand.uniform(2) == 1, do: random_atom("type"), else: nil))
    end)
  end

  defp generate_predicates() do
    random_list(fn ->
      {random_atom("pred"), generate_parameters_as_atoms()}
    end)
  end

  defp generate_functions() do
    random_list(fn ->
      {random_atom("func"), generate_parameters_as_atoms()}
    end)
  end

  defp generate_parameters() do
    random_list(fn ->
      Parameter.new(random_atom("var"), random_atom("type"))
    end, @max_params)
  end

  defp generate_parameters_as_atoms() do
    random_list(fn ->
      random_atom("var")
    end, @max_params)
  end

  defp generate_actions() do
    random_list(fn ->
      Action.new(
        random_atom("action"),
        generate_parameters(),
        :rand.uniform(10), # Placeholder for duration
        generate_expression(@max_depth),
        generate_expression(@max_depth)
      )
    end)
  end

  defp generate_tasks() do
    random_list(fn ->
      Task.new(random_atom("task"), generate_parameters())
    end)
  end

  defp generate_methods() do
    random_list(fn ->
      Method.new(
        random_atom("method"),
        Task.new(random_atom("task"), generate_parameters()),
        generate_parameters(),
        generate_expression(@max_depth),
        [], # Simplified for now
        random_list(fn -> Task.new(random_atom("subtask"), generate_parameters()) end)
      )
    end)
  end

  defp generate_objects() do
    random_list(fn ->
      Object.new(random_atom("obj"), random_atom("type"))
    end)
  end

  defp generate_init_facts() do
    random_list(fn ->
      case :rand.uniform(2) do
        1 -> InitFact.Predicate.new(random_atom("pred"), random_list(fn -> random_atom("obj") end, @max_params))
        2 -> InitFact.Function.new(random_atom("func"), random_list(fn -> random_atom("obj") end, @max_params), :rand.uniform(100))
      end
    end)
  end

  defp generate_goals() do
    random_list(fn ->
      Goal.Task.new(random_atom("task"), random_list(fn -> random_atom("obj") end, @max_params))
    end)
  end

  # Expression generation (simplified for now)
  defp generate_expression(0), do: generate_literal()
  defp generate_expression(depth) do
    case :rand.uniform(3) do
      1 -> generate_literal()
      2 -> {:and, random_list(fn -> generate_expression(depth - 1) end, 2)}
      3 -> {:not, generate_expression(depth - 1)}
    end
  end

  defp generate_literal() do
    case :rand.uniform(2) do
      1 -> {random_atom("pred"), generate_parameters_as_atoms()}
      2 -> {random_atom("func"), generate_parameters_as_atoms()}
    end
  end
end
