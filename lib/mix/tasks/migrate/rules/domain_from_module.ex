# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.Rules.DomainFromModule do
  @moduledoc """
  Rule for migrating Domain.from_module calls to direct build() calls.

  Single responsibility: Define transformation logic for replacing deprecated
  Domain.from_module/1 calls with direct calls to the domain module's build/0 function.
  """


  @doc """
  Check if content needs Domain.from_module transformation.
  """
  @spec needs_transformation?(String.t()) :: boolean()
  def needs_transformation?(source_code) do
    String.contains?(source_code, "Domain.from_module(")
  end

  @doc """
  Get transformation rules for Domain.from_module migration.
  """
  @spec transformation_rules() :: [function()]
  def transformation_rules do
    [domain_from_module_rule()]
  end

  # Private functions

  defp domain_from_module_rule do
    fn ast_node ->
      case ast_node do
        # Match: AriaEngine.Domain.from_module(AriaEngine.SoftwareDevelopment.Domain)
        {{:., meta, [{:__aliases__, _alias_meta, [:AriaEngine, :Domain]}, :from_module]},
         call_meta, [{:__aliases__, domain_alias_meta, domain_module_path}]}
        when is_list(domain_module_path) ->
          # Replace with: DomainModule.build()
          {{:., meta, [{:__aliases__, domain_alias_meta, domain_module_path}, :build]}, call_meta,
           []}

        # Match: Domain.from_module(SomeDomain) when Domain is aliased
        {{:., meta, [{:__aliases__, _alias_meta, [:Domain]}, :from_module]}, call_meta,
         [{:__aliases__, domain_alias_meta, domain_module_path}]}
        when is_list(domain_module_path) ->
          # Replace with: DomainModule.build()
          {{:., meta, [{:__aliases__, domain_alias_meta, domain_module_path}, :build]}, call_meta,
           []}

        _ ->
          ast_node
      end
    end
  end
end
