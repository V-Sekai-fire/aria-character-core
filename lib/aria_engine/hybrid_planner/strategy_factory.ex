# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.StrategyFactory do
  @moduledoc """
  Factory and registry for creating and managing hybrid planner strategies.

  This module provides centralized strategy management including:
  - Strategy registration and lookup
  - Dynamic strategy composition
  - Configuration-based strategy selection
  - Runtime strategy validation and swapping

  ## Usage

      # Register strategies
      factory = StrategyFactory.new()
      |> StrategyFactory.register_strategy(:planning, :default,
           HybridPlanner.Strategies.Default.HTNPlanningStrategy)
      |> StrategyFactory.register_strategy(:planning, :optimized,
           HybridPlanner.Strategies.Optimized.HTNPlanningStrategy)

      # Create coordinator from configuration
      config = %{
        planning_strategy: :default,
        temporal_strategy: :stn,
        state_strategy: :statev2,
        domain_strategy: :default,
        logging_strategy: :verbose,
        execution_strategy: :lazy
      }

      coordinator = StrategyFactory.create_coordinator(factory, config)

      # Runtime strategy swapping
      new_coordinator = StrategyFactory.swap_strategy(coordinator, :planning, :optimized)
  """

  alias HybridPlanner.{HybridCoordinatorV2, Strategies}

  defstruct [
    :strategies,
    :configurations,
    :metadata,
    :validation_cache
  ]

  @type strategy_type ::
          :planning_strategy
          | :temporal_strategy
          | :state_strategy
          | :domain_strategy
          | :logging_strategy
          | :execution_strategy

  @type strategy_key :: atom()
  @type strategy_module :: module()
  @type strategy_config :: %{strategy_type() => strategy_key()}

  @type t :: %__MODULE__{
          strategies: %{strategy_type() => %{strategy_key() => strategy_module()}},
          configurations: %{atom() => strategy_config()},
          metadata: map(),
          validation_cache: %{strategy_module() => :ok | {:error, String.t()}}
        }

  # ==================== CONSTRUCTOR ====================

  @doc """
  Create a new strategy factory with default strategies registered.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    factory = %__MODULE__{
      strategies: %{
        planning_strategy: %{},
        temporal_strategy: %{},
        state_strategy: %{},
        domain_strategy: %{},
        logging_strategy: %{},
        execution_strategy: %{}
      },
      configurations: %{},
      metadata: %{
        created_at: System.system_time(:millisecond),
        options: opts
      },
      validation_cache: %{}
    }

    # Register default strategies
    factory
    |> register_default_strategies()
    |> register_default_configurations()
  end

  # ==================== STRATEGY REGISTRATION ====================

  @doc """
  Register a strategy implementation for a given type and key.
  """
  @spec register_strategy(t(), strategy_type(), strategy_key(), strategy_module()) :: t()
  def register_strategy(%__MODULE__{} = factory, strategy_type, strategy_key, strategy_module) do
    # Validate strategy type
    # Temporarily disabled for debugging
    # unless Map.has_key?(factory.strategies, strategy_type) do
    #   raise ArgumentError, "Unknown strategy type: #{strategy_type}"
    # end

    # Validate strategy module implements required behavior
    # Temporarily disabled due to compilation order issues
    # See ADR-120 for validation reactivation implementation plan
    # case validate_strategy_module(strategy_type, strategy_module) do
    #   :ok -> :ok
    #   {:error, reason} -> raise ArgumentError, "Strategy validation failed: #{reason}"
    # end

    # Register the strategy
    current_strategies = Map.get(factory.strategies, strategy_type, %{})
    updated_strategy_map = Map.put(current_strategies, strategy_key, strategy_module)
    updated_strategies = Map.put(factory.strategies, strategy_type, updated_strategy_map)

    %{factory | strategies: updated_strategies}
  end

  @doc """
  Register multiple strategies at once.
  """
  @spec register_strategies(t(), [{strategy_type(), strategy_key(), strategy_module()}]) :: t()
  def register_strategies(%__MODULE__{} = factory, strategy_list) do
    Enum.reduce(strategy_list, factory, fn {type, key, module}, acc ->
      register_strategy(acc, type, key, module)
    end)
  end

  @doc """
  Get a registered strategy by type and key.
  """
  @spec get_strategy(t(), strategy_type(), strategy_key()) ::
          {:ok, strategy_module()} | {:error, String.t()}
  def get_strategy(%__MODULE__{} = factory, strategy_type, strategy_key) do
    case get_in(factory.strategies, [strategy_type, strategy_key]) do
      nil -> {:error, "Strategy not found: #{strategy_type}:#{strategy_key}"}
      module -> {:ok, module}
    end
  end

  @doc """
  List all registered strategies for a given type.
  """
  @spec list_strategies(t(), strategy_type()) :: [strategy_key()]
  def list_strategies(%__MODULE__{} = factory, strategy_type) do
    factory.strategies
    |> Map.get(strategy_type, %{})
    |> Map.keys()
  end

  # ==================== CONFIGURATION MANAGEMENT ====================

  @doc """
  Register a named strategy configuration.
  """
  @spec register_configuration(t(), atom(), strategy_config()) :: t()
  def register_configuration(%__MODULE__{} = factory, config_name, strategy_config) do
    # Validate configuration
    case validate_strategy_configuration(factory, strategy_config) do
      :ok -> :ok
      {:error, reason} -> raise ArgumentError, "Configuration validation failed: #{reason}"
    end

    updated_configurations = Map.put(factory.configurations, config_name, strategy_config)
    %{factory | configurations: updated_configurations}
  end

  @doc """
  Get a registered configuration by name.
  """
  @spec get_configuration(t(), atom()) :: {:ok, strategy_config()} | {:error, String.t()}
  def get_configuration(%__MODULE__{} = factory, config_name) do
    case Map.get(factory.configurations, config_name) do
      nil -> {:error, "Configuration not found: #{config_name}"}
      config -> {:ok, config}
    end
  end

  @doc """
  List all registered configurations.
  """
  @spec list_configurations(t()) :: [atom()]
  def list_configurations(%__MODULE__{} = factory) do
    Map.keys(factory.configurations)
  end

  # ==================== COORDINATOR CREATION ====================

  @doc """
  Create a hybrid coordinator from a strategy configuration.
  """
  @spec create_coordinator(t(), strategy_config() | atom(), keyword()) ::
          {:ok, HybridCoordinatorV2.t()} | {:error, String.t()}
  def create_coordinator(factory, config, opts \\ [])

  def create_coordinator(%__MODULE__{} = factory, config_name, opts) when is_atom(config_name) do
    case get_configuration(factory, config_name) do
      {:ok, config} -> create_coordinator(factory, config, opts)
      {:error, reason} -> {:error, reason}
    end
  end

  def create_coordinator(%__MODULE__{} = factory, strategy_config, opts)
      when is_map(strategy_config) do
    try do
      # Resolve strategy modules from configuration
        case resolve_strategy_modules(factory, strategy_config) do
          {:ok, strategy_modules} ->
            # Validate all strategy modules before creating coordinator
            case validate_all_strategy_modules(factory, strategy_modules) do
              {:ok, _updated_factory} ->
                # Note: updated_factory contains validation cache but we don't need to return it
                # since we're only creating a coordinator here
                coordinator = HybridCoordinatorV2.new(strategy_modules, opts)
                {:ok, coordinator}

              {:error, reason} ->
                {:error, "Strategy validation failed: #{reason}"}
            end

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e ->
        {:error, "Coordinator creation failed: #{Exception.message(e)}"}
    end
  end

  @doc """
  Create a coordinator with default configuration.
  """
  @spec create_default_coordinator(t(), keyword()) :: HybridCoordinatorV2.t()
  def create_default_coordinator(%__MODULE__{} = factory, opts \\ []) do
    case create_coordinator(factory, :default, opts) do
      {:ok, coordinator} -> coordinator
      {:error, reason} -> raise "Failed to create default coordinator: #{reason}"
    end
  end

  # ==================== RUNTIME STRATEGY SWAPPING ====================

  @doc """
  Swap a strategy in an existing coordinator.
  """
  @spec swap_strategy(HybridCoordinatorV2.t(), strategy_type(), strategy_key(), t()) ::
          {:ok, HybridCoordinatorV2.t()} | {:error, String.t()}
  def swap_strategy(
        %HybridCoordinatorV2{} = coordinator,
        strategy_type,
        strategy_key,
        %__MODULE__{} = factory
      ) do
    case get_strategy(factory, strategy_type, strategy_key) do
      {:ok, new_strategy_module} ->
        updated_coordinator =
          HybridCoordinatorV2.replace_strategy(coordinator, strategy_type, new_strategy_module)

        {:ok, updated_coordinator}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Create a new coordinator by modifying an existing configuration.
  """
  @spec modify_configuration(t(), atom(), strategy_config(), keyword()) ::
          {:ok, HybridCoordinatorV2.t()} | {:error, String.t()}
  def modify_configuration(%__MODULE__{} = factory, base_config_name, modifications, opts \\ []) do
    case get_configuration(factory, base_config_name) do
      {:ok, base_config} ->
        modified_config = Map.merge(base_config, modifications)
        create_coordinator(factory, modified_config, opts)

      {:error, reason} ->
        {:error, reason}
    end
  end

  # ==================== STRATEGY COMPOSITION ====================

  @doc """
  Compose multiple strategy configurations into a new configuration.
  """
  @spec compose_configurations(t(), [atom()], atom()) :: {:ok, t()} | {:error, String.t()}
  def compose_configurations(%__MODULE__{} = factory, config_names, new_config_name) do
    try do
      # Collect all configurations
      configs =
        Enum.map(config_names, fn name ->
          case get_configuration(factory, name) do
            {:ok, config} -> config
            {:error, reason} -> throw({:error, reason})
          end
        end)

      # Merge configurations (later configs override earlier ones)
      composed_config = Enum.reduce(configs, %{}, &Map.merge/2)

      # Validate composed configuration
      case validate_strategy_configuration(factory, composed_config) do
        :ok ->
          updated_factory = register_configuration(factory, new_config_name, composed_config)
          {:ok, updated_factory}

        {:error, reason} ->
          {:error, "Composed configuration validation failed: #{reason}"}
      end
    catch
      {:error, reason} -> {:error, reason}
    end
  end

  # ==================== VALIDATION ====================

  @doc """
  Validate that a strategy configuration is complete and valid.
  """
  @spec validate_strategy_configuration(t(), strategy_config()) :: :ok | {:error, String.t()}
  def validate_strategy_configuration(%__MODULE__{} = factory, strategy_config) do
    required_strategies = [
      :planning_strategy,
      :temporal_strategy,
      :state_strategy,
      :domain_strategy,
      :logging_strategy,
      :execution_strategy
    ]

    # Check all required strategies are present
    missing_strategies =
      required_strategies
      |> Enum.filter(fn strategy_type -> not Map.has_key?(strategy_config, strategy_type) end)

    if length(missing_strategies) > 0 do
      {:error, "Missing required strategies: #{inspect(missing_strategies)}"}
    else
      # Validate each strategy exists in registry
      validation_results =
        Enum.map(required_strategies, fn strategy_type ->
          strategy_key = Map.get(strategy_config, strategy_type)
          get_strategy(factory, strategy_type, strategy_key)
        end)

      case Enum.find(validation_results, fn result -> match?({:error, _}, result) end) do
        nil -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  end

  # ==================== STRATEGY VALIDATION ====================

  @doc """
  Validate that a strategy module implements the required behavior for its type.

  Uses deferred validation with caching to avoid compilation order issues.
  """
  @spec validate_strategy_module(t(), strategy_type(), strategy_module()) ::
          {:ok, t()} | {:error, String.t()}
  def validate_strategy_module(%__MODULE__{} = factory, strategy_type, strategy_module) do
    # Check cache first
    case Map.get(factory.validation_cache, strategy_module) do
      nil ->
        # Perform validation and cache result
        result = perform_strategy_validation(strategy_type, strategy_module)
        updated_cache = Map.put(factory.validation_cache, strategy_module, result)
        updated_factory = %{factory | validation_cache: updated_cache}

        case result do
          :ok -> {:ok, updated_factory}
          {:error, reason} -> {:error, reason}
        end

      cached_result ->
        # Return cached result
        case cached_result do
          :ok -> {:ok, factory}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  @doc """
  Validate all strategy modules in a strategy configuration.

  This is used during coordinator creation to ensure all strategies are valid.
  """
  @spec validate_all_strategy_modules(t(), %{strategy_type() => strategy_module()}) ::
          {:ok, t()} | {:error, String.t()}
  def validate_all_strategy_modules(%__MODULE__{} = factory, strategy_modules) do
    try do
      # Validate each strategy module
      {final_factory, final_status} =
        Enum.reduce(strategy_modules, {factory, :ok}, fn {strategy_type, strategy_module}, {acc_factory, status} ->
          case status do
            :ok ->
              case validate_strategy_module(acc_factory, strategy_type, strategy_module) do
                {:ok, updated_factory} -> {updated_factory, :ok}
                {:error, reason} -> {acc_factory, {:error, reason}}
              end
            {:error, _} = error ->
              {acc_factory, error}
          end
        end)

      case final_status do
        :ok -> {:ok, final_factory}
        {:error, reason} -> {:error, reason}
      end
    rescue
      e ->
        {:error, "Strategy validation failed: #{Exception.message(e)}"}
    end
  end

  # ==================== PRIVATE HELPER FUNCTIONS ====================

  # Register default strategy implementations
  defp register_default_strategies(factory) do
    default_strategies = [
      {:planning_strategy, :default, Strategies.Default.HTNPlanningStrategy},
      {:temporal_strategy, :stn, Strategies.Default.STNBridgeTemporalStrategy},
      {:temporal_strategy, :stn_legacy, Strategies.Default.STNTemporalStrategy},
      {:temporal_strategy, :stn_bridge, Strategies.Default.STNBridgeTemporalStrategy},
      {:state_strategy, :statev2, Strategies.Default.StateStrategy},
      {:domain_strategy, :default, Strategies.Default.DomainStrategy},
      {:logging_strategy, :default, Strategies.Default.LoggerStrategy},
      {:logging_strategy, :verbose, Strategies.Default.LoggerStrategy},
      {:logging_strategy, :quiet, Strategies.Default.LoggerStrategy},
      {:execution_strategy, :lazy, Strategies.Default.LazyExecutionStrategy}
    ]

    register_strategies(factory, default_strategies)
  end

  # Register default configurations
  defp register_default_configurations(factory) do
    default_config = %{
      planning_strategy: :default,
      temporal_strategy: :stn,
      state_strategy: :statev2,
      domain_strategy: :default,
      logging_strategy: :default,
      execution_strategy: :lazy
    }

    verbose_config = %{
      planning_strategy: :default,
      temporal_strategy: :stn,
      state_strategy: :statev2,
      domain_strategy: :default,
      logging_strategy: :verbose,
      execution_strategy: :lazy
    }

    quiet_config = %{
      planning_strategy: :default,
      temporal_strategy: :stn,
      state_strategy: :statev2,
      domain_strategy: :default,
      logging_strategy: :quiet,
      execution_strategy: :lazy
    }

    # Bridge-enabled configurations
    always_bridge_config = %{
      planning_strategy: :default,
      temporal_strategy: :stn_bridge,
      state_strategy: :statev2,
      domain_strategy: :default,
      logging_strategy: :default,
      execution_strategy: :lazy
    }

    bridge_verbose_config = %{
      planning_strategy: :default,
      temporal_strategy: :stn_bridge,
      state_strategy: :statev2,
      domain_strategy: :default,
      logging_strategy: :verbose,
      execution_strategy: :lazy
    }

    factory
    |> register_configuration(:default, default_config)
    |> register_configuration(:verbose, verbose_config)
    |> register_configuration(:quiet, quiet_config)
    |> register_configuration(:always_bridge, always_bridge_config)
    |> register_configuration(:bridge_verbose, bridge_verbose_config)
  end

  # Resolve strategy configuration to actual strategy modules
  defp resolve_strategy_modules(factory, strategy_config) do
    try do
      resolved_modules =
        Enum.map(strategy_config, fn {strategy_type, strategy_key} ->
          case get_strategy(factory, strategy_type, strategy_key) do
            {:ok, module} -> {strategy_type, module}
            {:error, reason} -> throw({:error, reason})
          end
        end)

      {:ok, Enum.into(resolved_modules, %{})}
    catch
      {:error, reason} -> {:error, reason}
    end
  end

  # Perform actual strategy validation by checking behavior implementation
  defp perform_strategy_validation(strategy_type, strategy_module) do
    try do
      # Check if module exists and is loaded
      unless Code.ensure_loaded?(strategy_module) do
        {:error, "Strategy module #{strategy_module} could not be loaded"}
      else
        # Get expected behavior module for strategy type
        behavior_module = get_behavior_module_for_strategy_type(strategy_type)

        # Check if strategy implements the required behavior
        case validate_behavior_implementation(strategy_module, behavior_module) do
          :ok -> :ok
          {:error, reason} -> {:error, "#{strategy_module} validation failed: #{reason}"}
        end
      end
    rescue
      e ->
        {:error, "Strategy validation error: #{Exception.message(e)}"}
    end
  end

  # Map strategy types to their corresponding behavior modules
  defp get_behavior_module_for_strategy_type(strategy_type) do
    case strategy_type do
      :planning_strategy -> Strategies.PlanningStrategy
      :temporal_strategy -> Strategies.TemporalStrategy
      :state_strategy -> Strategies.StateStrategy
      :domain_strategy -> Strategies.DomainStrategy
      :logging_strategy -> Strategies.LoggingStrategy
      :execution_strategy -> Strategies.ExecutionStrategy
      _ -> nil
    end
  end

  # Validate that a module implements a specific behavior
  defp validate_behavior_implementation(strategy_module, behavior_module) do
    if behavior_module == nil do
      {:error, "Unknown behavior module"}
    else
      # Get required callbacks from behavior module
      required_callbacks = get_behavior_callbacks(behavior_module)

      # Check if all required callbacks are implemented
      missing_callbacks =
        Enum.filter(required_callbacks, fn {function, arity} ->
          not function_exported?(strategy_module, function, arity)
        end)

      if length(missing_callbacks) == 0 do
        :ok
      else
        callback_list = Enum.map(missing_callbacks, fn {f, a} -> "#{f}/#{a}" end)
        {:error, "Missing required callbacks: #{Enum.join(callback_list, ", ")}"}
      end
    end
  end

  # Get required callbacks for each behavior module
  defp get_behavior_callbacks(behavior_module) do
    case behavior_module do
      Strategies.PlanningStrategy ->
        [
          {:plan, 4},
          {:replan, 5},
          {:validate_plan, 3},
          {:strategy_info, 0}
        ]

      Strategies.TemporalStrategy ->
        [
          {:add_temporal_constraints, 3},
          {:validate_temporal_consistency, 2},
          {:update_constraints, 3},
          {:get_temporal_schedule, 2}
        ]

      Strategies.StateStrategy ->
        [
          {:apply_action, 4},
          {:query_state, 3},
          {:create_checkpoint, 3},
          {:rollback_to_checkpoint, 3}
        ]

      Strategies.DomainStrategy ->
        [
          {:get_action_metadata, 3},
          {:get_task_methods, 3},
          {:get_goal_methods, 3},
          {:validate_domain, 2}
        ]

      Strategies.LoggingStrategy ->
        [
          {:log, 4},
          {:log_progress, 3},
          {:log_error, 3},
          {:configure, 2}
        ]

      Strategies.ExecutionStrategy ->
        [
          {:execute_plan, 4},
          {:execute_step, 4},
          {:handle_execution_failure, 4}
        ]

      _ ->
        []
    end
  end
end
