defmodule AriaEngine.Domain do
  @moduledoc """
  Facade module for AriaEngine Domain.

  This module serves as the primary interface for defining planning domains
  in AriaEngine, as specified in ADR R25W1398085. It delegates to
  `AriaEngineCore.Domain` and `AriaCore.Domain` for underlying functionality.
  """

  alias AriaEngineCore.Domain
  alias AriaCore.Domain, as: AriaCoreDomain

  @doc """
  Creates a new planning domain.
  """
  @spec new(String.t()) :: Domain.t()
  def new(name \\ "default") do
    Domain.new(name)
  end

  @doc """
  Adds an action to the domain.
  """
  @spec add_action(Domain.t(), atom(), any(), map()) :: Domain.t()
  def add_action(domain, name, action_fn, metadata \\ %{}) do
    Domain.add_action(domain, name, action_fn, metadata)
  end

  @doc """
  Adds task methods to the domain.
  """
  @spec add_task_methods(Domain.t(), String.t(), list()) :: Domain.t()
  def add_task_methods(domain, task_name, method_tuples_or_functions) do
    Domain.add_task_methods(domain, task_name, method_tuples_or_functions)
  end

  @doc """
  Adds a unigoal method to the domain.
  """
  @spec add_unigoal_method(Domain.t(), String.t(), String.t(), any()) :: Domain.t()
  def add_unigoal_method(domain, goal_type, method_name, method_fn) do
    Domain.add_unigoal_method(domain, goal_type, method_name, method_fn)
  end

  @doc """
  Adds a multigoal method to the domain.
  """
  @spec add_multigoal_method(Domain.t(), String.t(), any()) :: Domain.t()
  def add_multigoal_method(domain, method_name, method_fn) do
    Domain.add_multigoal_method(domain, method_name, method_fn)
  end

  @doc """
  Adds a multitodo method to the domain.
  """
  @spec add_multitodo_method(Domain.t(), String.t(), any()) :: Domain.t()
  def add_multitodo_method(domain, method_name, method_fn) do
    Domain.add_multitodo_method(domain, method_name, method_fn)
  end

  @doc """
  Enables domain definition using attributes.
  """
  defmacro __using__(_opts) do
    quote do
      use AriaCore.Domain # Leverage AriaCore's attribute processing
      alias AriaEngine.Domain # Ensure this module is available
    end
  end

  @doc """
  Creates a domain from a module that uses @action and @task_method attributes.
  """
  @spec create_from_module(module()) :: Domain.t()
  def create_from_module(domain_module) do
    AriaCoreDomain.create_from_module(domain_module)
  end

  @doc """
  Merges multiple domains into a single unified domain.
  """
  @spec merge_domains(list(), list()) :: Domain.t()
  def merge_domains(domains, options \\ []) do
    AriaCoreDomain.merge_domains(domains, options)
  end

  @doc """
  Validates a domain module.
  """
  @spec validate_domain_module(module()) :: :ok | {:error, String.t()}
  def validate_domain_module(domain_module) do
    AriaCoreDomain.validate_domain_module(domain_module)
  end

  @doc """
  Gets comprehensive information about a domain module.
  """
  @spec get_domain_info(module()) :: map()
  def get_domain_info(domain_module) do
    AriaCoreDomain.get_domain_info(domain_module)
  end

  @doc """
  Creates a domain registry for managing multiple domains.
  """
  @spec create_domain_registry(list()) :: map()
  def create_domain_registry(domain_modules) do
    AriaCoreDomain.create_domain_registry(domain_modules)
  end
end
