# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

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

  @type action_metadata :: keyword()
  @type method_metadata :: map()
  @type unigoal_metadata :: keyword()
  @type entity_requirement :: map()
  @type duration_spec :: AriaCore.Temporal.Interval.duration()

  alias AriaEngineCore.Domain

  @doc """
  Enables @action attribute processing in a module.

  When a module uses AriaCore.Domain, it gains access to:
  - @action attribute for defining action metadata
  - @task_method attribute for defining method decomposition
  - @unigoal_method attribute for defining unigoal methods
  - Automatic domain creation from attributes
  """
  @spec __using__(keyword()) :: Macro.t()
  defmacro __using__(_opts) do
    quote do
      # Register all attributes as accumulating
      Module.register_attribute(__MODULE__, :action, accumulate: true)
      Module.register_attribute(__MODULE__, :command, accumulate: true)
      Module.register_attribute(__MODULE__, :task_method, accumulate: true)
      Module.register_attribute(__MODULE__, :unigoal_method, accumulate: true)

      # Internal tracking attributes
      Module.register_attribute(__MODULE__, :action_metadata, accumulate: true)
      Module.register_attribute(__MODULE__, :command_metadata, accumulate: true)
      Module.register_attribute(__MODULE__, :method_metadata, accumulate: true)
      Module.register_attribute(__MODULE__, :unigoal_metadata, accumulate: true)

      # Pending attributes (non-persistent)
      Module.register_attribute(__MODULE__, :pending_action_metadata, persist: false)
      Module.register_attribute(__MODULE__, :pending_command_metadata, persist: false)
      Module.register_attribute(__MODULE__, :pending_task_metadata, persist: false)
      Module.register_attribute(__MODULE__, :pending_unigoal_metadata, persist: false)

      # Hook into compilation process
      @on_definition {AriaCore.ActionAttributes, :__on_definition__}
      @before_compile AriaCore.ActionAttributes

      # Import the attribute consumption macro
      import AriaCore.ActionAttributes, only: [task_method: 0]
    end
  end

  # Documentation for supported attributes

  @doc """
  @action attribute documentation.

  ## Supported Attributes

  - `duration`: ISO 8601 duration string or seconds (optional)
  - `start`: ISO 8601 datetime string for fixed start time (optional)
  - `end`: ISO 8601 datetime string for fixed end time (optional)
  - `requires_entities`: List of entity requirements (optional)

  ## Examples

      @action duration: "PT30M",
              requires_entities: [
                %{type: "agent", capabilities: [:cooking]},
                %{type: "kitchen", capabilities: [:food_prep]}
              ]
      def make_soup(state, [soup_id]) do
        # Implementation
      end
  """
  @spec action_attribute_docs() :: :ok
  def action_attribute_docs, do: :ok

  @doc """
  @command attribute documentation.

  Commands are execution-time logic with failure handling according to ADR-181.
  They are used during plan execution to handle real-world failures and provide
  robust execution behavior.

  ## Supported Attributes

  - `duration`: ISO 8601 duration string or seconds (optional)
  - `requires_entities`: List of entity requirements (optional)

  ## Examples

      @command true
      def cook_meal_command(state, [meal_id]) do
        case validate_cooking_equipment(state) do
          :ok ->
            perform_cooking(state, meal_id)
          {:error, reason} ->
            {:error, reason}
        end
      end
  """
  @spec command_attribute_docs() :: :ok
  def command_attribute_docs, do: :ok

  @doc """
  @task_method attribute documentation.

  Task methods provide decomposition strategies for complex workflows.
  According to ADR-181, task methods are for workflow decomposition only
  and do not support priority or goal_pattern fields.

  ## Examples

      @task_method
      def prepare_meal_method(state, [meal_id]) do
        {:ok, [
          {"ingredients_available", meal_id, true},
          {:cook_meal, [meal_id]},
          {"quality_check", meal_id, true}
        ]}
      end
  """
  @spec task_method_attribute_docs() :: :ok
  def task_method_attribute_docs, do: :ok

  @doc """
  @unigoal_method attribute documentation.

  Unigoal methods provide single goal achievement strategies according to ADR-181.
  They handle prerequisite checking, action selection, and verification for one specific goal predicate.

  ## Required Attributes

  - `predicate`: The goal predicate this method handles (required)

  ## Examples

      @unigoal_method predicate: "meal_status"
      def meal_status_goal(state, [subject, value]) when value == "ready" do
        {:ok, [
          # Prerequisites (former preconditions)
          {"ingredient_available", "tomato", true},
          {"equipment_status", "stove_1", "operational"},

          # Main action
          {:cook_meal, [subject]},

          # Verification (former effects)
          {"meal_status", subject, "ready"}
        ]}
      end
  """
  @spec unigoal_method_attribute_docs() :: :ok
  def unigoal_method_attribute_docs, do: :ok

  @doc """
  Macro to properly consume @task_method attribute.

  This macro ensures the @task_method attribute is properly consumed
  to avoid Elixir warnings about unused attributes.

  Task methods provide decomposition strategies for complex workflows
  according to ADR-181. They are for workflow decomposition only.
  """
  @spec task_method() :: Macro.t()
  defmacro task_method() do
    quote do
      # Consume the @task_method attribute by assigning it
      _ = @task_method
      # Return the consumed value to satisfy Elixir's requirements
      true
    end
  end

  @doc """
  Callback invoked when a function is defined.

  This associates any pending attributes with the newly defined function.
  """
  @spec __on_definition__(Macro.Env.t(), atom(), atom(), list(), list(), term()) :: :ok
  def __on_definition__(env, kind, name, _args, _guards, _body) when kind in [:def, :defp] do
    # Functional approach: consume attributes by reading and transforming them

    # Process @action attribute - consume by reading and transforming
    case Module.get_attribute(env.module, :action) do
      [] -> :ok
      [action_metadata | _rest] = attrs ->
        # Consume the attribute by assigning it (satisfies Elixir's "return" requirement)
        _consumed_action_attrs = attrs
        Module.put_attribute(env.module, :action_metadata, {name, action_metadata})
    end

    # Process @command attribute - consume by reading and transforming
    case Module.get_attribute(env.module, :command) do
      [] -> :ok
      [command_metadata | _rest] = attrs ->
        # Consume the attribute by assigning it (satisfies Elixir's "return" requirement)
        _consumed_command_attrs = attrs
        Module.put_attribute(env.module, :command_metadata, {name, command_metadata})
    end

    # Process @task_method attribute - consume by reading and transforming
    # Handle both @task_method and @task_method <value> patterns
    task_attrs = Module.get_attribute(env.module, :task_method)
    case task_attrs do
      [] -> :ok
      nil -> :ok
      attrs when is_list(attrs) and length(attrs) > 0 ->
        # Consume the attribute by assigning it (satisfies Elixir's "return" requirement)
        _consumed_task_attrs = attrs
        Module.put_attribute(env.module, :method_metadata, {name, %{type: :task_method}})
        # Clear the attribute to prevent accumulation
        Module.delete_attribute(env.module, :task_method)
      other when other != [] ->
        # Handle any other attribute value (including bare @task_method)
        _consumed_task_attr = other
        Module.put_attribute(env.module, :method_metadata, {name, %{type: :task_method}})
        # Clear the attribute to prevent accumulation
        Module.delete_attribute(env.module, :task_method)
    end

    # Process @unigoal_method attribute - consume by reading and transforming
    case Module.get_attribute(env.module, :unigoal_method) do
      [] -> :ok
      [unigoal_metadata | _rest] = attrs ->
        # Consume the attribute by assigning it (satisfies Elixir's "return" requirement)
        _consumed_unigoal_attrs = attrs

        # Validate required predicate attribute
        predicate = unigoal_metadata[:predicate]
        if is_nil(predicate) do
          raise ArgumentError, "unigoal_method requires predicate: attribute, got: #{inspect(unigoal_metadata)}"
        end

        Module.put_attribute(env.module, :unigoal_metadata, {name, unigoal_metadata})
    end

    # Continue with normal compilation
    :ok
  end

  def __on_definition__(_env, _kind, _name, _args, _guards, _body), do: :ok

  @doc """
  Compile-time hook that processes accumulated @action and @task_method attributes.

  This generates the domain creation functions that bridge to existing systems.
  """
  defmacro __before_compile__(env) do
    actions = Module.get_attribute(env.module, :action_metadata) || []
    commands = Module.get_attribute(env.module, :command_metadata) || []
    methods = Module.get_attribute(env.module, :method_metadata) || []
    unigoals = Module.get_attribute(env.module, :unigoal_metadata) || []

    quote do
      def __action_metadata__, do: unquote(Macro.escape(actions))
      def __command_metadata__, do: unquote(Macro.escape(commands))
      def __method_metadata__, do: unquote(Macro.escape(methods))
      def __unigoal_metadata__, do: unquote(Macro.escape(unigoals))

      @doc """
      Creates a domain from the module's @action, @task_method, and @unigoal_method attributes.

      This function implements the sociable testing approach by leveraging
      existing AriaCore systems rather than reimplementing them.
      """
      def create_domain() do
        # Start with base domain (LEVERAGE existing Domain.new)
        domain = Domain.new(unquote(env.module))

        # Process actions using existing systems (SOCIABLE approach)
        domain_with_actions =
          Enum.reduce(__action_metadata__(), domain, fn {name, metadata}, acc ->
            action_spec = AriaCore.ActionAttributes.convert_action_metadata(metadata, name, __MODULE__)
            Domain.add_action(acc, name, action_spec)
          end)

        # Process commands using existing systems (SOCIABLE approach)
        domain_with_commands =
          Enum.reduce(__command_metadata__(), domain_with_actions, fn {name, metadata}, acc ->
            command_spec = AriaCore.ActionAttributes.convert_command_metadata(metadata, name, __MODULE__)
            Domain.add_action(acc, name, command_spec)
          end)

        # Process methods using existing systems (SOCIABLE approach)
        domain_with_methods =
          Enum.reduce(__method_metadata__(), domain_with_commands, fn {name, metadata}, acc ->
            method_spec = AriaCore.ActionAttributes.convert_method_metadata(metadata, name, __MODULE__)
            Domain.add_method(acc, name, method_spec)
          end)

        # Process unigoal methods using existing systems (SOCIABLE approach)
        domain_with_unigoals =
          Enum.reduce(__unigoal_metadata__(), domain_with_methods, fn {name, metadata}, acc ->
            unigoal_spec = AriaCore.ActionAttributes.convert_unigoal_metadata(metadata, name, __MODULE__)
            Domain.add_unigoal_method(acc, name, unigoal_spec)
          end)

        # Set up entity registry (LEVERAGE existing entity system)
        entity_registry = AriaCore.ActionAttributes.create_entity_registry(__action_metadata__())
        domain_with_entities = Domain.set_entity_registry(domain_with_unigoals, entity_registry)

        # Set up temporal specifications (LEVERAGE existing temporal system)
        temporal_specs = AriaCore.ActionAttributes.create_temporal_specifications(__action_metadata__())
        domain_with_temporal_specs = Domain.set_temporal_specifications(domain_with_entities, temporal_specs)
        domain_with_temporal_specs
      end
    end
  end

  @doc """
  Converts @action metadata to Domain action specification.

  This function bridges the new attribute syntax to existing Domain.add_action format.
  """
  @spec convert_action_metadata(action_metadata(), atom(), module()) :: map()
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
  Converts @command metadata to Domain action specification.

  Commands are execution-time logic with failure handling according to ADR-181.
  They use the same specification format as actions but are intended for execution.
  """
  @spec convert_command_metadata(action_metadata(), atom(), module()) :: map()
  def convert_command_metadata(metadata, command_name, module) do
    %{
      duration: convert_duration(metadata[:duration]),
      entity_requirements: convert_entity_requirements(metadata[:requires_entities] || []),
      preconditions: metadata[:preconditions] || [],
      effects: metadata[:effects] || [],
      action_fn: Function.capture(module, command_name, 2),
      command: true  # Mark as command for execution-time logic
    }
  end

  @doc """
  Converts @task_method metadata to Domain method specification.

  According to ADR-181, @task_method attributes do not support priority or goal_pattern fields.
  Task methods are for workflow decomposition only.
  """
  def convert_method_metadata(_metadata, method_name, module) do
    %{
      decomposition_fn: Function.capture(module, method_name, 2)
    }
  end

  @doc """
  Converts @unigoal_method metadata to Domain unigoal method specification.

  According to ADR-181, @unigoal_method attributes only support the predicate field.
  Priority handling belongs in the planner's method selection logic, not in attribute metadata.
  """
  def convert_unigoal_metadata(metadata, method_name, module) do
    %{
      predicate: metadata[:predicate],
      goal_fn: Function.capture(module, method_name, 2)
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

  defp convert_entity_requirements(_invalid_requirements) do
    # Handle invalid input gracefully by providing empty list
    # This allows the system to continue functioning with reasonable defaults
    []
  end
end
