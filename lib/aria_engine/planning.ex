defmodule Planning do
  @moduledoc "Provides core planning and execution functionalities for the Aria Engine.\n"
  alias Planning.CoreInterface
  alias Core
  @type t :: Core.t()
  @type solution_tree :: Core.solution_tree()
  @type plan_step :: Core.plan_step()
  @type todo_item :: Core.todo_item()
  defdelegate plan(domain, state, todos, opts), to: CoreInterface
  defdelegate plan_with_tree(domain, state, todos, opts), to: CoreInterface
  defdelegate execute_plan(domain, initial_state, plan), to: CoreInterface
  defdelegate replan(engine, fail_node_id, opts), to: CoreInterface
  defdelegate validate_plan(engine), to: CoreInterface
end