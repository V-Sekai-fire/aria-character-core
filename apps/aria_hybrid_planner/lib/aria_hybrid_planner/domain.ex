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

  # Type definitions for external API compatibility
  @type t :: term()
  @type action_name :: atom()
  @type task_name :: String.t()
  @type method_name :: String.t()
  @type action_fn :: function()
  @type task_method_fn :: function()
  @type goal_method_fn :: function()
  @type named_method :: {String.t(), function()}
  @type durative_action_name :: atom()
  @type durative_action :: map()
end
