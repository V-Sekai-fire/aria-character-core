# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSerial do
  @moduledoc """
  Documentation for `AriaSerial`.
  """

  @doc "Returns the serial number for this module"
  def serial_number do
    case AriaSerial.JsonStorage.lookup_serial("R25W001ARXA") do
      {:ok, _info} -> "R25W001ARXA"
      {:error, _} -> "R25W001ARXA"  # fallback
    end
  end

  @doc """
  Hello world.

  ## Examples

      iex> AriaSerial.hello()
      :world

  """
  def hello do
    :world
  end
end
