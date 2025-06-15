# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaFlow.ElementBuffer do
  @moduledoc """
  Represents a buffer of data flowing through element pads.
  Similar to Membrane.Buffer but implemented for Flow processing.
  """
  defstruct [
    :payload,        # The actual data
    :metadata,       # Additional metadata
    :pts,           # Presentation timestamp
    :dts,           # Decode timestamp
    :size,          # Buffer size
    :stream_format, # Format of the stream
    :pad_name       # Which pad this buffer belongs to
  ]
end
