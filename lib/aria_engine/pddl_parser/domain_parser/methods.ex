# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaEngine.PddlParser.DomainParser.Methods do
  @moduledoc """
  Parses the methods section of a PDDL domain string.
  """
  # Removed unused aliases
  alias AriaEngine.PddlParser.DomainParser.Methods.Core

  def parse_method_block(method_content) do
    Core.parse_method_block(method_content)
  end
end
