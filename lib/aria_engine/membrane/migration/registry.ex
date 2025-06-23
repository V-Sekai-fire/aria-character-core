# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Migration.Registry do
  @moduledoc """
  Registry for Membrane-based migration transformation rules.

  This module manages the catalog of available transformation rules as Membrane bins,
  their metadata, dependencies, and discovery.
  """

  alias AriaEngine.Membrane.Migration.Rules.{
    DatetimeStringFixBin,
    IntervalConstructorFixBin,
    DomainFromModuleBin,
    LoggerConversionBin,
    GoalTuplesBin,
    DebugDatetimeBin
  }

  @type rule_metadata :: %{
    name: atom(),
    description: String.t(),
    category: atom(),
    bin_module: module(),
    detection_fn: function(),
    dependencies: [atom()]
  }

  @doc """
  List all available transformation rules with their Membrane bin modules.
  """
  @spec list_rules() :: [rule_metadata()]
  def list_rules do
    [
      # API migrations
      %{
        name: :domain_from_module,
        description: "Replace Domain.from_module calls with direct build() calls",
        category: :api_migration,
        bin_module: DomainFromModuleBin,
        detection_fn: &domain_from_module_detection/1,
        dependencies: []
      },

      # Format migrations
      %{
        name: :goal_tuples,
        description: "Fix goal tuple ordering from {subject, predicate, object} to {predicate, subject, object}",
        category: :format_migration,
        bin_module: GoalTuplesBin,
        detection_fn: &goal_tuples_detection/1,
        dependencies: []
      },

      # Refactoring
      %{
        name: :logger_conversion,
        description: "Convert IO.puts calls to appropriate Logger calls",
        category: :refactoring,
        bin_module: LoggerConversionBin,
        detection_fn: &logger_conversion_detection/1,
        dependencies: []
      },

      # Bug fixes
      %{
        name: :datetime_string_fix,
        description: "Fix DateTime.to_iso8601 calls with string arguments",
        category: :bug_fix,
        bin_module: DatetimeStringFixBin,
        detection_fn: &datetime_string_fix_detection/1,
        dependencies: []
      },

      %{
        name: :interval_constructor_fix,
        description: "Fix Interval.new_fixed_schedule calls missing end time parameters",
        category: :bug_fix,
        bin_module: IntervalConstructorFixBin,
        detection_fn: &interval_constructor_fix_detection/1,
        dependencies: []
      },

      # Debug
      %{
        name: :debug_datetime,
        description: "Debug DateTime AST patterns",
        category: :debug,
        bin_module: DebugDatetimeBin,
        detection_fn: &debug_datetime_detection/1,
        dependencies: []
      }
    ]
  end

  @doc """
  Get a specific rule by name.
  """
  @spec get_rule(atom()) :: rule_metadata() | nil
  def get_rule(name) do
    Enum.find(list_rules(), &(&1.name == name))
  end

  @doc """
  Get the Membrane bin module for a specific rule.
  """
  @spec get_rule_bin_module(atom()) :: module() | nil
  def get_rule_bin_module(rule_name) do
    case get_rule(rule_name) do
      %{bin_module: module} -> module
      nil -> nil
    end
  end

  @doc """
  Get the rule module for direct transformation (not Membrane bin).
  """
  @spec get_rule_module(atom()) :: module() | nil
  def get_rule_module(rule_name) do
    # Map rule names to simple transformation modules
    case rule_name do
      :datetime_string_fix -> AriaEngine.Membrane.Migration.Rules.DatetimeStringFix
      :interval_constructor_fix -> AriaEngine.Membrane.Migration.Rules.IntervalConstructorFix
      :domain_from_module -> AriaEngine.Membrane.Migration.Rules.DomainFromModule
      :logger_conversion -> AriaEngine.Membrane.Migration.Rules.LoggerConversion
      :goal_tuples -> AriaEngine.Membrane.Migration.Rules.GoalTuples
      :debug_datetime -> AriaEngine.Membrane.Migration.Rules.DebugDatetime
      _ -> nil
    end
  end

  @doc """
  Get rules by category.
  """
  @spec get_rules_by_category(atom()) :: [rule_metadata()]
  def get_rules_by_category(category) do
    Enum.filter(list_rules(), &(&1.category == category))
  end

  @doc """
  List all rule names.
  """
  @spec list_all_rule_names() :: [atom()]
  def list_all_rule_names do
    Enum.map(list_rules(), & &1.name)
  end

  @doc """
  Get all applicable rules for the given content.
  """
  @spec get_applicable_rules(String.t()) :: [rule_metadata()]
  def get_applicable_rules(content) do
    list_rules()
    |> Enum.filter(fn rule ->
      rule.detection_fn.(content)
    end)
  end

  @doc """
  Resolve rule dependencies and return rules in execution order.
  """
  @spec resolve_dependencies([atom()]) :: [rule_metadata()]
  def resolve_dependencies(rule_names) do
    rules = Enum.map(rule_names, &get_rule/1) |> Enum.reject(&is_nil/1)
    topological_sort(rules)
  end

  # Detection functions (migrated from original rules)

  defp domain_from_module_detection(source_code) do
    String.contains?(source_code, "Domain.from_module")
  end

  defp goal_tuples_detection(source_code) do
    # Look for tuple patterns that might need reordering
    String.contains?(source_code, "{") and
      (String.contains?(source_code, "subject") or
       String.contains?(source_code, "predicate") or
       String.contains?(source_code, "object"))
  end

  defp logger_conversion_detection(source_code) do
    String.contains?(source_code, "IO.puts")
  end

  defp datetime_string_fix_detection(source_code) do
    String.contains?(source_code, "DateTime.to_iso8601(")
  end

  defp interval_constructor_fix_detection(source_code) do
    String.contains?(source_code, "Interval.new_fixed_schedule")
  end

  defp debug_datetime_detection(source_code) do
    String.contains?(source_code, "DateTime.to_iso8601(")
  end

  # Private functions

  defp topological_sort(rules) do
    # Simple topological sort based on dependencies
    rule_map = Map.new(rules, &{&1.name, &1})

    # Start with rules that have no dependencies
    no_deps = Enum.filter(rules, &(Enum.empty?(&1.dependencies)))

    # Then add rules whose dependencies are satisfied
    sorted = sort_with_dependencies(rules, rule_map, no_deps, [])

    # Return in execution order
    Enum.reverse(sorted)
  end

  defp sort_with_dependencies([], _rule_map, _satisfied, acc), do: acc

  defp sort_with_dependencies(remaining_rules, rule_map, satisfied_rules, acc) do
    satisfied_names = MapSet.new(satisfied_rules, & &1.name)

    {ready, still_waiting} =
      Enum.split_with(remaining_rules, fn rule ->
        Enum.all?(rule.dependencies, &MapSet.member?(satisfied_names, &1))
      end)

    case ready do
      [] ->
        # No progress possible - add remaining rules anyway to avoid infinite loop
        Enum.reverse(still_waiting) ++ acc

      _ ->
        new_satisfied = satisfied_rules ++ ready
        new_acc = ready ++ acc
        sort_with_dependencies(still_waiting, rule_map, new_satisfied, new_acc)
    end
  end
end
