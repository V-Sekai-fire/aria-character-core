defmodule AriaCore.ActionAttributes do
  @moduledoc """
  Action attribute processing system for AriaCore.

  This module implements Phase 1 of the ADR-181 implementation plan:
  enabling @action attribute syntax while leveraging existing systems.

  Uses the sociable testing approach by bridging to existing Domain,
  Entity, and Temporal systems rather than reimplementing them.

  ## Usage

      defmodule MyDomain do
        use AriaCore.Domain

        @action duration: "PT2H",
                requires_entities: [
                  %{type: "agent", capabilities: [:cooking]}
                ]
        def cook_meal(state, [meal_id]) do
          # Action implementation
          AriaCore.State.Relational.set_fact(state, "meal_status", meal_id, "ready")
        end
      end
  """

  @doc """
  Enables @action attribute processing in a module.

  When a module uses AriaCore.Domain, it gains access to:
  - @action attribute for defining action metadata
  - @task_method attribute for defining method decomposition
  - Automatic domain creation from attributes
  """
  defmacro __using__(_opts) do
    quote do
      import AriaCore.ActionAttributes
      Module.register_attribute(__MODULE__, :action_metadata, accumulate: true)
      Module.register_attribute(__MODULE__, :method_metadata, accumulate: true)
      @before_compile AriaCore.ActionAttributes
    end
  end

  @doc """
  Defines action metadata using @action attribute.

  ## Supported Attributes

  - `duration`: ISO 8601 duration string or seconds (required)
  - `requires_entities`: List of entity requirements (optional)
  - `preconditions`: List of state conditions that must be true (optional)
  - `effects`: List of state changes the action produces (optional)

  ## Examples

      @action duration: "PT30M",
              requires_entities: [
                %{type: "agent", capabilities: [:cooking]},
                %{type: "kitchen", capabilities: [:food_prep]}
              ],
              preconditions: [
                {"ingredient_available", "tomato", true}
              ],
              effects: [
                {"meal_status", "soup", "cooking"}
              ]
      def make_soup(state, [soup_id]) do
        # Implementation
      end
  """
  defmacro action(metadata) do
    quote do
      function_name = case __CALLER__.function do
        {name, _arity} -> name
        nil -> :unknown_action
      end
      @action_metadata {function_name, unquote(metadata)}
    end
  end

  @doc """
  Defines task method metadata using @task_method attribute.

  Task methods provide decomposition strategies for complex goals.

  ## Examples

      @task_method goal_pattern: {"meal_ready", :meal_id, true}
      def prepare_meal_method(state, [meal_id]) do
        {:ok, [
          {"ingredients_available", meal_id, true},
          {:cook_meal, [meal_id]},
          {"quality_check", meal_id, true}
        ]}
      end
  """
  defmacro task_method(metadata) do
    quote do
      function_name = case __CALLER__.function do
        {name, _arity} -> name
        nil -> :unknown_method
      end
      @method_metadata {function_name, unquote(metadata)}
    end
  end

  @doc """
  Compile-time hook that processes accumulated @action and @task_method attributes.

  This generates the domain creation functions that bridge to existing systems.
  """
  defmacro __before_compile__(env) do
    actions = Module.get_attribute(env.module, :action_metadata) || []
    methods = Module.get_attribute(env.module, :method_metadata) || []

    quote do
      def __action_metadata__, do: unquote(actions)
      def __method_metadata__, do: unquote(methods)

      @doc """
      Creates a domain from the module's @action and @task_method attributes.

      This function implements the sociable testing approach by leveraging
      existing AriaCore systems rather than reimplementing them.
      """
      def create_domain() do
        # Start with base domain (LEVERAGE existing Domain.new)
        domain = AriaCore.Domain.new(unquote(env.module))

        # Process actions using existing systems (SOCIABLE approach)
        domain_with_actions =
          Enum.reduce(__action_metadata__(), domain, fn {name, metadata}, acc ->
            action_spec = AriaCore.ActionAttributes.convert_action_metadata(metadata, name, __MODULE__)
            AriaCore.Domain.add_action(acc, name, action_spec)
          end)

        # Process methods using existing systems (SOCIABLE approach)
        domain_with_methods =
          Enum.reduce(__method_metadata__(), domain_with_actions, fn {name, metadata}, acc ->
            method_spec = AriaCore.ActionAttributes.convert_method_metadata(metadata, name, __MODULE__)
            AriaCore.Domain.add_method(acc, name, method_spec)
          end)

        # Set up entity registry (LEVERAGE existing entity system)
        entity_registry = AriaCore.ActionAttributes.create_entity_registry(__action_metadata__())
        domain_with_entities = AriaCore.Domain.set_entity_registry(domain_with_methods, entity_registry)

        # Set up temporal specifications (LEVERAGE existing temporal system)
        temporal_specs = AriaCore.ActionAttributes.create_temporal_specifications(__action_metadata__())
        AriaCore.Domain.set_temporal_specifications(domain_with_entities, temporal_specs)
      end
    end
  end

  @doc """
  Converts @action metadata to Domain action specification.

  This function bridges the new attribute syntax to existing Domain.add_action format.
  """
  def convert_action_metadata(metadata, action_name, module) do
    %{
      duration: convert_duration(metadata[:duration]),
      entity_requirements: convert_entity_requirements(metadata[:requires_entities] || []),
      preconditions: metadata[:preconditions] || [],
      effects: metadata[:effects] || [],
      action_fn: Function.capture(module, action_name, 2)
    }
  end

  @doc """
  Converts @task_method metadata to Domain method specification.
  """
  def convert_method_metadata(metadata, method_name, module) do
    %{
      goal_pattern: metadata[:goal_pattern],
      decomposition_fn: Function.capture(module, method_name, 2),
      priority: metadata[:priority] || 1
    }
  end

  @doc """
  Creates entity registry from action metadata.

  SOCIABLE APPROACH: Leverages existing AriaCore.Entity.Management system.
  """
  def create_entity_registry(action_metadata) do
    # Extract all entity requirements from actions
    all_requirements =
      action_metadata
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
    # Extract all duration specifications
    duration_specs =
      action_metadata
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

  defp convert_entity_requirements(requirements) when is_list(requirements) do
    # LEVERAGE existing entity requirement processing (sociable approach)
    Enum.map(requirements, &AriaCore.Entity.Management.normalize_requirement/1)
  end

  defp convert_entity_requirements(invalid_requirements) do
    # Handle invalid input gracefully
    raise ArgumentError, "Entity requirements must be a list, got: #{inspect(invalid_requirements)}"
  end
end
