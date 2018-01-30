defmodule LifeBeyondApocalypse.UserTest do
  use ExUnit.Case
  doctest User

  test "greets the world" do
    assert LifeBeyondApocalypse.hello() == :world
  end
end
