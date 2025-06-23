# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.Membrane.Migration.Format.FileData do
  @moduledoc """
  Format for file data flowing through the migration pipeline.
  """


  defstruct [
    :file_path,
    :content,
    :original_content,
    :transformations,
    :applicable_rules,
    :timestamp,
    :error
  ]

  @type t :: %__MODULE__{
    file_path: String.t(),
    content: String.t(),
    original_content: String.t(),
    transformations: [map()],
    applicable_rules: [atom()],
    timestamp: DateTime.t(),
    error: term() | nil
  }
end
