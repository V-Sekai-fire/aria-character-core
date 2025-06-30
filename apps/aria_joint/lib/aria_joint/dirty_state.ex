# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaJoint.DirtyState do
  @moduledoc """
  Dirty state flag management for Joint nodes.

  Handles efficient tracking of what needs recomputation through
  dirty flags for transforms and hierarchy changes.
  """

  @type dirty_state() ::
    :dirty_none |
    :dirty_vectors |
    :dirty_local |
    :dirty_global |
    [:dirty_vectors | :dirty_local | :dirty_global]

  # Dirty state constants
  @dirty_none :dirty_none
  @dirty_vectors :dirty_vectors
  @dirty_local :dirty_local
  @dirty_global :dirty_global

  @doc """
  Add a dirty flag to current dirty state.
  """
  @spec add_dirty_flag(dirty_state(), atom()) :: dirty_state()
  def add_dirty_flag(@dirty_none, flag), do: flag
  def add_dirty_flag(current_flags, flag) when is_list(current_flags) do
    if flag in current_flags do
      current_flags
    else
      [flag | current_flags]
    end
  end
  def add_dirty_flag(current_flag, flag) when is_atom(current_flag) do
    if current_flag == flag do
      current_flag
    else
      [flag, current_flag]
    end
  end

  @doc """
  Remove a dirty flag from current dirty state.
  """
  @spec remove_dirty_flag(dirty_state(), atom()) :: dirty_state()
  def remove_dirty_flag(@dirty_none, _flag), do: @dirty_none
  def remove_dirty_flag(current_flags, flag) when is_list(current_flags) do
    remaining = List.delete(current_flags, flag)
    case remaining do
      [] -> @dirty_none
      [single_flag] -> single_flag
      multiple -> multiple
    end
  end
  def remove_dirty_flag(current_flag, flag) when is_atom(current_flag) do
    if current_flag == flag do
      @dirty_none
    else
      current_flag
    end
  end

  @doc """
  Check if dirty state has a specific flag.
  """
  @spec has_dirty_flag?(dirty_state(), atom()) :: boolean()
  def has_dirty_flag?(@dirty_none, _flag), do: false
  def has_dirty_flag?(current_flags, flag) when is_list(current_flags) do
    flag in current_flags
  end
  def has_dirty_flag?(current_flag, flag) when is_atom(current_flag) do
    current_flag == flag
  end

  @doc """
  Get the dirty_none constant.
  """
  @spec dirty_none() :: atom()
  def dirty_none, do: @dirty_none

  @doc """
  Get the dirty_vectors constant.
  """
  @spec dirty_vectors() :: atom()
  def dirty_vectors, do: @dirty_vectors

  @doc """
  Get the dirty_local constant.
  """
  @spec dirty_local() :: atom()
  def dirty_local, do: @dirty_local

  @doc """
  Get the dirty_global constant.
  """
  @spec dirty_global() :: atom()
  def dirty_global, do: @dirty_global
end
