# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule Mix.Tasks.Migrate.RuleRegistry do
  @moduledoc """
  Registry for migration transformation rules.

  Single responsibility: Manage the catalog of available transformation rules,
  their metadata, dependencies, and discovery.
  """

  defstruct [:name, :description, :category, :transformation_fn, :detection_fn, :dependencies]

  @type rule :: %__MODULE__{
          name: atom(),
          description: String.t(),
          category: atom(),
          transformation_fn: function(),
          detection_fn: function(),
          dependencies: [atom()]
        }

  @doc """
  List all available transformation rules.
  """
  @spec list_rules() :: [rule()]
  def list_rules do
    [
      # API migrations
      %__MODULE__{
        name: :domain_from_module,
        description: "Replace Domain.from_module calls with direct build() calls",
        category: :api_migration,
        transformation_fn: &Mix.Tasks.Migrate.Rules.DomainFromModule.transformation_rules/0,
        detection_fn: &Mix.Tasks.Migrate.Rules.DomainFromModule.needs_transformation?/1,
        dependencies: []
      },

      # Format migrations
      %__MODULE__{
        name: :goal_tuples,
        description: "Fix goal tuple ordering from {subject, predicate, object} to {predicate, subject, object}",
        category: :format_migration,
        transformation_fn: &Mix.Tasks.Migrate.Rules.GoalTuples.transformation_rules/0,
        detection_fn: &Mix.Tasks.Migrate.Rules.GoalTuples.needs_transformation?/1,
        dependencies: []
      },

      # Refactoring
      %__MODULE__{
        name: :logger_conversion,
        description: "Convert IO.puts calls to appropriate Logger calls",
        category: :refactoring,
        transformation_fn: &Mix.Tasks.Migrate.Rules.LoggerConversion.transformation_rules/0,
        detection_fn: &Mix.Tasks.Migrate.Rules.LoggerConversion.needs_transformation?/1,
        dependencies: []
      },

      # Bug fixes
      %__MODULE__{
        name: :datetime_string_fix,
        description: "Fix DateTime.to_iso8601 calls with string arguments",
        category: :bug_fix,
        transformation_fn: &Mix.Tasks.Migrate.Rules.DatetimeStringFix.transformation_rules/0,
        detection_fn: &Mix.Tasks.Migrate.Rules.DatetimeStringFix.needs_transformation?/1,
        dependencies: []
      },

      %__MODULE__{
        name: :interval_constructor_fix,
        description: "Fix Interval.new_fixed_schedule calls missing end time parameters",
        category: :bug_fix,
        transformation_fn: &Mix.Tasks.Migrate.Rules.IntervalConstructorFix.transformation_rules/0,
        detection_fn: &Mix.Tasks.Migrate.Rules.IntervalConstructorFix.needs_transformation?/1,
        dependencies: []
      },

      %__MODULE__{
        name: :debug_datetime,
        description: "Debug DateTime AST patterns",
        category: :debug,
        transformation_fn: &Mix.Tasks.Migrate.Rules.DebugDatetime.transformation_rules/0,
        detection_fn: &Mix.Tasks.Migrate.Rules.DebugDatetime.needs_transformation?/1,
        dependencies: []
      }
    ]
  end

  @doc """
  Get a specific rule by name.
  """
  @spec get_rule(atom()) :: rule() | nil
  def get_rule(name) do
    Enum.find(list_rules(), &(&1.name == name))
  end

  @doc """
  Get rules by category.
  """
  @spec get_rules_by_category(atom()) :: [rule()]
  def get_rules_by_category(category) do
    Enum.filter(list_rules(), &(&1.category == category))
  end

  @doc """
  Resolve rule dependencies and return rules in execution order.
  """
  @spec resolve_dependencies([atom()]) :: [rule()]
  def resolve_dependencies(rule_names) do
    rules = Enum.map(rule_names, &get_rule/1) |> Enum.reject(&is_nil/1)
    topological_sort(rules)
  end

  @doc """
  Get all applicable rules for the given content.
  """
  @spec get_applicable_rules(String.t()) :: [rule()]
  def get_applicable_rules(content) do
    list_rules()
    |> Enum.filter(fn rule ->
      rule.detection_fn.(content)
    end)
  end

  # Private functions

  defp topological_sort(rules) do
    # Simple topological sort based on dependencies
    # For now, we'll use a basic approach - in practice, you might want a more robust algorithm

    # Create a map of rule names to rules for quick lookup
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
        # No progress possible - circular dependency or missing dependency
        # Add remaining rules anyway to avoid infinite loop
        Enum.reverse(still_waiting) ++ acc

      _ ->
        new_satisfied = satisfied_rules ++ ready
        new_acc = ready ++ acc
        sort_with_dependencies(still_waiting, rule_map, new_satisfied, new_acc)
    end
  end
end
