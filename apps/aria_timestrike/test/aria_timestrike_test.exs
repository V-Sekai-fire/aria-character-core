# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTimestrikeTest do
  use ExUnit.Case
  doctest AriaTimestrike

  test "module loads successfully" do
    assert Code.ensure_loaded?(AriaTimestrike)
  end
end
