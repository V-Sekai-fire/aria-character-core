defmodule AriaMathTest do
  use ExUnit.Case
  doctest AriaMath

  test "greets the world" do
    assert AriaMath.hello() == :world
  end
end
