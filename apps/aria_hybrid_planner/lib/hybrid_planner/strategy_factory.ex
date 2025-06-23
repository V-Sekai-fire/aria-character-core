# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.StrategyFactory do
  @moduledoc "Factory and registry for creating and managing hybrid planner strategies.\n\nThis module provides centralized strategy management including:\n- Strategy registration and lookup\n- Dynamic strategy composition\n- Configuration-based strategy selection\n- Runtime strategy validation and swapping\n\n## Usage\n\n    # Register strategies\n    factory = StrategyFactory.new()\n    |> StrategyFactory.register_strategy(:planning, :default, \n         HybridPlanner.Strategies.Default.HTNPlanningStrategy)\n    |> StrategyFactory.register_strategy(:planning, :optimized,\n         HybridPlanner.Strategies.Optimized.HTNPlanningStrategy)\n    \n    # Create coordinator from configuration\n    config = %{\n      planning_strategy: :default,\n      temporal_strategy: :stn,\n      state_strategy: :statev2,\n      domain_strategy: :default,\n      logging_strategy: :verbose,\n      execution_strategy: :lazy\n    }\n    \n    coordinator = StrategyFactory.create_coordinator(factory, config)\n    \n    # Runtime strategy swapping\n    new_coordinator = StrategyFactory.swap_strategy(coordinator, :planning, :optimized)\n"
  alias HybridPlanner.{HybridCoordinatorV2, Strategies}
  defstruct [:strategies, :configurations, :metadata]

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
          metadata: map()
        }
  @doc "Create a new strategy factory with default strategies registered.\n"
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
      metadata: %{created_at: System.system_time(:millisecond), options: opts}
    }

    factory |> register_default_strategies() |> register_default_configurations()
  end

  @doc "Register a strategy implementation for a given type and key.\n"
  @spec register_strategy(t(), strategy_type(), strategy_key(), strategy_module()) :: t()
  def register_strategy(%__MODULE__{} = factory, strategy_type, strategy_key, strategy_module) do
    current_strategies = Map.get(factory.strategies, strategy_type, %{})
    updated_strategy_map = Map.put(current_strategies, strategy_key, strategy_module)
    updated_strategies = Map.put(factory.strategies, strategy_type, updated_strategy_map)
    %{factory | strategies: updated_strategies}
  end

  @doc "Register multiple strategies at once.\n"
  @spec register_strategies(t(), [{strategy_type(), strategy_key(), strategy_module()}]) :: t()
  def register_strategies(%__MODULE__{} = factory, strategy_list) do
    Enum.reduce(strategy_list, factory, fn {type, key, module}, acc ->
      register_strategy(acc, type, key, module)
    end)
  end

  @doc "Get a registered strategy by type and key.\n"
  @spec get_strategy(t(), strategy_type(), strategy_key()) ::
          {:ok, strategy_module()} | {:error, String.t()}
  def get_strategy(%__MODULE__{} = factory, strategy_type, strategy_key) do
    case get_in(factory.strategies, [strategy_type, strategy_key]) do
      nil -> {:error, "Strategy not found: #{strategy_type}:#{strategy_key}"}
      module -> {:ok, module}
    end
  end

  @doc "List all registered strategies for a given type.\n"
  @spec list_strategies(t(), strategy_type()) :: [strategy_key()]
  def list_strategies(%__MODULE__{} = factory, strategy_type) do
    factory.strategies |> Map.get(strategy_type, %{}) |> Map.keys()
  end

  @doc "Register a named strategy configuration.\n"
  @spec register_configuration(t(), atom(), strategy_config()) :: t()
  def register_configuration(%__MODULE__{} = factory, config_name, strategy_config) do
    case validate_strategy_configuration(factory, strategy_config) do
      :ok -> :ok
      {:error, reason} -> raise ArgumentError, "Configuration validation failed: #{reason}"
    end

    updated_configurations = Map.put(factory.configurations, config_name, strategy_config)
    %{factory | configurations: updated_configurations}
  end

  @doc "Get a registered configuration by name.\n"
  @spec get_configuration(t(), atom()) :: {:ok, strategy_config()} | {:error, String.t()}
  def get_configuration(%__MODULE__{} = factory, config_name) do
    case Map.get(factory.configurations, config_name) do
      nil -> {:error, "Configuration not found: #{config_name}"}
      config -> {:ok, config}
    end
  end

  @doc "List all registered configurations.\n"
  @spec list_configurations(t()) :: [atom()]
  def list_configurations(%__MODULE__{} = factory) do
    Map.keys(factory.configurations)
  end

  @doc "Create a hybrid coordinator from a strategy configuration.\n"
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
      case resolve_strategy_modules(factory, strategy_config) do
        {:ok, strategy_modules} ->
          coordinator = HybridCoordinatorV2.new(strategy_modules, opts)
          {:ok, coordinator}

        {:error, reason} ->
          {:error, reason}
      end
    rescue
      e -> {:error, "Coordinator creation failed: #{Exception.message(e)}"}
    end
  end

  @doc "Create a coordinator with default configuration.\n"
  @spec create_default_coordinator(t(), keyword()) :: HybridCoordinatorV2.t()
  def create_default_coordinator(%__MODULE__{} = factory, opts \\ []) do
    case create_coordinator(factory, :default, opts) do
      {:ok, coordinator} -> coordinator
      {:error, reason} -> raise "Failed to create default coordinator: #{reason}"
    end
  end

  @doc "Swap a strategy in an existing coordinator.\n"
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

  @doc "Create a new coordinator by modifying an existing configuration.\n"
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

  @doc "Compose multiple strategy configurations into a new configuration.\n"
  @spec compose_configurations(t(), [atom()], atom()) :: {:ok, t()} | {:error, String.t()}
  def compose_configurations(%__MODULE__{} = factory, config_names, new_config_name) do
    try do
      configs =
        Enum.map(config_names, fn name ->
          case get_configuration(factory, name) do
            {:ok, config} -> config
            {:error, reason} -> throw({:error, reason})
          end
        end)

      composed_config = Enum.reduce(configs, %{}, &Map.merge/2)

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

  @doc "Validate that a strategy configuration is complete and valid.\n"
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

    missing_strategies =
      required_strategies
      |> Enum.filter(fn strategy_type -> not Map.has_key?(strategy_config, strategy_type) end)

    if length(missing_strategies) > 0 do
      {:error, "Missing required strategies: #{inspect(missing_strategies)}"}
    else
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

  defp register_default_strategies(factory) do
    default_strategies = [
      {:planning_strategy, :default, Strategies.Default.HTNPlanningStrategy},
      {:temporal_strategy, :stn, Strategies.Default.STNTemporalStrategy},
      {:state_strategy, :statev2, Strategies.Default.StateV2Strategy},
      {:domain_strategy, :default, Strategies.Default.DomainStrategy},
      {:logging_strategy, :default, Strategies.Default.LoggerStrategy},
      {:logging_strategy, :verbose, Strategies.Default.LoggerStrategy},
      {:logging_strategy, :quiet, Strategies.Default.LoggerStrategy},
      {:execution_strategy, :lazy, Strategies.Default.LazyExecutionStrategy}
    ]

    register_strategies(factory, default_strategies)
  end

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

    factory
    |> register_configuration(:default, default_config)
    |> register_configuration(:verbose, verbose_config)
    |> register_configuration(:quiet, quiet_config)
  end

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
end