# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaMiniZinc.ProblemGenerator.Common do
  @moduledoc """
  Shared utilities for MiniZinc problem generators.

  Contains common type definitions, helper functions, and utilities
  used by both goal-solving and STN problem generators.
  """

  require Logger

  # Shared type definitions
  @type goal :: {subject :: String.t(), predicate :: String.t(), object :: term()}
  @type state :: AriaEngine.State.t()
  @type iso8601_datetime :: String.t()  # "2025-06-23T23:16:07.123456-07:00"
  @type iso8601_duration :: String.t()  # "PT1.234S"
  @type domain :: map()
  @type options :: map()

  @type variable :: %{
    name: String.t(),
    type: String.t(),
    domain: Range.t() | nil | String.t()
  }

  @type structured_variables :: %{
    time_vars: [variable()],
    location_vars: [variable()],
    boolean_vars: [variable()]
  }

  @type constraint :: %{
    type: :equality | :domain | :temporal_ordering | :generic,
    variable: String.t(),
    value: term(),
    description: String.t(),
    constraint: String.t(),
    min: integer(),
    max: integer()
  }

  @type problem_metadata :: %{
    goal_count: non_neg_integer(),
    variable_count: non_neg_integer(),
    constraint_count: non_neg_integer(),
    optimization: atom(),
    generation_start: iso8601_datetime(),
    generation_end: iso8601_datetime(),
    generation_duration: iso8601_duration(),
    domain: String.t()
  }

  @template_dir "priv/templates/minizinc"

  @doc """
  Calculate duration between two ISO 8601 timestamps.
  """
  @spec calculate_duration(iso8601_datetime(), iso8601_datetime()) :: iso8601_duration()
  def calculate_duration(start_iso, end_iso) do
    start_dt = Timex.parse!(start_iso, "{ISO:Extended}")
    end_dt = Timex.parse!(end_iso, "{ISO:Extended}")

    # Use microseconds as Timex's most precise integer duration element
    duration_microseconds = Timex.diff(end_dt, start_dt, :microseconds)
    duration_seconds = duration_microseconds / 1_000_000
    "PT#{duration_seconds}S"
  end

  @doc """
  Extract decision variables from goals and state - returns structured format.
  """
  @spec extract_variables([goal()], state()) :: structured_variables()
  def extract_variables(goals, _state) do
    # Handle malformed goals gracefully
    valid_goals = Enum.filter(goals, fn
      {subject, _predicate, _value} when is_binary(subject) -> true
      _ -> false
    end)

    # Extract entities and their possible values
    entities = valid_goals
    |> Enum.map(fn {subject, _predicate, _value} -> subject end)
    |> Enum.uniq()

    # Create categorized variables for each entity
    time_vars = Enum.map(entities, fn entity ->
      %{name: "#{entity}_time", type: "var int", domain: 0..100}
    end)

    location_vars = Enum.map(entities, fn entity ->
      %{name: "#{entity}_location", type: "var int", domain: 1..10}
    end)

    boolean_vars = Enum.map(entities, fn entity ->
      %{name: "#{entity}_active", type: "var bool", domain: nil}
    end)

    %{
      time_vars: time_vars,
      location_vars: location_vars,
      boolean_vars: boolean_vars
    }
  end

  @doc """
  Count total variables from structured format.
  """
  @spec count_total_variables(structured_variables()) :: non_neg_integer()
  def count_total_variables(variables) do
    length(variables.time_vars) + length(variables.location_vars) + length(variables.boolean_vars)
  end

  @doc """
  Determine optimization type from options.
  """
  @spec determine_optimization_type(options()) :: atom()
  def determine_optimization_type(options) do
    case Map.get(options, :optimization_type, :minimize_time) do
      :minimize_time -> :minimize_steps
      :minimize_distance -> :minimize_distance
      :maximize_efficiency -> :maximize_efficiency
      _ -> :minimize_steps
    end
  end

  @doc """
  Generate constraints from domain rules and goals - returns structured format.
  """
  @spec generate_constraints(domain(), state(), [goal()], options()) :: [constraint()]
  def generate_constraints(domain, state, goals, options) do
    goal_constraints = generate_goal_constraints(goals)
    domain_constraints = generate_domain_constraints(domain, state)
    temporal_constraints = generate_temporal_constraints(goals, options)

    goal_constraints ++ domain_constraints ++ temporal_constraints
  end

  @doc """
  Process variable with formatted domain.
  """
  @spec process_variable(variable()) :: variable()
  def process_variable(var) do
    %{var | domain: format_domain(var.domain)}
  end

  @doc """
  Load and render a MiniZinc template.
  """
  @spec render_template(String.t(), map()) :: String.t()
  def render_template(template_name, vars) do
    template_path = Path.join([Application.app_dir(:aria_minizinc), @template_dir, template_name])

    case File.read(template_path) do
      {:ok, template_content} ->
        EEx.eval_string(template_content, assigns: vars)
      {:error, reason} ->
        Logger.error("Failed to load template #{template_name}: #{inspect(reason)}")
        raise "Template loading failed: #{template_name}"
    end
  end

  @doc """
  Render structured constraint to MiniZinc string.
  """
  @spec render_constraint(constraint()) :: String.t()
  def render_constraint(%{type: :equality, variable: var, value: val, description: desc}) do
    "constraint #{var} = #{val}; % #{desc}"
  end

  def render_constraint(%{type: :domain, variable: var, min: min, max: max, description: desc}) do
    "constraint forall(i in 1..num_entities) (#{var}[i] >= #{min} /\\ #{var}[i] <= #{max}); % #{desc}"
  end

  def render_constraint(%{type: :domain, variable: var, min: min, description: desc}) do
    "constraint forall(i in 1..num_entities) (#{var}[i] >= #{min}); % #{desc}"
  end

  def render_constraint(%{type: :temporal_ordering, description: desc}) do
    "constraint forall(i in 1..num_entities-1) (entity_time[i] <= entity_time[i+1]); % #{desc}"
  end

  def render_constraint(%{type: :generic, constraint: constraint, description: desc}) do
    "constraint #{constraint}; % #{desc}"
  end

  def render_constraint(%{type: :generic, description: desc}) do
    "constraint true; % #{desc}"
  end

  def render_constraint(constraint) do
    "constraint true; % Unknown constraint: #{inspect(constraint)}"
  end

  @doc """
  Helper functions for encoding values.
  """
  @spec encode_location(String.t() | integer()) :: integer()
  def encode_location(location) when is_binary(location) do
    # Simple hash-based encoding for location names
    :erlang.phash2(location, 10) + 1
  end
  def encode_location(location) when is_integer(location), do: location

  @spec encode_boolean(term()) :: String.t()
  def encode_boolean(true), do: "true"
  def encode_boolean(false), do: "false"
  def encode_boolean("true"), do: "true"
  def encode_boolean("false"), do: "false"
  def encode_boolean(_), do: "true"

  # Private helper functions

  # Format domain for MiniZinc syntax
  defp format_domain(min..max//1), do: "#{min}..#{max}"
  defp format_domain(nil), do: ""
  defp format_domain(domain) when is_integer(domain), do: "#{domain}"
  defp format_domain(domain), do: "#{inspect(domain)}"

  # Generate constraints to satisfy goals - returns structured constraint maps
  defp generate_goal_constraints(goals) do
    # Filter out malformed goals
    valid_goals = Enum.filter(goals, fn
      {subject, predicate, _value} when is_binary(subject) and is_binary(predicate) -> true
      _ -> false
    end)

    Enum.map(valid_goals, fn {subject, predicate, value} ->
      case predicate do
        "location" ->
          %{
            type: :equality,
            variable: "#{subject}_location",
            value: encode_location(value),
            description: "Goal: #{subject} at #{value}"
          }
        "state" ->
          %{
            type: :equality,
            variable: "#{subject}_active",
            value: encode_boolean(value),
            description: "Goal: #{subject} state #{value}"
          }
        _ ->
          %{
            type: :generic,
            description: "Generic goal: #{subject} #{predicate} #{value}",
            constraint: "true"
          }
      end
    end)
  end

  # Generate domain-specific constraints - returns structured constraint maps
  defp generate_domain_constraints(_domain, _state) do
    [
      %{
        type: :domain,
        variable: "entity_time",
        constraint: "forall",
        min: 0,
        description: "Time variables must be non-negative"
      },
      %{
        type: :domain,
        variable: "entity_location",
        constraint: "forall",
        min: 1,
        max: 10,
        description: "Location variables must be in valid range"
      }
    ]
  end

  # Generate temporal ordering constraints - returns structured constraint maps
  defp generate_temporal_constraints(goals, options) do
    if (Map.get(options, :temporal_ordering, false) or Map.get(options, :temporal_constraints, false)) and length(goals) > 1 do
      [
        %{
          type: :temporal_ordering,
          constraint: "forall",
          description: "Sequential temporal ordering"
        }
      ]
    else
      []
    end
  end
end
