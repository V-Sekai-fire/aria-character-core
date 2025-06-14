# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaTuiTest do
  use ExUnit.Case
  doctest AriaTui

  test "greets the world" do
    assert AriaTui.hello() == :world
  end
end
