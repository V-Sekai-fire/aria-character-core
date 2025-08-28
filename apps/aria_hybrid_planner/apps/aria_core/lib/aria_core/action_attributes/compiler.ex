# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

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
    # Handle both single values and lists of accumulated attributes

    # Process @action attributes
    action_attrs = Module.get_attribute(module, :action) || []
    action_attrs = if is_list(action_attrs), do: action_attrs, else: [action_attrs]

    Enum.each(action_attrs, fn attr ->
      if attr != nil do
        Module.put_attribute(module, :action_metadata, {function_key, attr})
      end
    end)
    Module.delete_attribute(module, :action)

    # Process @command attributes
    command_attrs = Module.get_attribute(module, :command) || []
    command_attrs = if is_list(command_attrs), do: command_attrs, else: [command_attrs]

    Enum.each(command_attrs, fn attr ->
      if attr != nil do
        Module.put_attribute(module, :command_metadata, {function_key, attr})
      end
    end)
    Module.delete_attribute(module, :command)

    # Process @task_method attributes
    task_method_attrs = Module.get_attribute(module, :task_method) || []
    task_method_attrs = if is_list(task_method_attrs), do: task_method_attrs, else: [task_method_attrs]

    Enum.each(task_method_attrs, fn attr ->
      if attr != nil do
        Module.put_attribute(module, :method_metadata, {function_key, attr})
      end
    end)
    Module.delete_attribute(module, :task_method)

    # Process @unigoal_method attributes
    unigoal_attrs = Module.get_attribute(module, :unigoal_method) || []
    unigoal_attrs = if is_list(unigoal_attrs), do: unigoal_attrs, else: [unigoal_attrs]

    Enum.each(unigoal_attrs, fn attr ->
      if attr != nil do
        Module.put_attribute(module, :unigoal_metadata, {function_key, attr})
      end
    end)
    Module.delete_attribute(module, :unigoal_method)

    # Process @multigoal_method attributes
    multigoal_attrs = Module.get_attribute(module, :multigoal_method) || []
    multigoal_attrs = if is_list(multigoal_attrs), do: multigoal_attrs, else: [multigoal_attrs]

    Enum.each(multigoal_attrs, fn attr ->
      if attr != nil do
        Module.put_attribute(module, :multigoal_metadata, {function_key, attr})
      end
    end)
    Module.delete_attribute(module, :multigoal_method)

    # Process @multitodo_method attributes
    multitodo_attrs = Module.get_attribute(module, :multitodo_method) || []
    multitodo_attrs = if is_list(multitodo_attrs), do: multitodo_attrs, else: [multitodo_attrs]

    Enum.each(multitodo_attrs, fn attr ->
      if attr != nil do
        Module.put_attribute(module, :multitodo_metadata, {function_key, attr})
      end
    end)
    Module.delete_attribute(module, :multitodo_method)
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

    # Use the metadata collected by the @on_definition hook
    # No need for raw attribute processing since we handle it in the hook
    processed_action_metadata = action_metadata
    processed_command_metadata = command_metadata
    processed_method_metadata = method_metadata
    processed_unigoal_metadata = unigoal_metadata
    processed_multigoal_metadata = multigoal_metadata
    processed_multitodo_metadata = multitodo_metadata

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


  # Private helper functions for generating registration code

  defp generate_action_registrations([], _module), do: nil

  defp generate_action_registrations(action_metadata, module) do
    registrations =
      Enum.map(action_metadata, fn {{function_name, _arity}, metadata} ->
        quote do
          spec = AriaCore.ActionAttributes.Converters.convert_action_metadata(
            unquote(Macro.escape(metadata)),
            unquote(function_name),
            unquote(module)
          )

          # Store action spec for domain registration
          {unquote(function_name), spec}
        end
      end)

    quote do
      action_specs = [unquote_splicing(registrations)]
      Process.put({__MODULE__, :action_specs}, action_specs)
      :ok
    end
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
          spec = AriaCore.ActionAttributes.Converters.convert_method_metadata(
            unquote(Macro.escape(metadata)),
            unquote(function_name),
            unquote(module)
          )

          # Store method spec for domain registration
          {unquote(function_name), spec}
        end
      end)

    quote do
      method_specs = [unquote_splicing(registrations)]
      Process.put({__MODULE__, :method_specs}, method_specs)
      :ok
    end
  end

  defp generate_unigoal_registrations([], _module), do: nil

  defp generate_unigoal_registrations(unigoal_metadata, module) do
    registrations =
      Enum.map(unigoal_metadata, fn {{function_name, _arity}, metadata} ->
        quote do
          spec = AriaCore.ActionAttributes.Converters.convert_unigoal_metadata(
            unquote(Macro.escape(metadata)),
            unquote(function_name),
            unquote(module)
          )

          # Store unigoal spec for domain registration
          {unquote(function_name), spec}
        end
      end)

    quote do
      unigoal_specs = [unquote_splicing(registrations)]
      Process.put({__MODULE__, :unigoal_specs}, unigoal_specs)
      :ok
    end
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
