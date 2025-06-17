defmodule AriaEngine.PddlParser.DomainParser.Methods.Core do
  @moduledoc """
  Core parsing for methods.
  """
  alias AriaEngine.Pddl.Domain.Method
  alias AriaEngine.PddlParser.DomainParser.Actions.Parameters # For parse_action_parameters
  alias AriaEngine.PddlParser.DomainParser.Methods.Task, as: MethodTaskParser
  alias AriaEngine.PddlParser.DomainParser.Methods.Subtasks
  alias AriaEngine.PddlParser.DomainParser.Methods.Ordering
  alias AriaEngine.PddlParser.DomainParser.Methods.Constraints

  @type parsed_method :: Method.t()

  @spec parse_method_block(String.t()) :: Method.t()
  def parse_method_block(method_content) do
    parts = String.split(method_content, " ", trim: true)
    name = String.trim(List.first(parts)) # Trim the name
    Method.new(
      String.to_atom(name),
      MethodTaskParser.parse_method_task(method_content),
      Parameters.parse_action_parameters(method_content),
      Constraints.parse_method_constraints(method_content),
      Ordering.parse_method_ordering(method_content),
      Subtasks.parse_method_subtasks(method_content)
    )
  end
end
