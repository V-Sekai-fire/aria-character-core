defmodule HybridPlanner.Strategies.Default.DomainStrategy do
  @moduledoc "Default domain strategy implementation wrapping existing domain operations.\n\nThis strategy encapsulates domain queries and metadata operations while\nproviding the clean strategy interface defined in ADR-091.\n"
  @behaviour HybridPlanner.Strategies.DomainStrategy
  require Logger
  @impl true
  def get_action_metadata(domain, action_name, _opts \\ []) do
    try do
      case Map.get(domain.actions, action_name) do
        action_fn when is_function(action_fn) ->
          metadata = %{
            name: action_name,
            arity: :erlang.fun_info(action_fn, :arity) |> elem(1),
            type: :primitive_action,
            available: true
          }

          {:ok, metadata}

        nil ->
          {:error, "Action #{action_name} not found in domain"}
      end
    rescue
      e -> {:error, "DomainStrategy action metadata error: #{Exception.message(e)}"}
    end
  end

  @impl true
  def get_task_methods(domain, task_name, _opts \\ []) do
    try do
      case Map.get(domain.task_methods, task_name) do
        methods when is_list(methods) -> {:ok, methods}
        nil -> {:ok, []}
      end
    rescue
      e -> {:error, "DomainStrategy task methods error: #{Exception.message(e)}"}
    end
  end

  @impl true
  def get_goal_methods(domain, goal_spec, _opts \\ []) do
    try do
      case goal_spec do
        {predicate, subject, _value} ->
          goal_key = "#{predicate}_#{subject}"

          case Map.get(domain.unigoal_methods, goal_key) do
            methods when is_list(methods) ->
              {:ok, methods}

            nil ->
              case Map.get(domain.unigoal_methods, predicate) do
                methods when is_list(methods) -> {:ok, methods}
                nil -> {:ok, []}
              end
          end

        _ ->
          {:ok, []}
      end
    rescue
      e -> {:error, "DomainStrategy goal methods error: #{Exception.message(e)}"}
    end
  end

  @impl true
  def validate_domain(domain, _opts \\ []) do
    try do
      errors = []

      errors =
        if is_map(domain.actions) do
          errors
        else
          ["Actions must be a map" | errors]
        end

      errors =
        if is_map(domain.task_methods) do
          errors
        else
          ["Task methods must be a map" | errors]
        end

      errors =
        if is_map(domain.unigoal_methods) do
          errors
        else
          ["Unigoal methods must be a map" | errors]
        end

      errors =
        if is_list(domain.multigoal_methods) do
          errors
        else
          ["Multigoal methods must be a list" | errors]
        end

      case errors do
        [] -> {:ok, true}
        error_list -> {:error, "Domain validation failed: #{Enum.join(error_list, ", ")}"}
      end
    rescue
      e -> {:error, "DomainStrategy validation error: #{Exception.message(e)}"}
    end
  end

  def strategy_info do
    %{
      name: "Domain Strategy",
      version: "1.0.0",
      description: "Default domain query and metadata strategy",
      capabilities: [:action_metadata, :method_queries, :domain_validation],
      underlying_implementation: "Domain.Core"
    }
  end
end