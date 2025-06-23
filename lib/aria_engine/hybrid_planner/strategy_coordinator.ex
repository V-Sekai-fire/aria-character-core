defmodule HybridPlanner.StrategyCoordinator do
  @moduledoc "Coordinates planning using pluggable function strategies.\n\nEmbodies Martin Fowler's Function as Object pattern completely by treating\nplanning strategies as composable functions that can be stored, passed around,\nand combined at runtime without requiring object hierarchies.\n\n## Function as Object Benefits\n\n- **Pure Composition**: Strategies are just functions, no inheritance needed\n- **Runtime Flexibility**: Change strategies dynamically based on problem characteristics\n- **Easy Testing**: Mock strategies are just simple functions\n- **No Coupling**: Strategies don't know about each other, only input/output contracts\n\n## Usage Examples\n\n    # Basic composition\n    coordinator = StrategyCoordinator.hybrid_htn_stn()\n    result = StrategyCoordinator.coordinate(coordinator, domain, state, goals)\n    \n    # Custom composition\n    custom_coordinator = StrategyCoordinator.new(\n      &MyPlanner.plan/4,\n      &MyTemporal.validate/3,\n      &MyExecutor.run/4\n    )\n    \n    # Runtime strategy selection\n    coordinator = case problem_complexity do\n      :simple -> StrategyCoordinator.pure_strips()\n      :temporal -> StrategyCoordinator.hybrid_htn_stn()\n      :custom -> StrategyCoordinator.from_config(config)\n    end\n"
  require Logger
  alias HybridPlanner.StrategyRegistry
  @type strategy_function :: function()
  @type coordination_result :: {:ok, AriaEngine.State.t()} | {:error, String.t()}
  defstruct [:planning_fn, :temporal_fn, :execution_fn, :metadata, :middleware]

  @type t :: %__MODULE__{
          planning_fn: StrategyRegistry.planning_strategy(),
          temporal_fn: StrategyRegistry.temporal_strategy(),
          execution_fn: StrategyRegistry.execution_strategy(),
          metadata: map(),
          middleware: [function()]
        }
  @doc "Create a strategy coordinator with custom function strategies.\n\nThis is the core Function as Object constructor - just pass in functions.\n"
  @spec new(
          StrategyRegistry.planning_strategy(),
          StrategyRegistry.temporal_strategy(),
          StrategyRegistry.execution_strategy(),
          map(),
          [function()]
        ) :: t()
  def new(planning_fn, temporal_fn, execution_fn, metadata \\ %{}, middleware \\ []) do
    %__MODULE__{
      planning_fn: planning_fn,
      temporal_fn: temporal_fn,
      execution_fn: execution_fn,
      metadata: metadata,
      middleware: middleware
    }
  end

  @doc "Create a coordinator from named strategies in the registry.\n"
  @spec from_strategies(atom(), atom(), atom(), map()) :: {:ok, t()} | {:error, String.t()}
  def from_strategies(planning_strategy, temporal_strategy, execution_strategy, metadata \\ %{}) do
    strategies = StrategyRegistry.default_strategies()

    with {:ok, planning_fn} <-
           StrategyRegistry.get_strategy(strategies, :planning, planning_strategy),
         {:ok, temporal_fn} <-
           StrategyRegistry.get_strategy(strategies, :temporal, temporal_strategy),
         {:ok, execution_fn} <-
           StrategyRegistry.get_strategy(strategies, :execution, execution_strategy) do
      coordinator = new(planning_fn, temporal_fn, execution_fn, metadata)
      {:ok, coordinator}
    end
  end

  @doc "Create hybrid HTN+STN coordinator (most common configuration).\n"
  @spec hybrid_htn_stn(map()) :: t()
  def hybrid_htn_stn(metadata \\ %{}) do
    strategies = StrategyRegistry.default_strategies()

    new(
      strategies.planning.htn,
      strategies.temporal.stn,
      strategies.execution.lazy,
      Map.merge(
        %{
          name: "Hybrid HTN+STN",
          description: "HTN planning with STN temporal validation and lazy execution",
          strategy_types: [:htn, :stn, :lazy]
        },
        metadata
      )
    )
  end

  @doc "Create pure STRIPS coordinator (no temporal reasoning).\n"
  @spec pure_strips(map()) :: t()
  def pure_strips(metadata \\ %{}) do
    strategies = StrategyRegistry.default_strategies()

    new(
      strategies.planning.strips,
      strategies.temporal.none,
      strategies.execution.eager,
      Map.merge(
        %{
          name: "Pure STRIPS",
          description: "Classical STRIPS planning without temporal reasoning",
          strategy_types: [:strips, :none, :eager]
        },
        metadata
      )
    )
  end

  @doc "Create reactive planning coordinator (fast replanning).\n"
  @spec reactive_planner(map()) :: t()
  def reactive_planner(metadata \\ %{}) do
    strategies = StrategyRegistry.default_strategies()

    new(
      strategies.planning.reactive,
      strategies.temporal.none,
      strategies.execution.streaming,
      Map.merge(
        %{
          name: "Reactive Planner",
          description: "Fast reactive planning with streaming execution",
          strategy_types: [:reactive, :none, :streaming]
        },
        metadata
      )
    )
  end

  @doc "Create coordinator from configuration map.\n"
  @spec from_config(map()) :: {:ok, t()} | {:error, String.t()}
  def from_config(%{planning: planning, temporal: temporal, execution: execution} = config) do
    metadata = Map.get(config, :metadata, %{})
    middleware = Map.get(config, :middleware, [])

    case from_strategies(planning, temporal, execution, metadata) do
      {:ok, coordinator} -> {:ok, %{coordinator | middleware: middleware}}
      error -> error
    end
  end

  @doc "Coordinate planning using the composed function strategies.\n\nThis is where Function as Object shines - just call the functions in sequence.\n"
  @spec coordinate(t(), Domain.Core.t(), AriaEngine.State.t(), [term()], keyword()) ::
          coordination_result()
  def coordinate(%__MODULE__{} = coordinator, domain, state, goals, opts \\ []) do
    with {:ok, plan} <-
           call_with_middleware(
             coordinator.planning_fn,
             [domain, state, goals, opts],
             coordinator.middleware
           ),
         {:ok, validated_plan} <-
           call_with_middleware(
             coordinator.temporal_fn,
             [plan, domain, opts],
             coordinator.middleware
           ) do
      call_with_middleware(
        coordinator.execution_fn,
        [domain, state, validated_plan, opts],
        coordinator.middleware
      )
    end
  end

  @doc "Plan only (without execution) using the coordinator's strategies.\n"
  @spec plan_only(t(), Domain.Core.t(), AriaEngine.State.t(), [term()], keyword()) ::
          {:ok, term()} | {:error, String.t()}
  def plan_only(%__MODULE__{} = coordinator, domain, state, goals, opts \\ []) do
    with {:ok, plan} <-
           call_with_middleware(
             coordinator.planning_fn,
             [domain, state, goals, opts],
             coordinator.middleware
           ) do
      call_with_middleware(
        coordinator.temporal_fn,
        [plan, domain, opts],
        coordinator.middleware
      )
    end
  end

  @doc "Execute a pre-planned solution using the coordinator's execution strategy.\n"
  @spec execute_only(t(), Domain.Core.t(), AriaEngine.State.t(), term(), keyword()) ::
          {:ok, AriaEngine.State.t()} | {:error, String.t()}
  def execute_only(%__MODULE__{} = coordinator, domain, state, plan, opts \\ []) do
    call_with_middleware(
      coordinator.execution_fn,
      [domain, state, plan, opts],
      coordinator.middleware
    )
  end

  @doc "Wrap a strategy function with middleware (logging, caching, timing, etc.).\n\nPure Function as Object - middleware are just functions that wrap other functions.\n"
  @spec with_middleware(strategy_function(), [function()]) :: strategy_function()
  def with_middleware(strategy_fn, middleware) when is_list(middleware) do
    Enum.reduce(middleware, strategy_fn, fn middleware_fn, acc_fn ->
      fn args -> middleware_fn.(acc_fn, args) end
    end)
  end

  @doc "Create logging middleware function.\n"
  @spec logging_middleware(String.t()) :: function()
  def logging_middleware(label) do
    fn strategy_fn, args ->
      start_time = System.monotonic_time(:millisecond)
      result = apply(strategy_fn, args)
      end_time = System.monotonic_time(:millisecond)
      duration = end_time - start_time

      case result do
        {:ok, _} -> Logger.debug("#{label} succeeded in #{duration}ms")
        {:error, reason} -> Logger.error("#{label} failed in #{duration}ms: #{reason}")
      end

      result
    end
  end

  @doc "Create caching middleware function.\n"
  @spec caching_middleware(atom()) :: function()
  def caching_middleware(cache_name) do
    fn strategy_fn, args ->
      cache_key = :erlang.phash2(args)

      case :ets.lookup(cache_name, cache_key) do
        [{^cache_key, cached_result}] ->
          cached_result

        [] ->
          result = apply(strategy_fn, args)
          :ets.insert(cache_name, {cache_key, result})
          result
      end
    end
  end

  @doc "Create timeout middleware function.\n"
  @spec timeout_middleware(integer()) :: function()
  def timeout_middleware(timeout_ms) do
    fn strategy_fn, args ->
      task = Task.async(fn -> apply(strategy_fn, args) end)

      case Task.yield(task, timeout_ms) do
        {:ok, result} ->
          result

        nil ->
          Task.shutdown(task, :brutal_kill)
          {:error, "Strategy timed out after #{timeout_ms}ms"}
      end
    end
  end

  @doc "Get metadata about the coordinator's strategy functions.\n"
  @spec get_strategy_info(t()) :: map()
  def get_strategy_info(%__MODULE__{} = coordinator) do
    %{
      planning_function: inspect_function(coordinator.planning_fn),
      temporal_function: inspect_function(coordinator.temporal_fn),
      execution_function: inspect_function(coordinator.execution_fn),
      middleware_count: length(coordinator.middleware),
      metadata: coordinator.metadata
    }
  end

  @doc "Test if a coordinator is compatible with a domain (checks function signatures).\n"
  @spec compatible_with_domain?(t(), Domain.Core.t()) :: boolean()
  def compatible_with_domain?(%__MODULE__{} = coordinator, %Domain.Core{}) do
    try do
      is_function(coordinator.planning_fn, 4) and is_function(coordinator.temporal_fn, 3) and
        is_function(coordinator.execution_fn, 4)
    rescue
      _ -> false
    end
  end

  defp call_with_middleware(strategy_fn, args, []) do
    apply(strategy_fn, args)
  end

  defp call_with_middleware(strategy_fn, args, middleware) do
    enhanced_fn = with_middleware(strategy_fn, middleware)
    enhanced_fn.(args)
  end

  defp inspect_function(fun) when is_function(fun) do
    info = Function.info(fun)
    %{arity: info[:arity], module: info[:module], name: info[:name], type: info[:type]}
  end
end