# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSerial do
  @serial_number "R25W001ARXA"

  @moduledoc """
  Documentation for `AriaSerial`.
  """

  @doc "Returns the serial number for this module"
  def serial_number do
    case AriaSerial.JsonStorage.lookup_serial(@serial_number) do
      {:ok, _info} -> @serial_number
      {:error, _} -> @serial_number  # fallback
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
