# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaCore.ActionAttributes.Compiler do
  @moduledoc """
  Compilation-time processing for AriaCore.ActionAttributes.

  This module handles the @before_compile callback to process accumulated
  attribute metadata and register it with appropriate Domain systems.
  """

  @doc false
  defmacro __before_compile__(env) do
    # Extract all accumulated metadata from module attributes
    action_metadata = Module.get_attribute(env.module, :action_metadata, [])
    command_metadata = Module.get_attribute(env.module, :command_metadata, [])
    method_metadata = Module.get_attribute(env.module, :method_metadata, [])
    unigoal_metadata = Module.get_attribute(env.module, :unigoal_metadata, [])
    multigoal_metadata = Module.get_attribute(env.module, :multigoal_metadata, [])
    multitodo_metadata = Module.get_attribute(env.module, :multitodo_metadata, [])

    quote do
      # Define a function to register all metadata with Domain systems
      @doc false
      def __register_action_attributes__() do
        # Register actions with Domain system
        unquote(generate_action_registrations(action_metadata, env.module))

        # Register commands with Domain system
        unquote(generate_command_registrations(command_metadata, env.module))

        # Register task methods with Domain system
        unquote(generate_method_registrations(method_metadata, env.module))

        # Register unigoal methods with Domain system
        unquote(generate_unigoal_registrations(unigoal_metadata, env.module))

        # Register multigoal methods with Domain system
        unquote(generate_multigoal_registrations(multigoal_metadata, env.module))

        # Register multitodo methods with Domain system
        unquote(generate_multitodo_registrations(multitodo_metadata, env.module))

        :ok
      end

      # Provide metadata access for runtime inspection
      @doc false
      def __action_metadata__(), do: unquote(Macro.escape(action_metadata))

      @doc false
      def __command_metadata__(), do: unquote(Macro.escape(command_metadata))

      @doc false
      def __method_metadata__(), do: unquote(Macro.escape(method_metadata))

      @doc false
      def __unigoal_metadata__(), do: unquote(Macro.escape(unigoal_metadata))

      @doc false
      def __multigoal_metadata__(), do: unquote(Macro.escape(multigoal_metadata))

      @doc false
      def __multitodo_metadata__(), do: unquote(Macro.escape(multitodo_metadata))
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

          AriaCore.Domain.add_action(unquote(function_name), spec)
        end
      end)

    quote do: (unquote_splicing(registrations))
  end

  defp generate_command_registrations([], _module), do: nil

  defp generate_command_registrations(command_metadata, module) do
    registrations =
      Enum.map(command_metadata, fn {{function_name, _arity}, metadata} ->
        quote do
          spec = AriaCore.ActionAttributes.Converters.convert_command_metadata(
            unquote(Macro.escape(metadata)),
            unquote(function_name),
            unquote(module)
          )

          AriaCore.Domain.add_command(unquote(function_name), spec)
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

          AriaCore.Domain.add_task_method(unquote(function_name), spec)
        end
      end)

    quote do: (unquote_splicing(registrations))
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

          AriaCore.Domain.add_unigoal_method(unquote(function_name), spec)
        end
      end)

    quote do: (unquote_splicing(registrations))
  end

  defp generate_multigoal_registrations([], _module), do: nil

  defp generate_multigoal_registrations(multigoal_metadata, module) do
    registrations =
      Enum.map(multigoal_metadata, fn {{function_name, _arity}, metadata} ->
        quote do
          method_fn = AriaCore.ActionAttributes.Converters.convert_multigoal_metadata(
            unquote(Macro.escape(metadata)),
            unquote(function_name),
            unquote(module)
          )

          AriaCore.Domain.add_multigoal_method(unquote(function_name), method_fn)
        end
      end)

    quote do: (unquote_splicing(registrations))
  end

  defp generate_multitodo_registrations([], _module), do: nil

  defp generate_multitodo_registrations(multitodo_metadata, module) do
    registrations =
      Enum.map(multitodo_metadata, fn {{function_name, _arity}, metadata} ->
        quote do
          method_fn = AriaCore.ActionAttributes.Converters.convert_multitodo_metadata(
            unquote(Macro.escape(metadata)),
            unquote(function_name),
            unquote(module)
          )

          AriaCore.Domain.add_multitodo_method(unquote(function_name), method_fn)
        end
      end)

    quote do: (unquote_splicing(registrations))
  end
end
