# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule HybridPlanner.StrategyConfig do
  @moduledoc """
  Configuration-based strategy selection and management for the hybrid planner.

  This module provides utilities for loading strategy configurations from various sources:
  - Application configuration files
  - Environment variables
  - Runtime configuration maps
  - JSON/YAML configuration files

  ## Configuration Format

      # config/config.exs
      config :aria_engine, :hybrid_planner,
        default_strategy_config: %{
          planning_strategy: :default,
          temporal_strategy: :stn,
          state_strategy: :statev2,
          domain_strategy: :default,
          logging_strategy: :default,
          execution_strategy: :lazy
        },
        strategy_profiles: %{
          debug: %{
            logging_strategy: :verbose,
            execution_strategy: :eager
          },
          production: %{
            logging_strategy: :quiet,
            execution_strategy: :optimized
          }
        }

  ## Usage

      # Load from application configuration
      {:ok, coordinator} = StrategyConfig.load_coordinator_from_config()
      
      # Load specific profile
      {:ok, coordinator} = StrategyConfig.load_coordinator_from_profile(:debug)
      
      # Load from environment variables
      {:ok, coordinator} = StrategyConfig.load_coordinator_from_env()
      
      # Merge configurations
      config = StrategyConfig.merge_configs(base_config, override_config)
  """

  alias HybridPlanner.{StrategyFactory, HybridCoordinatorV2}
  require Logger

  @type strategy_config :: %{atom() => atom()}
  @type config_source :: :application | :environment | :file | :runtime
  @type profile_name :: atom()

  # Default configuration fallback
  @default_config %{
    planning_strategy: :default,
    temporal_strategy: :stn,
    state_strategy: :statev2,
    domain_strategy: :default,
    logging_strategy: :default,
    execution_strategy: :lazy
  }

  # Environment variable mappings
  @env_mappings %{
    planning_strategy: "ARIA_PLANNING_STRATEGY",
    temporal_strategy: "ARIA_TEMPORAL_STRATEGY",
    state_strategy: "ARIA_STATE_STRATEGY",
    domain_strategy: "ARIA_DOMAIN_STRATEGY",
    logging_strategy: "ARIA_LOGGING_STRATEGY",
    execution_strategy: "ARIA_EXECUTION_STRATEGY"
  }

  # ==================== COORDINATOR LOADING ====================

  @doc """
  Load a hybrid coordinator from application configuration.
  """
  @spec load_coordinator_from_config(keyword()) ::
          {:ok, HybridCoordinatorV2.t()} | {:error, String.t()}
  def load_coordinator_from_config(opts \\ []) do
    profile = Keyword.get(opts, :profile, :default)
    factory_opts = Keyword.get(opts, :factory_opts, [])
    coordinator_opts = Keyword.get(opts, :coordinator_opts, [])

    with {:ok, config} <- load_config_from_application(profile),
         {:ok, factory} <- create_factory_with_config(factory_opts),
         {:ok, coordinator} <-
           StrategyFactory.create_coordinator(factory, config, coordinator_opts) do
      {:ok, coordinator}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Load a hybrid coordinator from a specific profile.
  """
  @spec load_coordinator_from_profile(profile_name(), keyword()) ::
          {:ok, HybridCoordinatorV2.t()} | {:error, String.t()}
  def load_coordinator_from_profile(profile_name, opts \\ []) do
    opts_with_profile = Keyword.put(opts, :profile, profile_name)
    load_coordinator_from_config(opts_with_profile)
  end

  @doc """
  Load a hybrid coordinator from environment variables.
  """
  @spec load_coordinator_from_env(keyword()) ::
          {:ok, HybridCoordinatorV2.t()} | {:error, String.t()}
  def load_coordinator_from_env(opts \\ []) do
    factory_opts = Keyword.get(opts, :factory_opts, [])
    coordinator_opts = Keyword.get(opts, :coordinator_opts, [])

    with {:ok, config} <- load_config_from_environment(),
         {:ok, factory} <- create_factory_with_config(factory_opts),
         {:ok, coordinator} <-
           StrategyFactory.create_coordinator(factory, config, coordinator_opts) do
      {:ok, coordinator}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Load a hybrid coordinator from a configuration file.
  """
  @spec load_coordinator_from_file(String.t(), keyword()) ::
          {:ok, HybridCoordinatorV2.t()} | {:error, String.t()}
  def load_coordinator_from_file(config_file_path, opts \\ []) do
    factory_opts = Keyword.get(opts, :factory_opts, [])
    coordinator_opts = Keyword.get(opts, :coordinator_opts, [])

    with {:ok, config} <- load_config_from_file(config_file_path),
         {:ok, factory} <- create_factory_with_config(factory_opts),
         {:ok, coordinator} <-
           StrategyFactory.create_coordinator(factory, config, coordinator_opts) do
      {:ok, coordinator}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # ==================== CONFIGURATION LOADING ====================

  @doc """
  Load strategy configuration from application configuration.
  """
  @spec load_config_from_application(profile_name()) ::
          {:ok, strategy_config()} | {:error, String.t()}
  def load_config_from_application(profile \\ :default) do
    try do
      # Load base configuration
      base_config =
        Application.get_env(:aria_engine, :hybrid_planner, %{})
        |> Map.get(:default_strategy_config, @default_config)

      # Apply profile overrides if requested
      final_config =
        if profile != :default do
          profile_overrides =
            Application.get_env(:aria_engine, :hybrid_planner, %{})
            |> Map.get(:strategy_profiles, %{})
            |> Map.get(profile, %{})

          merge_configs(base_config, profile_overrides)
        else
          base_config
        end

      {:ok, final_config}
    rescue
      e ->
        {:error, "Failed to load application configuration: #{Exception.message(e)}"}
    end
  end

  @doc """
  Load strategy configuration from environment variables.
  """
  @spec load_config_from_environment() :: {:ok, strategy_config()} | {:error, String.t()}
  def load_config_from_environment() do
    try do
      # Start with default configuration
      base_config = @default_config

      # Override with environment variables where present
      env_overrides =
        Enum.reduce(@env_mappings, %{}, fn {strategy_type, env_var}, acc ->
          case System.get_env(env_var) do
            nil -> acc
            value -> Map.put(acc, strategy_type, String.to_atom(value))
          end
        end)

      final_config = merge_configs(base_config, env_overrides)
      {:ok, final_config}
    rescue
      e ->
        {:error, "Failed to load environment configuration: #{Exception.message(e)}"}
    end
  end

  @doc """
  Load strategy configuration from a JSON or YAML file.
  """
  @spec load_config_from_file(String.t()) :: {:ok, strategy_config()} | {:error, String.t()}
  def load_config_from_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        parse_config_content(content, Path.extname(file_path))

      {:error, reason} ->
        {:error, "Failed to read config file #{file_path}: #{reason}"}
    end
  end

  # ==================== CONFIGURATION MANIPULATION ====================

  @doc """
  Merge two strategy configurations, with the second taking precedence.
  """
  @spec merge_configs(strategy_config(), strategy_config()) :: strategy_config()
  def merge_configs(base_config, override_config) do
    Map.merge(base_config, override_config)
  end

  @doc """
  Validate that a strategy configuration is complete and properly formatted.
  """
  @spec validate_config(strategy_config()) :: :ok | {:error, String.t()}
  def validate_config(config) when is_map(config) do
    required_strategies = [
      :planning_strategy,
      :temporal_strategy,
      :state_strategy,
      :domain_strategy,
      :logging_strategy,
      :execution_strategy
    ]

    missing_strategies =
      Enum.filter(required_strategies, fn strategy ->
        not Map.has_key?(config, strategy)
      end)

    invalid_values =
      Enum.filter(config, fn {_key, value} ->
        not is_atom(value)
      end)

    cond do
      length(missing_strategies) > 0 ->
        {:error, "Missing required strategies: #{inspect(missing_strategies)}"}

      length(invalid_values) > 0 ->
        {:error, "Invalid strategy values (must be atoms): #{inspect(invalid_values)}"}

      true ->
        :ok
    end
  end

  def validate_config(_config) do
    {:error, "Configuration must be a map"}
  end

  @doc """
  Get the default strategy configuration.
  """
  @spec get_default_config() :: strategy_config()
  def get_default_config(), do: @default_config

  @doc """
  Create a strategy configuration with specific overrides.
  """
  @spec create_config(keyword()) :: strategy_config()
  def create_config(overrides \\ []) do
    override_map = Enum.into(overrides, %{})
    merge_configs(@default_config, override_map)
  end

  # ==================== PROFILE MANAGEMENT ====================

  @doc """
  List all available strategy profiles from application configuration.
  """
  @spec list_profiles() :: [profile_name()]
  def list_profiles() do
    Application.get_env(:aria_engine, :hybrid_planner, %{})
    |> Map.get(:strategy_profiles, %{})
    |> Map.keys()
  end

  @doc """
  Get configuration for a specific profile.
  """
  @spec get_profile_config(profile_name()) :: {:ok, strategy_config()} | {:error, String.t()}
  def get_profile_config(profile_name) do
    profiles =
      Application.get_env(:aria_engine, :hybrid_planner, %{})
      |> Map.get(:strategy_profiles, %{})

    case Map.get(profiles, profile_name) do
      nil ->
        {:error, "Profile not found: #{profile_name}"}

      profile_config ->
        base_config = @default_config
        final_config = merge_configs(base_config, profile_config)
        {:ok, final_config}
    end
  end

  # ==================== ADAPTIVE CONFIGURATION ====================

  @doc """
  Create an adaptive configuration based on runtime conditions.
  """
  @spec create_adaptive_config(keyword()) :: strategy_config()
  def create_adaptive_config(opts \\ []) do
    # Determine environment
    env = Keyword.get(opts, :environment, get_runtime_environment())

    # Determine performance requirements
    performance_level = Keyword.get(opts, :performance, get_performance_requirements())

    # Determine logging needs
    debug_level = Keyword.get(opts, :debug, get_debug_level())

    # Start with base configuration
    base_config = @default_config

    # Apply environment-specific adaptations
    env_config =
      case env do
        :development -> %{logging_strategy: :verbose}
        :test -> %{logging_strategy: :quiet, execution_strategy: :deterministic}
        :production -> %{logging_strategy: :quiet, execution_strategy: :optimized}
        _ -> %{}
      end

    # Apply performance adaptations
    perf_config =
      case performance_level do
        :high -> %{execution_strategy: :optimized, temporal_strategy: :fast_stn}
        :normal -> %{}
        :debug -> %{execution_strategy: :step_by_step}
        _ -> %{}
      end

    # Apply debug level adaptations
    debug_config =
      case debug_level do
        :verbose -> %{logging_strategy: :verbose}
        :normal -> %{}
        :quiet -> %{logging_strategy: :quiet}
        _ -> %{}
      end

    # Merge all configurations
    base_config
    |> merge_configs(env_config)
    |> merge_configs(perf_config)
    |> merge_configs(debug_config)
  end

  # ==================== PRIVATE HELPER FUNCTIONS ====================

  # Create a strategy factory with default strategies loaded
  defp create_factory_with_config(opts) do
    try do
      factory = StrategyFactory.new(opts)
      {:ok, factory}
    rescue
      e ->
        {:error, "Failed to create strategy factory: #{Exception.message(e)}"}
    end
  end

  # Parse configuration content based on file extension
  defp parse_config_content(content, ".json") do
    case Jason.decode(content) do
      {:ok, data} ->
        config = atomize_keys(data)

        case validate_config(config) do
          :ok -> {:ok, config}
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, "JSON parsing failed: #{inspect(reason)}"}
    end
  end

  defp parse_config_content(content, ".yaml") do
    # TODO: Add YamlElixir dependency or implement alternative YAML parsing
    Logger.warning("StrategyConfig: YamlElixir dependency not available, using JSON fallback")

    case Jason.decode(content) do
      {:ok, data} ->
        config = atomize_keys(data)

        case validate_config(config) do
          :ok -> {:ok, config}
          {:error, reason} -> {:error, reason}
        end

      {:error, reason} ->
        {:error, "YAML parsing failed: #{inspect(reason)}"}
    end
  end

  defp parse_config_content(_content, ext) do
    {:error, "Unsupported configuration file format: #{ext}"}
  end

  # Convert string keys to atoms recursively
  defp atomize_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      atom_key = if is_binary(key), do: String.to_atom(key), else: key
      atom_value = if is_binary(value), do: String.to_atom(value), else: value
      Map.put(acc, atom_key, atom_value)
    end)
  end

  defp atomize_keys(value), do: value

  # Get current runtime environment
  defp get_runtime_environment() do
    Mix.env() || Application.get_env(:aria_engine, :environment, :development)
  end

  # Determine performance requirements based on system resources
  defp get_performance_requirements() do
    # This could be enhanced with actual system monitoring
    # For now, return a sensible default
    :normal
  end

  # Determine appropriate debug level
  defp get_debug_level() do
    case get_runtime_environment() do
      :development -> :verbose
      :test -> :quiet
      :production -> :quiet
      _ -> :normal
    end
  end
end
