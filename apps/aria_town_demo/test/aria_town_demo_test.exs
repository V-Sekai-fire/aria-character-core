defmodule AriaTownDemoTest do
  use ExUnit.Case
  doctest AriaTownDemo

  test "greets the world" do
    assert AriaTownDemo.hello() == :world
  end
end
