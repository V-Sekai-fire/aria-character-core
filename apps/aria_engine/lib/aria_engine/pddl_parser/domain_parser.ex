defmodule AriaEngine.PddlParser.DomainParser do
  @moduledoc """
  Parses the domain section of a PDDL string.
  """
  alias AriaEngine.Pddl.Domain.{Action, Type, Task, Method}
  alias AriaEngine.PddlParser.Core
  alias AriaEngine.PddlParser.DomainParser.Types
  alias AriaEngine.PddlParser.DomainParser.Predicates
  alias AriaEngine.PddlParser.DomainParser.Functions
  alias AriaEngine.PddlParser.DomainParser.Actions
  alias AriaEngine.PddlParser.DomainParser.Tasks
  alias AriaEngine.PddlParser.DomainParser.Methods

  @type parsed_domain_sections :: %{
          types: [Type.t()],
          predicates: [{atom(), [atom()]}],
          functions: [{atom(), [atom()]}],
          actions: [Action.t()],
          tasks: [Task.t()],
          methods: [Method.t()]
        }

  @spec parse_domain_sections(String.t()) :: parsed_domain_sections()
  def parse_domain_sections(pddl_string) do
    types_str = Core.parse_pddl_block(pddl_string, ":types")
    predicates_str = Core.parse_pddl_block(pddl_string, ":predicates")
    functions_str = Core.parse_pddl_block(pddl_string, ":functions")

    actions_contents = Core.parse_pddl_blocks(pddl_string, ":action") # Changed from :durative-action
    tasks_contents = Core.parse_pddl_blocks(pddl_string, ":task")
    methods_contents = Core.parse_pddl_blocks(pddl_string, ":method")

    types = if elem(types_str, 0) == :ok, do: Types.parse_types(elem(types_str, 1)), else: []
    predicates = if elem(predicates_str, 0) == :ok, do: Predicates.parse_predicates(elem(predicates_str, 1)), else: []
    functions = if elem(functions_str, 0) == :ok, do: Functions.parse_functions(elem(functions_str, 1)), else: []

    actions = Enum.map(actions_contents, &Actions.Core.parse_action/1) # Changed from parse_durative_action
    tasks = Enum.map(tasks_contents, &Tasks.parse_task_block/1)
    methods = Enum.map(methods_contents, &Methods.Core.parse_method_block/1)

    %{
      types: types,
      predicates: predicates,
      functions: functions,
      actions: actions, # Changed from durative_actions
      tasks: tasks,
      methods: methods
    }
  end
end
