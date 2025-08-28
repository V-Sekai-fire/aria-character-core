# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.ActionAttributes.Registry do
  @moduledoc """
  Registry creation functions for AriaCore.ActionAttributes.

  This module handles creating entity registries and temporal specifications
  from action metadata, leveraging existing AriaCore systems.
  """

  @doc """
  Creates entity registry from action metadata.

  SOCIABLE APPROACH: Leverages existing AriaCore.Entity.Management system.
  """
  def create_entity_registry(action_metadata) do
    # Filter out non-map metadata (e.g., `true` for @action true)
    filtered_metadata = Enum.filter(action_metadata, fn {_name, metadata} -> is_map(metadata) end)

    # Extract all entity requirements from actions
    all_requirements =
      filtered_metadata
      |> Enum.flat_map(fn {_name, metadata} ->
        metadata[:requires_entities] || []
      end)
      |> Enum.uniq()

    # LEVERAGE existing entity system (no rewrite needed)
    registry = AriaCore.Entity.Management.new_registry()

    Enum.reduce(all_requirements, registry, fn requirement, acc ->
      AriaCore.Entity.Management.register_entity_type(acc, requirement)
    end)
  end

  @doc """
  Creates temporal specifications from action metadata.

  SOCIABLE APPROACH: Leverages existing AriaCore.Temporal.Interval system.
  """
  def create_temporal_specifications(action_metadata) do
    # Filter out non-map metadata (e.g., `true` for @action true)
    filtered_metadata = Enum.filter(action_metadata, fn {_name, metadata} -> is_map(metadata) end)

    # Extract all duration specifications
    duration_specs =
      filtered_metadata
      |> Enum.map(fn {name, metadata} ->
        {name, convert_duration(metadata[:duration])}
      end)
      |> Enum.into(%{})

    # LEVERAGE existing temporal system (no rewrite needed)
    specs = AriaCore.Temporal.Interval.new_specifications()

    Enum.reduce(duration_specs, specs, fn {action_name, duration}, acc ->
      AriaCore.Temporal.Interval.add_action_duration(acc, action_name, duration)
    end)
  end

  # Private helper functions

  defp convert_duration(duration) when is_binary(duration) do
    # Convert ISO 8601 duration to internal format
    # LEVERAGE existing temporal parsing (sociable approach)
    AriaCore.Temporal.Interval.parse_iso8601(duration)
  end

  defp convert_duration(duration) when is_integer(duration) do
    # Convert seconds to internal format
    AriaCore.Temporal.Interval.fixed(duration)
  end

  defp convert_duration(nil) do
    # Default duration if not specified
    AriaCore.Temporal.Interval.fixed(1)
  end
end
