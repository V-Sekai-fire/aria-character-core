defmodule AriaEngine.PddlParser.DomainParser.Tasks do
  @moduledoc """
  Parses the tasks section of a PDDL domain string.
  """
  alias AriaEngine.Pddl.Domain.Task
  alias AriaEngine.PddlParser.DomainParser.Actions.Parameters # For parse_action_parameters

  @type parsed_task :: Task.t()

  @spec parse_task_block(String.t()) :: Task.t()
  def parse_task_block(task_content) do
    parts = String.split(task_content, " ", trim: true)
    name = List.first(parts)
    Task.new(
      String.to_atom(name),
      Parameters.parse_action_parameters(task_content)
    )
  end
end
