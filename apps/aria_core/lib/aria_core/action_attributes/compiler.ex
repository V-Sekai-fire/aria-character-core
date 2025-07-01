# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaCore.ActionAttributes.Compiler do
  @moduledoc """
  Compilation-time processing for AriaCore.ActionAttributes.

  This module handles the @before_compile callback to process accumulated
  attribute metadata and register it with appropriate Domain systems.
  """

  @doc false
  def __on_definition__(env, kind, name, args, _guards, _body) do
    # Only process function definitions
    if kind == :def do
      # Check for pending attributes and associate them with this function
      check_and_store_attributes(env.module, {name, length(args)})
    end
  end

  defp check_and_store_attributes(module, function_key) do
    # Check for each attribute type and store with function key
    if action_attr = Module.get_attribute(module, :action) do
      Module.put_attribute(module, :action_metadata, {function_key, action_attr})
      Module.delete_attribute(module, :action)
    end

    if command_attr = Module.get_attribute(module, :command) do
      Module.put_attribute(module, :command_metadata, {function_key, command_attr})
      Module.delete_attribute(module, :command)
    end

    if task_method_attr = Module.get_attribute(module, :task_method) do
      Module.put_attribute(module, :method_metadata, {function_key, task_method_attr})
      Module.delete_attribute(module, :task_method)
    end

    if unigoal_attr = Module.get_attribute(module, :unigoal_method) do
      Module.put_attribute(module, :unigoal_metadata, {function_key, unigoal_attr})
      Module.delete_attribute(module, :unigoal_method)
    end

    if multigoal_attr = Module.get_attribute(module, :multigoal_method) do
      Module.put_attribute(module, :multigoal_metadata, {function_key, multigoal_attr})
      Module.delete_attribute(module, :multigoal_method)
    end

    if multitodo_attr = Module.get_attribute(module, :multitodo_method) do
      Module.put_attribute(module, :multitodo_metadata, {function_key, multitodo_attr})
      Module.delete_attribute(module, :multitodo_method)
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    # Extract all accumulated metadata from module attributes
    action_metadata = Module.get_attribute(env.module, :action_metadata, [])
    command_metadata = Module.get_attribute(env.module, :command_metadata, [])
    method_metadata = Module.get_attribute(env.module, :method_metadata, [])
    unigoal_metadata = Module.get_attribute(env.module, :unigoal_metadata, [])
    multigoal_metadata = Module.get_attribute(env.module, :multigoal_metadata, [])
    multitodo_metadata = Module.get_attribute(env.module, :multitodo_metadata, [])

    # Also extract raw attributes for compatibility
    raw_actions = Module.get_attribute(env.module, :action, [])
    raw_commands = Module.get_attribute(env.module, :command, [])
    raw_task_methods = Module.get_attribute(env.module, :task_method, [])
    raw_unigoal_methods = Module.get_attribute(env.module, :unigoal_method, [])
    raw_multigoal_methods = Module.get_attribute(env.module, :multigoal_method, [])
    raw_multitodo_methods = Module.get_attribute(env.module, :multitodo_method, [])

    # Convert raw attributes to metadata format
    processed_action_metadata = action_metadata ++ convert_raw_attributes(raw_actions, env)
    processed_command_metadata = command_metadata ++ convert_raw_attributes(raw_commands, env)
    processed_method_metadata = method_metadata ++ convert_raw_attributes(raw_task_methods, env)
    processed_unigoal_metadata = unigoal_metadata ++ convert_raw_attributes(raw_unigoal_methods, env)
    processed_multigoal_metadata = multigoal_metadata ++ convert_raw_attributes(raw_multigoal_methods, env)
    processed_multitodo_metadata = multitodo_metadata ++ convert_raw_attributes(raw_multitodo_methods, env)

    quote do
      # Define a function to register all metadata with Domain systems
      @doc false
      def __register_action_attributes__() do
        # Register actions with Domain system
        unquote(generate_action_registrations(processed_action_metadata, env.module))

        # Register commands with Domain system
        unquote(generate_command_registrations(processed_command_metadata, env.module))

        # Register task methods with Domain system
        unquote(generate_method_registrations(processed_method_metadata, env.module))

        # Register unigoal methods with Domain system
        unquote(generate_unigoal_registrations(processed_unigoal_metadata, env.module))

        # Register multigoal methods with Domain system
        unquote(generate_multigoal_registrations(processed_multigoal_metadata, env.module))

        # Register multitodo methods with Domain system
        unquote(generate_multitodo_registrations(processed_multitodo_metadata, env.module))

        :ok
      end

      # Provide metadata access for runtime inspection
      @doc false
      def __action_metadata__(), do: unquote(Macro.escape(processed_action_metadata))

      @doc false
      def __command_metadata__(), do: unquote(Macro.escape(processed_command_metadata))

      @doc false
      def __method_metadata__(), do: unquote(Macro.escape(processed_method_metadata))

      @doc false
      def __unigoal_metadata__(), do: unquote(Macro.escape(processed_unigoal_metadata))

      @doc false
      def __multigoal_metadata__(), do: unquote(Macro.escape(processed_multigoal_metadata))

      @doc false
      def __multitodo_metadata__(), do: unquote(Macro.escape(processed_multitodo_metadata))
    end
  end

  # Helper function to convert raw attributes to metadata format
  defp convert_raw_attributes(raw_attributes, _env) do
    # Raw attributes are stored in reverse order, so we need to reverse and pair with functions
    raw_attributes
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.map(fn {metadata, index} ->
      # For now, we'll create a placeholder function name since we can't easily
      # determine which function the attribute applies to at compile time.
      # In practice, we need a different approach - let's use an on_definition hook instead.
      {{:"raw_attribute_#{index}", 0}, metadata}
    end)
  end

  # Private helper functions for generating registration code

  defp generate_action_registrations([], _module), do: nil

  defp generate_action_registrations(action_metadata, module) do
    registrations =
      Enum.map(action_metadata, fn {{function_name, _arity}, metadata} ->
        quote do
          # TODO: Need proper domain instance management
          # For now, skip registration until Domain API is updated
          spec = AriaCore.ActionAttributes.Converters.convert_action_metadata(
            unquote(Macro.escape(metadata)),
            unquote(function_name),
            unquote(module)
          )

          # Store for later registration when domain instance is available
          # AriaCore.Domain.add_action(domain, unquote(function_name), spec)
          :ok
        end
      end)

    quote do: (unquote_splicing(registrations))
  end

  defp generate_command_registrations([], _module), do: nil

  defp generate_command_registrations(command_metadata, module) do
    registrations =
      Enum.map(command_metadata, fn {{function_name, _arity}, metadata} ->
        quote do
          # TODO: add_command/2 doesn't exist in AriaCore.Domain yet
          spec = AriaCore.ActionAttributes.Converters.convert_command_metadata(
            unquote(Macro.escape(metadata)),
            unquote(function_name),
            unquote(module)
          )

          # Store for later when command registration is implemented
          # AriaCore.Domain.add_command(domain, unquote(function_name), spec)
          :ok
        end
      end)

    quote do: (unquote_splicing(registrations))
  end

  defp generate_method_registrations([], _module), do: nil

  defp generate_method_registrations(method_metadata, module) do
    registrations =
      Enum.map(method_metadata, fn {{function_name, _arity}, metadata} ->
        quote do
          # TODO: Domain API expects 3 arguments (domain, name, spec)
          spec = AriaCore.ActionAttributes.Converters.convert_method_metadata(
            unquote(Macro.escape(metadata)),
            unquote(function_name),
            unquote(module)
          )

          # Store for later when domain instance management is implemented
          # AriaCore.Domain.add_method(domain, unquote(function_name), spec)
          :ok
        end
      end)

    quote do: (unquote_splicing(registrations))
  end

  defp generate_unigoal_registrations([], _module), do: nil

  defp generate_unigoal_registrations(unigoal_metadata, module) do
    registrations =
      Enum.map(unigoal_metadata, fn {{function_name, _arity}, metadata} ->
        quote do
          # TODO: Domain API expects 3 arguments (domain, name, spec)
          spec = AriaCore.ActionAttributes.Converters.convert_unigoal_metadata(
            unquote(Macro.escape(metadata)),
            unquote(function_name),
            unquote(module)
          )

          # Store for later when domain instance management is implemented
          # AriaCore.Domain.add_unigoal_method(domain, unquote(function_name), spec)
          :ok
        end
      end)

    quote do: (unquote_splicing(registrations))
  end

  defp generate_multigoal_registrations([], _module), do: nil

  defp generate_multigoal_registrations(multigoal_metadata, module) do
    registrations =
      Enum.map(multigoal_metadata, fn {{function_name, _arity}, metadata} ->
        quote do
          # TODO: add_multigoal_method/2 doesn't exist in AriaCore.Domain yet
          method_fn = AriaCore.ActionAttributes.Converters.convert_multigoal_metadata(
            unquote(Macro.escape(metadata)),
            unquote(function_name),
            unquote(module)
          )

          # Store for later when multigoal method registration is implemented
          # AriaCore.Domain.add_multigoal_method(domain, unquote(function_name), method_fn)
          :ok
        end
      end)

    quote do: (unquote_splicing(registrations))
  end

  defp generate_multitodo_registrations([], _module), do: nil

  defp generate_multitodo_registrations(multitodo_metadata, module) do
    registrations =
      Enum.map(multitodo_metadata, fn {{function_name, _arity}, metadata} ->
        quote do
          # TODO: add_multitodo_method/2 doesn't exist in AriaCore.Domain yet
          method_fn = AriaCore.ActionAttributes.Converters.convert_multitodo_metadata(
            unquote(Macro.escape(metadata)),
            unquote(function_name),
            unquote(module)
          )

          # Store for later when multitodo method registration is implemented
          # AriaCore.Domain.add_multitodo_method(domain, unquote(function_name), method_fn)
          :ok
        end
      end)

    quote do: (unquote_splicing(registrations))
  end
end
