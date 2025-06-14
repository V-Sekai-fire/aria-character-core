# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.DomainProvider do
  @moduledoc """
  Behavior for domain providers in AriaEngine.

  This provides a more idiomatic Elixir approach to domain management
  by using behaviors and explicit configuration rather than runtime registration.
  """

  alias AriaEngine.Domain

  @doc """
  Returns the domain type identifier for this provider.
  """
  @callback domain_type() :: String.t()

  @doc """
  Creates and returns the domain with all its actions and methods.
  """
  @callback create_domain() :: Domain.t()

  @doc """
  Returns whether this domain provider is available.
  Default implementation always returns true.
  """
  @callback available?() :: boolean()

  @optional_callbacks [available?: 0]

  @doc """
  Get all configured domain providers from application environment.
  """
  @spec get_configured_providers() :: [module()]
  def get_configured_providers do
    Application.get_env(:aria_engine, :domain_providers, [])
  end

  @doc """
  Get a domain by type from configured providers.
  """
  @spec get_domain(String.t()) :: {:ok, Domain.t()} | {:error, String.t()}
  def get_domain(domain_type) do
    providers = get_configured_providers()

    provider = Enum.find(providers, fn provider_module ->
      provider_module.domain_type() == domain_type and
      (not function_exported?(provider_module, :available?, 0) or provider_module.available?())
    end)

    case provider do
      nil ->
        {:error, "Domain type '#{domain_type}' not found in configured providers"}
      provider_module ->
        try do
          domain = provider_module.create_domain()
          {:ok, domain}
        rescue
          error ->
            {:error, "Failed to create domain: #{inspect(error)}"}
        end
    end
  end

  @doc """
  List all available domain types from configured providers.
  """
  @spec list_domain_types() :: [String.t()]
  def list_domain_types do
    get_configured_providers()
    |> Enum.filter(fn provider ->
      not function_exported?(provider, :available?, 0) or provider.available?()
    end)
    |> Enum.map(&(&1.domain_type()))
  end
end
