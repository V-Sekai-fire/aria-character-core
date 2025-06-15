# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaFlow.ElementPad do
  @moduledoc """
  Represents a Membrane-style pad with demand-driven flow control.
  """
  defstruct [
    :name,
    :type,           # :input or :output
    :flow_control,   # :push or :pull
    :demand,         # current demand size
    :connected_to,   # {element_name, pad_name}
    :buffer_queue,   # queue of pending buffers
    :accepted_format,
    :demand_size
  ]
end
