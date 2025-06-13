# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.DomainRegistry do
  @moduledoc """
  Registry for managing different types of domains in AriaEngine.

  This module provides a clean separation between the core planner and
  domain-specific functionality. It manages:

  - Domain registration and lookup
  - Domain composition and inheritance
  - Domain validation
  - Domain interface standardization

  Domains are organized by type (e.g., "file_management", "workflow_system")
  and can be composed together to create complex planning capabilities.
  """

  alias AriaEngine.{Domain, Planner}

  @domains_table :aria_domains_registry

  # Registry types
  @type domain_type :: String.t()
  @type domain_registry :: %{domain_type() => Domain.t()}
  @type composition_spec :: %{
    base_domains: [domain_type()],
    additional_actions: %{atom() => function()},
    additional_methods: %{String.t() => [function()]},
    overrides: %{String.t() => any()}
  }

  @doc """
  Get a domain by type from the registry.

  ## Parameters
  - `domain_type`: Type of domain to retrieve

  ## Returns
  - `{:ok, domain}`: Domain found
  - `{:error, reason}`: Domain not found or invalid
  """
  @spec get_domain(domain_type()) :: {:ok, Domain.t()} | {:error, String.t()}
  def get_domain(domain_type) do
    case :ets.lookup(@domains_table, domain_type) do
      [{^domain_type, domain}] -> {:ok, domain}
      [] ->
        # Try to dynamically load domain from available modules
        case try_load_domain(domain_type) do
          {:ok, domain} ->
            :ets.insert(@domains_table, {domain_type, domain})
            {:ok, domain}
          error -> error
        end
    end
  end

  @doc """
  List all available domain types.

  ## Returns
  List of available domain type strings
  """
  @spec list_domain_types() :: [domain_type()]
  def list_domain_types do
    [
      "file_management",
      "workflow_system",
      "timestrike",
      "basic_actions"
    ]
  end

  @doc """
  Compose multiple domains into a single domain.

  This allows combining capabilities from different domains while
  maintaining clean separation of concerns.

  ## Parameters
  - `composition_spec`: Specification for domain composition

  ## Returns
  - `{:ok, composed_domain}`: Successfully composed domain
  - `{:error, reason}`: Composition failed
  """
  @spec compose_domains(composition_spec()) :: {:ok, Domain.t()} | {:error, String.t()}
  def compose_domains(spec) do
    base_domains = Map.get(spec, :base_domains, [])
    additional_actions = Map.get(spec, :additional_actions, %{})
    additional_methods = Map.get(spec, :additional_methods, %{})
    overrides = Map.get(spec, :overrides, %{})

    # Get all base domains
    case get_base_domains(base_domains) do
      {:ok, domains} ->
        # Merge domains
        composed = merge_domains(domains)

        # Apply additional actions and methods
        enhanced = enhance_domain(composed, additional_actions, additional_methods)

        # Apply overrides
        final = apply_overrides(enhanced, overrides)

        {:ok, final}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Create a domain interface suitable for the planner.

  This converts a Domain struct to the interface format expected
  by AriaEngine.Planner.

  ## Parameters
  - `domain`: Domain to convert

  ## Returns
  Domain interface map
  """
  @spec create_planner_interface(Domain.t()) :: Planner.domain_interface()
  def create_planner_interface(%Domain{} = domain) do
    Planner.domain_to_interface(domain)
  end

  @doc """
  Validate that a domain has all required capabilities.

  ## Parameters
  - `domain`: Domain to validate
  - `required_actions`: List of required action names
  - `required_methods`: List of required method names

  ## Returns
  - `:ok`: Domain is valid
  - `{:error, missing_capabilities}`: Domain is missing required capabilities
  """
  @spec validate_domain(Domain.t(), [atom()], [String.t()]) :: :ok | {:error, [String.t()]}
  def validate_domain(%Domain{} = domain, required_actions \\ [], required_methods \\ []) do
    missing_actions = Enum.reject(required_actions, &Domain.has_action?(domain, &1))
    missing_methods = Enum.reject(required_methods, &Domain.has_task_methods?(domain, &1))

    case {missing_actions, missing_methods} do
      {[], []} ->
        :ok

      {missing_a, missing_m} ->
        missing = []
        missing = if missing_a != [], do: ["Missing actions: #{inspect(missing_a)}" | missing], else: missing
        missing = if missing_m != [], do: ["Missing methods: #{inspect(missing_m)}" | missing], else: missing
        {:error, missing}
    end
  end

  # Private helper functions

  # Get base domains from the registry
  @spec get_base_domains([domain_type()]) :: {:ok, [Domain.t()]} | {:error, String.t()}
  defp get_base_domains(domain_types) do
    domains =
      domain_types
      |> Enum.map(&get_domain/1)
      |> Enum.reduce_while([], fn
        {:ok, domain}, acc -> {:cont, [domain | acc]}
        {:error, reason}, _acc -> {:halt, {:error, reason}}
      end)

    case domains do
      {:error, reason} -> {:error, reason}
      domain_list when is_list(domain_list) -> {:ok, Enum.reverse(domain_list)}
    end
  end

  # Merge multiple domains into one
  @spec merge_domains([Domain.t()]) :: Domain.t()
  defp merge_domains([single_domain]) do
    single_domain
  end

  defp merge_domains([first | rest]) do
    Enum.reduce(rest, first, fn domain, acc ->
      %Domain{
        name: "#{acc.name}_#{domain.name}",
        actions: Map.merge(acc.actions, domain.actions),
        task_methods: merge_task_methods(acc.task_methods, domain.task_methods),
        unigoal_methods: merge_unigoal_methods(acc.unigoal_methods, domain.unigoal_methods),
        multigoal_methods: acc.multigoal_methods ++ domain.multigoal_methods
      }
    end)
  end

  # Merge task methods from multiple domains
  @spec merge_task_methods(%{String.t() => [function()]}, %{String.t() => [function()]}) :: %{String.t() => [function()]}
  defp merge_task_methods(methods1, methods2) do
    Map.merge(methods1, methods2, fn _key, list1, list2 -> list1 ++ list2 end)
  end

  # Merge unigoal methods from multiple domains
  @spec merge_unigoal_methods(%{String.t() => [function()]}, %{String.t() => [function()]}) :: %{String.t() => [function()]}
  defp merge_unigoal_methods(methods1, methods2) do
    Map.merge(methods1, methods2, fn _key, list1, list2 -> list1 ++ list2 end)
  end

  # Add additional actions and methods to a domain
  @spec enhance_domain(Domain.t(), %{atom() => function()}, %{String.t() => [function()]}) :: Domain.t()
  defp enhance_domain(%Domain{} = domain, additional_actions, additional_methods) do
    enhanced = Domain.add_actions(domain, additional_actions)

    Enum.reduce(additional_methods, enhanced, fn {method_name, method_fns}, acc ->
      Domain.add_task_methods(acc, method_name, method_fns)
    end)
  end

  # Apply overrides to a domain
  @spec apply_overrides(Domain.t(), %{String.t() => any()}) :: Domain.t()
  defp apply_overrides(%Domain{} = domain, overrides) do
    Enum.reduce(overrides, domain, fn {key, value}, acc ->
      case key do
        "name" -> %{acc | name: value}
        _ -> acc  # Ignore unknown overrides
      end
    end)
  end

  # Create a basic actions domain with core actions
  @spec create_basic_actions_domain() :: Domain.t()
  defp create_basic_actions_domain do
    alias AriaEngine.Actions

    Domain.new("basic_actions")
    |> Domain.add_actions(%{
      execute_command: &Actions.execute_command/2,
      echo: &Actions.echo/2,
      wait: &Actions.wait/2,
      set_env_var: &Actions.set_env_var/2
    })
  end

  # Private helper to try loading domain dynamically
  @spec try_load_domain(String.t()) :: {:ok, Domain.t()} | {:error, String.t()}
  defp try_load_domain(domain_type) do
    case domain_type do
      "file_management" ->
        try do
          {:ok, AriaFileManagement.create_domain()}
        rescue
          UndefinedFunctionError -> {:error, "AriaFileManagement module not available"}
          error -> {:error, "Failed to load file_management domain: #{inspect(error)}"}
        end
      "workflow_system" ->
        try do
          {:ok, AriaWorkflowSystem.create_domain()}
        rescue
          UndefinedFunctionError -> {:error, "AriaWorkflowSystem module not available"}
          error -> {:error, "Failed to load workflow_system domain: #{inspect(error)}"}
        end
      "timestrike" ->
        try do
          {:ok, AriaTimestrike.create_domain()}
        rescue
          UndefinedFunctionError -> {:error, "AriaTimestrike module not available"}
          error -> {:error, "Failed to load timestrike domain: #{inspect(error)}"}
        end
      "basic_actions" ->
        {:ok, create_basic_actions_domain()}
      _ ->
        {:error, "Unknown domain type: #{domain_type}"}
    end
  end

  @doc """
  Initialize the domain registry ETS table.
  """
  @spec init() :: :ok
  def init do
    case :ets.whereis(@domains_table) do
      :undefined ->
        :ets.new(@domains_table, [:named_table, :public, :set, {:read_concurrency, true}])
        :ok
      _ ->
        :ok
    end
  end
end
