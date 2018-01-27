defmodule LifeBeyondApocalypseTest do
  use ExUnit.Case
  doctest LifeBeyondApocalypse

  test "greets the world" do
    assert LifeBeyondApocalypse.hello() == :world
  end
end
