# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaCore do
  @moduledoc """
  Pure specification layer for ADR-181 compliant domain definitions.

  This module provides domain creation, validation, and legacy action conversion
  without any solving or execution logic. As part of ADR-193 layered architecture
  consolidation, AriaCore focuses exclusively on specification and validation.

  ## Usage

      # Domain creation (ADR-181 compliant)
      domain = AriaCore.create_domain(MyApp.CookingDomain)
      
      # Domain validation
      {:ok, validated_domain} = AriaCore.validate_domain(domain)
      
      # Legacy action conversion
      {:ok, converted_actions} = AriaCore.convert_legacy_actions(legacy_actions)
      
      # Entity validation
      :ok = AriaCore.validate_entity_requirements(requirements)
  """

  require Logger

  @type domain :: term()
  @type legacy_action :: map()
  @type entity_requirement :: map()
  @type error_reason :: String.t()

  @doc """
  Create domain from domain module (ADR-181 compliant).

  ## Parameters
  - `domain_module` - Module implementing domain specification

  ## Returns
  - `domain()` - Created domain specification
  """
  @spec create_domain(module()) :: domain()
  def create_domain(domain_module) do
    Logger.info("Creating domain from module: #{inspect(domain_module)}")
    
    # For now, delegate to the domain module's create_base_domain function
    # This will be expanded with full ADR-181 compliance validation
    if function_exported?(domain_module, :create_base_domain, 0) do
      domain_module.create_base_domain()
      |> validate_adr_181_compliance()
    else
      raise ArgumentError, "Domain module #{inspect(domain_module)} must implement create_base_domain/0"
    end
  end

  @doc """
  Validate domain specification (ADR-181 compliant).

  ## Parameters
  - `domain` - Domain specification to validate

  ## Returns
  - `{:ok, domain}` - Successfully validated
  - `{:error, reason}` - Validation failed
  """
  @spec validate_domain(domain()) :: {:ok, domain()} | {:error, error_reason()}
  def validate_domain(domain) do
    Logger.info("Validating domain specification")
    
    # For now, perform basic validation
    # This will be expanded with comprehensive ADR-181 validation
    case validate_adr_181_compliance(domain) do
      %{} = validated_domain -> {:ok, validated_domain}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Convert legacy actions to ADR-181 format.

  ## Parameters
  - `legacy_actions` - List of legacy action specifications

  ## Returns
  - `{:ok, converted_actions}` - Successfully converted
  - `{:error, reason}` - Conversion failed
  """
  @spec convert_legacy_actions([legacy_action()]) :: 
    {:ok, [map()]} | {:error, error_reason()}
  def convert_legacy_actions(legacy_actions) do
    Logger.info("Converting #{length(legacy_actions)} legacy actions to ADR-181 format")
    
    # Delegate to temporal converter
    case AriaCore.TemporalConverter.convert_batch(legacy_actions) do
      {:ok, converted} -> {:ok, converted}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Validate entity requirements and capabilities.

  ## Parameters
  - `requirements` - List of entity requirement specifications

  ## Returns
  - `:ok` - Requirements are valid
  - `{:error, reason}` - Validation failed
  """
  @spec validate_entity_requirements([entity_requirement()]) :: 
    :ok | {:error, error_reason()}
  def validate_entity_requirements(requirements) do
    Logger.info("Validating #{length(requirements)} entity requirements")
    
    # For now, perform basic validation
    # This will be expanded with full entity capability validation
    if is_list(requirements) and Enum.all?(requirements, &is_map/1) do
      :ok
    else
      {:error, "Entity requirements must be a list of maps"}
    end
  end

  @doc """
  Get current AriaCore configuration.

  ## Returns
  - `map()` - Current configuration
  """
  @spec get_config() :: map()
  def get_config do
    %{
      layer: :specification,
      adr_181_compliant: true,
      version: "1.0.0",
      capabilities: [
        :domain_creation,
        :domain_validation,
        :legacy_conversion,
        :entity_validation
      ]
    }
  end

  # Private function to validate ADR-181 compliance
  defp validate_adr_181_compliance(domain) do
    # For now, just return the domain as-is
    # This will be expanded with comprehensive ADR-181 validation:
    # - Entity capabilities and requirements
    # - Action attributes (@action, @command, etc.)
    # - Temporal patterns (9 valid combinations)
    # - Goal format enforcement
    # - Method decomposition validation
    domain
  end
end
