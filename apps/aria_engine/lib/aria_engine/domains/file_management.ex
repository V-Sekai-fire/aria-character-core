# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Domains.FileManagement do
  @moduledoc """
  Bridge module to AriaFileManagement domain.

  This module provides the expected interface for tests while delegating
  to the actual AriaFileManagement implementation.
  """

  require Logger

  @doc """
  Creates a file management domain.
  """
  def create_domain do
    if Code.ensure_loaded?(AriaFileManagement) do
      AriaFileManagement.create_domain()
    else
      Logger.debug("AriaFileManagement module not available")
      AriaEngine.Domain.new("file_management_fallback")
    end
  end

  @doc """
  Backup a single file.
  """
  def backup_file(state, args) do
    if Code.ensure_loaded?(AriaFileManagement) do
      AriaFileManagement.backup_file(state, args)
    else
      Logger.debug("AriaFileManagement.backup_file not available")
      false
    end
  end

  @doc """
  Replace a file safely.
  """
  def replace_file_safely(state, args) do
    if Code.ensure_loaded?(AriaFileManagement) do
      AriaFileManagement.replace_file_safely(state, args)
    else
      Logger.debug("AriaFileManagement.replace_file_safely not available")
      false
    end
  end

  @doc """
  Create directory structure.
  """
  def create_directory_structure(state, args) do
    if Code.ensure_loaded?(AriaFileManagement) do
      AriaFileManagement.create_directory_structure(state, args)
    else
      Logger.debug("AriaFileManagement.create_directory_structure not available")
      false
    end
  end

  @doc """
  Setup workspace.
  """
  def setup_workspace(state, args) do
    if Code.ensure_loaded?(AriaFileManagement) do
      AriaFileManagement.setup_workspace(state, args)
    else
      Logger.debug("AriaFileManagement.setup_workspace not available")
      false
    end
  end
end
