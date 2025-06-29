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
      # Register attributes as non-accumulating, to be processed one by one
      Module.register_attribute(__MODULE__, :action, [])
      Module.register_attribute(__MODULE__, :command, [])
      Module.register_attribute(__MODULE__, :task_method, [])
      Module.register_attribute(__MODULE__, :unigoal_method, [])
      Module.register_attribute(__MODULE__, :multigoal_method, [])
      Module.register_attribute(__MODULE__, :multitodo_method, [])

      # Internal tracking attributes (accumulating)
      Module.register_attribute(__MODULE__, :action_metadata, accumulate: true)
      Module.register_attribute(__MODULE__, :command_metadata, accumulate: true)
      Module.register_attribute(__MODULE__, :method_metadata, accumulate: true)
      Module.register_attribute(__MODULE__, :unigoal_metadata, accumulate: true)
      Module.register_attribute(__MODULE__, :multigoal_metadata, accumulate: true)
      Module.register_attribute(__MODULE__, :multitodo_metadata, accumulate: true)

      # Hook into compilation process
      @on_definition {AriaCore.ActionAttributes, :__on_definition__}
      @before_compile AriaCore.ActionAttributes

      # Import the attribute consumption macros
      import AriaCore.ActionAttributes, only: [task_method: 0, task_method: 1]
    end
  end

  # Documentation for supported attributes

  @doc """
  @multigoal_method attribute documentation.

  Multigoal methods provide optimization strategies for achieving multiple goals simultaneously.

  ## Examples

      @multigoal_method true
      def optimize_resource_allocation(state, multigoal) do
        # Implementation to reorder or optimize goals
        {:ok, multigoal}
      end
  """
  @spec multigoal_method_attribute_docs() :: :ok
  def multigoal_method_attribute_docs, do: :ok

  @doc """
  @multitodo_method attribute documentation.

  Multitodo methods provide optimization strategies for processing lists of todo items.

  ## Examples

      @multitodo_method true
      def reorder_tasks_for_efficiency(state, todo_list) do
        # Implementation to reorder or optimize todo_list
        {:ok, todo_list}
      end
  """
  @spec multitodo_method_attribute_docs() :: :ok
  def multitodo_method_attribute_docs, do: :ok

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
  Macro to register a function as a task method.

  This macro registers a function as a task method without
  relying on module attributes, avoiding the attribute timing issues.

  Task methods provide decomposition strategies for complex workflows
  according to ADR-181. They are for workflow decomposition only.

  ## Usage

  Call at module level after function definition:

      def prepare_meal(state, [meal_id]) do
        {:ok, [{:cook_meal, [meal_id]}]}
      end
      task_method(:prepare_meal)

  Or call inside function body (function name inferred):

      def prepare_meal(state, [meal_id]) do
        task_method()
        {:ok, [{:cook_meal, [meal_id]}]}
      end
  """
  @spec task_method() :: Macro.t()
  defmacro task_method() do
    quote do
      # Register this function as a task method by storing its name
      # We'll use the function name from the calling context
      case __ENV__.function do
        {function_name, _arity} ->
          Module.put_attribute(__MODULE__, :method_metadata, {function_name, %{type: :task_method}})
          # Return true to satisfy the function call
          true
        nil ->
          raise ArgumentError, "task_method() called outside function context. Use task_method(:function_name) instead."
      end
    end
  end

  @spec task_method(atom()) :: Macro.t()
  defmacro task_method(function_name) when is_atom(function_name) do
    quote do
      # Register the specified function as a task method
      Module.put_attribute(__MODULE__, :method_metadata, {unquote(function_name), %{type: :task_method}})
      # Return true for consistency
      true
    end
  end

  @doc """
  Callback invoked when a function is defined.

  This associates any pending attributes with the newly defined function.
  """
  @spec __on_definition__(Macro.Env.t(), atom(), atom(), list(), list(), term()) :: :ok
  def __on_definition__(env, kind, name, _args, _guards, _body) when kind in [:def, :defp] do
    # Process @action attribute
    if action_metadata = Module.get_attribute(env.module, :action) do
      Module.put_attribute(env.module, :action_metadata, {name, action_metadata})
      Module.delete_attribute(env.module, :action)
    end

    # Process @command attribute
    if command_metadata = Module.get_attribute(env.module, :command) do
      Module.put_attribute(env.module, :command_metadata, {name, command_metadata})
      Module.delete_attribute(env.module, :command)
    end

    # Process @task_method attribute
    if Module.has_attribute?(env.module, :task_method) do
      task_metadata = Module.get_attribute(env.module, :task_method)
      # Ensure task_metadata is a map before merging
      task_metadata = if is_map(task_metadata), do: task_metadata, else: %{}
      Module.put_attribute(env.module, :method_metadata, {name, %{type: :task_method} |> Map.merge(task_metadata)})
      Module.delete_attribute(env.module, :task_method)
    end

    # Process @unigoal_method attribute
    if unigoal_metadata = Module.get_attribute(env.module, :unigoal_method) do
      # Validate required predicate attribute
      predicate = unigoal_metadata[:predicate]
      if is_nil(predicate) do
        raise ArgumentError, "unigoal_method requires predicate: attribute, got: #{inspect(unigoal_metadata)}"
      end
      Module.put_attribute(env.module, :unigoal_metadata, {name, unigoal_metadata})
      Module.delete_attribute(env.module, :unigoal_method)
    end

    # Process @multigoal_method attribute
    if _multigoal_metadata = Module.get_attribute(env.module, :multigoal_method) do
      # Store the function name itself as metadata for simple true/false attributes
      Module.put_attribute(env.module, :multigoal_metadata, {name, name})
      Module.delete_attribute(env.module, :multigoal_method)
    end

    # Process @multitodo_method attribute
    if _multitodo_metadata = Module.get_attribute(env.module, :multitodo_method) do
      # Store the function name itself as metadata for simple true/false attributes
      Module.put_attribute(env.module, :multitodo_metadata, {name, name})
      Module.delete_attribute(env.module, :multitodo_method)
    end

    # Continue with normal compilation
    :ok
  end

  @doc """
  Compile-time hook that processes accumulated @action and @task_method attributes.

  This generates the domain creation functions that bridge to existing systems.
  """
  defmacro __before_compile__(env) do
    actions = Module.get_attribute(env.module, :action_metadata) || []
    commands = Module.get_attribute(env.module, :command_metadata) || []
    methods = Module.get_attribute(env.module, :method_metadata) || []
    unigoals = Module.get_attribute(env.module, :unigoal_metadata) || []
    multigoals = Module.get_attribute(env.module, :multigoal_metadata) || []
    multitodos = Module.get_attribute(env.module, :multitodo_metadata) || []

    quote do
      # Debugging: Inspect accumulated metadata
      IO.inspect(unquote(Macro.escape(actions)), label: "Actions Metadata")
      IO.inspect(unquote(Macro.escape(commands)), label: "Commands Metadata")
      IO.inspect(unquote(Macro.escape(methods)), label: "Methods Metadata")
      IO.inspect(unquote(Macro.escape(unigoals)), label: "Unigoals Metadata")
      IO.inspect(unquote(Macro.escape(multigoals)), label: "Multigoals Metadata")
      IO.inspect(unquote(Macro.escape(multitodos)), label: "Multitodos Metadata")

      def __action_metadata__, do: unquote(Macro.escape(actions))
      def __command_metadata__, do: unquote(Macro.escape(commands))
      def __method_metadata__, do: unquote(Macro.escape(methods))
      def __unigoal_metadata__, do: unquote(Macro.escape(unigoals))
      def __multigoal_metadata__, do: unquote(Macro.escape(multigoals))
      def __multitodo_metadata__, do: unquote(Macro.escape(multitodos))

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

        # Process multigoal methods using existing systems (SOCIABLE approach)
        domain_with_multigoals =
          Enum.reduce(__multigoal_metadata__(), domain_with_unigoals, fn {name, _metadata}, acc ->
            multigoal_fn = AriaCore.ActionAttributes.convert_multigoal_metadata(name, name, __MODULE__)
            Domain.add_multigoal_method(acc, Atom.to_string(name), multigoal_fn)
          end)

        # Process multitodo methods using existing systems (SOCIABLE approach)
        domain_with_multitodos =
          Enum.reduce(__multitodo_metadata__(), domain_with_multigoals, fn {name, _metadata}, acc ->
            multitodo_fn = AriaCore.ActionAttributes.convert_multitodo_metadata(name, name, __MODULE__)
            Domain.add_multitodo_method(acc, Atom.to_string(name), multitodo_fn)
          end)

        # Set up entity registry (LEVERAGE existing entity system)
        entity_registry = AriaCore.ActionAttributes.create_entity_registry(__action_metadata__())
        domain_with_entities = Domain.set_entity_registry(domain_with_multitodos, entity_registry)

        # Set up temporal specifications (LEVERAGE existing temporal system)
        temporal_specs = AriaCore.ActionAttributes.create_temporal_specifications(__action_metadata__())
        domain_with_temporal_specs = Domain.set_temporal_specifications(domain_with_entities, temporal_specs)
        domain_with_temporal_specs
      end
    end
  end

  @doc """
  Converts @multigoal_method metadata to Domain multigoal method specification.
  """
  @spec convert_multigoal_metadata(map(), atom(), module()) :: function()
  def convert_multigoal_metadata(_metadata, method_name, module) do
    Function.capture(module, method_name, 2)
  end

  @doc """
  Converts @multitodo_method metadata to Domain multitodo method specification.
  """
  @spec convert_multitodo_metadata(map(), atom(), module()) :: function()
  def convert_multitodo_metadata(_metadata, method_name, module) do
    Function.capture(module, method_name, 2)
  end

  @doc """
  Converts @action metadata to Domain action specification.

  This function bridges the new attribute syntax to existing Domain.add_action format.
  """
  @spec convert_action_metadata(true, atom(), module()) :: map()
  def convert_action_metadata(true, action_name, module) do
    %{
      duration: convert_duration(nil), # Default to instant action
      entity_requirements: [],
      preconditions: [],
      effects: [],
      action_fn: Function.capture(module, action_name, 2)
    }
  end

  @spec convert_action_metadata(action_metadata(), atom(), module()) :: map()
  def convert_action_metadata(metadata, action_name, module) do
    %{
      duration: convert_duration(metadata[:duration]),
      entity_requirements: convert_entity_requirements(metadata[:requires_entities] || []),
      preconditions: metadata[:preconditions] || [],
      effects: metadata[:effects] || [],
      action_fn: Function.capture(module, action_name, 2),
      start_time: metadata[:start], # Add start_time
      end_time: metadata[:end] # Add end_time
    }
  end

  @doc """
  Converts @command metadata to Domain action specification.

  Commands are execution-time logic with failure handling according to ADR-181.
  They use the same specification format as actions but are intended for execution.
  """
  @spec convert_command_metadata(true, atom(), module()) :: map()
  def convert_command_metadata(true, command_name, module) do
    %{
      duration: convert_duration(nil), # Default to instant action
      entity_requirements: [],
      preconditions: [],
      effects: [],
      action_fn: Function.capture(module, command_name, 2),
      command: true  # Mark as command for execution-time logic
    }
  end

  @spec convert_command_metadata(action_metadata(), atom(), module()) :: map()
  def convert_command_metadata(metadata, command_name, module) do
    %{
      duration: convert_duration(metadata[:duration]),
      entity_requirements: convert_entity_requirements(metadata[:requires_entities] || []),
      preconditions: metadata[:preconditions] || [],
      effects: metadata[:effects] || [],
      action_fn: Function.capture(module, command_name, 2),
      command: true,  # Mark as command for execution-time logic
      start_time: metadata[:start], # Add start_time
      end_time: metadata[:end] # Add end_time
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
