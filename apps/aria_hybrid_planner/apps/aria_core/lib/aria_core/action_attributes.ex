# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaCore.ActionAttributes do
  @moduledoc """
  Action attributes system for AriaCore.

  This module provides the main interface for the action attributes system,
  delegating to specialized modules for different functionality areas.

  ## Attribute Types

  - `@action` - Defines action metadata (duration, entities, etc.)
  - `@command` - Execution-time logic with failure handling (ADR-181)
  - `@task_method` - Workflow decomposition strategies
  - `@unigoal_method` - Single goal achievement strategies
  - `@multigoal_method` - Multiple goal optimization strategies
  - `@multitodo_method` - Todo list optimization strategies

  ## Usage

      defmodule MyDomain do
        use AriaCore.ActionAttributes

        @action duration: "PT30M", requires_entities: [%{type: "agent"}]
        def cook_meal(state, [meal_id]) do
          # Implementation
        end

        @unigoal_method predicate: "meal_status"
        def achieve_meal_ready(state, [subject, value]) do
          # Goal achievement logic
        end
      end
  """

  # Delegate to specialized modules
  defdelegate multigoal_method_attribute_docs(), to: AriaCore.ActionAttributes.Documentation
  defdelegate multitodo_method_attribute_docs(), to: AriaCore.ActionAttributes.Documentation
  defdelegate action_attribute_docs(), to: AriaCore.ActionAttributes.Documentation
  defdelegate command_attribute_docs(), to: AriaCore.ActionAttributes.Documentation
  defdelegate task_method_attribute_docs(), to: AriaCore.ActionAttributes.Documentation
  defdelegate unigoal_method_attribute_docs(), to: AriaCore.ActionAttributes.Documentation

  defdelegate convert_multigoal_metadata(metadata, method_name, module), to: AriaCore.ActionAttributes.Converters
  defdelegate convert_multitodo_metadata(metadata, method_name, module), to: AriaCore.ActionAttributes.Converters
  defdelegate convert_action_metadata(metadata, action_name, module), to: AriaCore.ActionAttributes.Converters
  defdelegate convert_command_metadata(metadata, command_name, module), to: AriaCore.ActionAttributes.Converters
  defdelegate convert_method_metadata(metadata, method_name, module), to: AriaCore.ActionAttributes.Converters
  defdelegate convert_unigoal_metadata(metadata, method_name, module), to: AriaCore.ActionAttributes.Converters

  defdelegate create_entity_registry(action_metadata), to: AriaCore.ActionAttributes.Registry
  defdelegate create_temporal_specifications(action_metadata), to: AriaCore.ActionAttributes.Registry

  @doc false
  defmacro __using__(_opts) do
    quote do
      # Import attribute macros
      import AriaCore.ActionAttributes.Macros

      # Store metadata in module attribute for compilation-time processing
      Module.register_attribute(__MODULE__, :action_metadata, accumulate: true)
      Module.register_attribute(__MODULE__, :multigoal_metadata, accumulate: true)
      Module.register_attribute(__MODULE__, :multitodo_metadata, accumulate: true)
      Module.register_attribute(__MODULE__, :method_metadata, accumulate: true)
      Module.register_attribute(__MODULE__, :unigoal_metadata, accumulate: true)
      Module.register_attribute(__MODULE__, :command_metadata, accumulate: true)

      # Register raw attribute handlers for @action, @command, etc.
      Module.register_attribute(__MODULE__, :action, accumulate: true)
      Module.register_attribute(__MODULE__, :command, accumulate: true)
      Module.register_attribute(__MODULE__, :task_method, accumulate: true)
      Module.register_attribute(__MODULE__, :unigoal_method, accumulate: true)
      Module.register_attribute(__MODULE__, :multigoal_method, accumulate: true)
      Module.register_attribute(__MODULE__, :multitodo_method, accumulate: true)

      # Add function definition hook to process attributes
      @on_definition AriaCore.ActionAttributes.Compiler

      # Process metadata after compilation
      @before_compile AriaCore.ActionAttributes.Compiler
    end
  end
end
