# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngineCore.Domain do
  @moduledoc """
  External API for AriaEngineCore Domain functionality.

  This module provides the public interface for domain management within AriaEngineCore,
  delegating to appropriate internal modules while maintaining architectural boundaries.

  All cross-app communication should use this external API rather than importing
  internal AriaEngineCore.Domain.* modules directly.

  ## Domain Management

      # Create new domain
      domain = AriaEngineCore.Domain.new("my_domain")

      # Add actions
      domain = AriaEngineCore.Domain.add_action(domain, :move, action_fn)

      # Add methods
      domain = AriaEngineCore.Domain.add_method(domain, "transport", method_fn)

  ## Method Retrieval

      # Get task methods
      methods = AriaEngineCore.Domain.get_task_methods(domain, "transport")

      # Get unigoal methods
      methods = AriaEngineCore.Domain.get_unigoal_methods(domain, "location")
  """

  # Domain Creation and Management
  defdelegate new(), to: AriaEngineCore.Domain.Core
  defdelegate new(name), to: AriaEngineCore.Domain.Core
  defdelegate validate(domain), to: AriaEngineCore.Domain.Core
  defdelegate add_action(domain, action_name, action), to: AriaEngineCore.Domain.Core
  defdelegate get_durative_action(domain, action_name), to: AriaEngineCore.Domain.Core
  defdelegate set_entity_registry(domain, registry), to: AriaEngineCore.Domain.Core
  defdelegate get_entity_registry(domain), to: AriaEngineCore.Domain.Core
  defdelegate set_temporal_specifications(domain, specs), to: AriaEngineCore.Domain.Core
  defdelegate get_temporal_specifications(domain), to: AriaEngineCore.Domain.Core

  # Method Management - Delegate to Methods module
  defdelegate add_task_method(domain, task_name, method_name, method_fn), to: AriaEngineCore.Domain.Methods
  defdelegate add_unigoal_method(domain, predicate, method_name, method_fn), to: AriaEngineCore.Domain.Methods
  defdelegate add_unigoal_method(domain, predicate, method_fn), to: AriaEngineCore.Domain.Methods
  defdelegate add_multigoal_method(domain, method_name, method_fn), to: AriaEngineCore.Domain.Methods
  defdelegate add_multitodo_method(domain, method_name, method_fn), to: AriaEngineCore.Domain.Methods
  defdelegate get_task_methods(domain, task_name), to: AriaEngineCore.Domain.Methods
  defdelegate get_unigoal_methods(domain, predicate), to: AriaEngineCore.Domain.Methods
  defdelegate get_multigoal_methods(domain), to: AriaEngineCore.Domain.Methods
  defdelegate get_multitodo_methods(domain), to: AriaEngineCore.Domain.Methods

  # Action Management - Delegate to Actions module
  defdelegate execute_action(domain, state, action_name, args), to: AriaEngineCore.Domain.Actions
  defdelegate get_action_metadata(domain, action_name), to: AriaEngineCore.Domain.Actions

  # Method wrapper for different method types
  def add_method(domain, method_name, method_spec) do
    AriaEngineCore.Domain.Methods.add_method(domain, method_name, method_spec)
  end

  # Type definitions for external API compatibility
  @type t :: AriaEngineCore.Domain.Core.t()
  @type action_name :: AriaEngineCore.Domain.Core.action_name()
  @type task_name :: AriaEngineCore.Domain.Core.task_name()
  @type method_name :: AriaEngineCore.Domain.Core.method_name()
  @type action_fn :: AriaEngineCore.Domain.Core.action_fn()
  @type task_method_fn :: AriaEngineCore.Domain.Core.task_method_fn()
  @type goal_method_fn :: AriaEngineCore.Domain.Core.goal_method_fn()
  @type named_method :: AriaEngineCore.Domain.Core.named_method()
  @type durative_action_name :: AriaEngineCore.Domain.Core.durative_action_name()
  @type durative_action :: AriaEngineCore.Domain.Core.durative_action()
end
