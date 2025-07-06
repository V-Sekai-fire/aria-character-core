# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

# Stub modules for aria_membrane_pipeline to prevent compilation warnings

unless Code.ensure_loaded?(AriaCore.Domain) do
  defmodule AriaCore.Domain do
    @moduledoc "Stub module for AriaCore.Domain"

    def new(_name), do: %{name: "stub-domain"}
    def enable_solution_tree(domain, _enabled), do: domain
  end
end

unless Code.ensure_loaded?(Membrane.Pipeline) do
  defmodule Membrane.Pipeline do
    @moduledoc "Stub module for Membrane.Pipeline"

    def notify_child(_pipeline_pid, _child_name, _message), do: :ok
  end
end
