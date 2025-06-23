defmodule HybridPlanner.StrategyRegistry do
  @moduledoc "Registry of planning strategy functions that can be composed at runtime.\n\nPure Function as Object implementation following Martin Fowler's pattern.\nAll strategies are functions that can be stored, passed around, and composed\nwithout requiring complex object hierarchies.\n\n## Function Signatures\n\nAll strategy functions follow consistent signatures for composability:\n\n- Planning strategies: `(Domain.t(), AriaEngine.StateV2.t(), [term()], keyword()) -> {:ok, term()} | {:error, String.t()}`\n- Temporal strategies: `(term(), Domain.t(), keyword()) -> {:ok, term()} | {:error, String.t()}`\n- Execution strategies: `(Domain.t(), AriaEngine.StateV2.t(), term(), keyword()) -> {:ok, AriaEngine.StateV2.t()} | {:error, String.t()}`\n\n## Usage\n\n    strategies = StrategyRegistry.default_strategies()\n    planning_fn = strategies.planning.htn\n    temporal_fn = strategies.temporal.stn\n    execution_fn = strategies.execution.lazy\n    \n    # Compose them in a coordinator\n    coordinator = StrategyCoordinator.new(planning_fn, temporal_fn, execution_fn)\n"
  alias TemporalPlanner.{STNPlanner, STNMethod, STNAction}

  @type planning_strategy :: (Domain.Core.t(), AriaEngine.State.t(), [term()], keyword() ->
                                {:ok, term()} | {:error, String.t()})
  @type temporal_strategy :: (term(), Domain.Core.t(), keyword() ->
                                {:ok, term()} | {:error, String.t()})
  @type execution_strategy :: (Domain.Core.t(), AriaEngine.State.t(), term(), keyword() ->
                                 {:ok, AriaEngine.State.t()} | {:error, String.t()})
  @type strategy_map :: %{
          planning: %{atom() => planning_strategy()},
          temporal: %{atom() => temporal_strategy()},
          execution: %{atom() => execution_strategy()}
        }
  @doc "Get the default registry of strategy functions.\n\nReturns a map of strategy categories, each containing named function strategies.\n"
  @spec default_strategies() :: strategy_map()
  def default_strategies() do
    %{
      planning: %{
        htn: &htn_planning_strategy/4,
        strips: &strips_planning_strategy/4,
        reactive: &reactive_planning_strategy/4
      },
      temporal: %{
        stn: &stn_temporal_strategy/3,
        csp: &csp_temporal_strategy/3,
        none: &no_temporal_strategy/3
      },
      execution: %{
        lazy: &lazy_execution_strategy/4,
        eager: &eager_execution_strategy/4,
        streaming: &streaming_execution_strategy/4
      }
    }
  end

  @doc "Register a custom strategy function.\n"
  @spec register_strategy(strategy_map(), atom(), atom(), function()) :: strategy_map()
  def register_strategy(strategies, category, name, strategy_fn) do
    put_in(strategies, [category, name], strategy_fn)
  end

  @doc "Get a specific strategy function by category and name.\n"
  @spec get_strategy(strategy_map(), atom(), atom()) :: {:ok, function()} | {:error, String.t()}
  def get_strategy(strategies, category, name) do
    case get_in(strategies, [category, name]) do
      nil -> {:error, "Strategy #{category}.#{name} not found"}
      strategy_fn -> {:ok, strategy_fn}
    end
  end

  @doc "Create a function pipeline for enhanced strategy composition.\n"
  @spec create_pipeline([function()]) :: function()
  def create_pipeline(functions) when is_list(functions) do
    fn input ->
      Enum.reduce_while(functions, {:ok, input}, fn func, {:ok, acc} ->
        case func.(acc) do
          {:ok, result} -> {:cont, {:ok, result}}
          error -> {:halt, error}
        end
      end)
    end
  end

  @doc false
  def htn_planning_strategy(domain, state, goals, opts) do
    Plan.plan(domain, state, goals, opts)
  end

  @doc false
  def strips_planning_strategy(domain, state, goals, opts) do
    Plan.plan(domain, state, goals, opts)
  end

  @doc false
  def reactive_planning_strategy(domain, state, goals, opts) do
    Plan.plan(domain, state, goals, opts)
  end

  @doc false
  def stn_temporal_strategy(plan, domain, opts) do
    current_time = Keyword.get(opts, :current_time, 0)

    try do
      stn_methods = solution_tree_to_stn_methods_with_bridges(plan, domain, current_time)
      goal_id = "validation_#{:erlang.system_time(:millisecond)}"
      planner = STNPlanner.new(goal_id, :hierarchical, methods: stn_methods)

      if STNPlanner.consistent?(planner) do
        {:ok, plan}
      else
        {:error, "STN temporal constraints are inconsistent"}
      end
    rescue
      e -> {:error, "STN validation error: #{Exception.message(e)}"}
    end
  end

  @doc false
  def csp_temporal_strategy(plan, _domain, _opts) do
    {:ok, plan}
  end

  @doc false
  def no_temporal_strategy(plan, _domain, _opts) do
    {:ok, plan}
  end

  @doc false
  def lazy_execution_strategy(domain, state, plan, opts) do
    Plan.run_lazy_refineahead(domain, state, plan, opts)
  end

  @doc false
  def eager_execution_strategy(domain, state, plan, opts) do
    Plan.run_lazy_refineahead(domain, state, plan, opts)
  end

  @doc false
  def streaming_execution_strategy(domain, state, plan, opts) do
    Plan.run_lazy_refineahead(domain, state, plan, opts)
  end

  defp solution_tree_to_stn_methods_with_bridges(solution_tree, domain, current_time) do
    primitive_actions = AriaEngine.Plan.Utils.get_primitive_actions_dfs(solution_tree)
    action_segments = group_actions_into_temporal_segments(primitive_actions)

    action_segments
    |> Enum.with_index()
    |> Enum.map(fn {segment, index} ->
      create_stn_method_with_bridges(segment, index, domain, current_time)
    end)
  end

  defp group_actions_into_temporal_segments(primitive_actions) do
    Enum.map(primitive_actions, fn action -> [action] end)
  end

  defp create_stn_method_with_bridges(action_segment, segment_index, domain, current_time) do
    method_id = "segment_#{segment_index}"

    bridge_actions = [
      %{
        action_id: "select_method_#{method_id}",
        type: :decision,
        duration: :instantaneous,
        metadata: %{
          htn_operation: :method_selection,
          segment_index: segment_index,
          timestamp: current_time
        }
      },
      %{
        action_id: "validate_state_#{method_id}",
        type: :condition,
        duration: :instantaneous,
        metadata: %{
          htn_operation: :state_validation,
          segment_index: segment_index,
          timestamp: current_time
        }
      }
    ]

    stn_actions =
      action_segment
      |> Enum.with_index()
      |> Enum.map(fn {{action_name, args}, action_index} ->
        create_temporal_stn_action_from_primitive(
          action_name,
          args,
          segment_index,
          action_index,
          domain
        )
      end)

    STNMethod.new(method_id, :sequential, stn_actions,
      bridge_actions: bridge_actions,
      metadata: %{
        segment_index: segment_index,
        primitive_actions: action_segment,
        domain_name: domain.name
      }
    )
  end

  defp create_temporal_stn_action_from_primitive(
         action_name,
         args,
         segment_index,
         action_index,
         domain
       ) do
    action_id = "#{action_name}_#{segment_index}_#{action_index}"
    duration = get_action_duration(action_name, domain)

    STNAction.new(action_id,
      duration: duration,
      preconditions: [],
      effects: [],
      metadata: %{
        primitive_action: {action_name, args},
        segment_index: segment_index,
        action_index: action_index,
        domain_action: true
      }
    )
  end

  defp get_action_duration(action_name, domain) do
    case Domain.get_action_metadata(domain, action_name) do
      %{duration: %Timeline.Interval{} = interval} ->
        fixed_duration = Timeline.Interval.duration_ms(interval)
        {fixed_duration, fixed_duration}

      %{duration: {min, max}} when is_integer(min) and is_integer(max) and min <= max ->
        {min, max}

      _ ->
        {1, 5}
    end
  end
end