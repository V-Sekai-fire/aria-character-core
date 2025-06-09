# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# SPDX-License-Identifier: MIT

defmodule AriaSecurityTest do
  use ExUnit.Case
  doctest AriaSecurity

  describe "AriaSecurity basic functionality" do
    test "hello/0 returns :world" do
      assert AriaSecurity.hello() == :world
    end

    test "module exists and is loaded" do
      assert Code.ensure_loaded?(AriaSecurity)
    end

    test "module has correct documentation" do
      {:docs_v1, _, :elixir, _, moduledoc, _, _} = Code.fetch_docs(AriaSecurity)
      assert moduledoc != :none
      assert String.contains?(moduledoc, "Security service")
    end
  end
end
