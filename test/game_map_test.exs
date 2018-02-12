defmodule LifeBeyondApocalypse.GameMapTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  doctest GameMap
  def generate_map() do
    map = ~w"""
    #=#=#=#=#@@@@
    #=#=#=#=#@@@@
    #=#=#=#=#@@#@
    #=#=#=#=#@@@@
    #=#=#=#=#===#
    #=#=#=#=#@@@@
    #=#=#=#=#@@@@
    """
    {x, y} = {String.length(Enum.at(map,1)),length(map)}
    map = Enum.map(map, fn (x) -> String.split(x,"", trim: true ) end)
    |> Enum.map(fn (x) -> List.insert_at(x,-1,"\n") end)
    %{map: map, x: x, y: y}
  end


  setup do
      GameDatabase.load_database()
      User.start("Lord Praslea")
      User.set(%{x: 5, y: 5})
      GameMap.start_map("Țărâmul Zânelor",13,7)
    :ok
  end


  test "movement Location transform to actual location" do
    assert( GameMap.movement_location("ne") == "north-east"   )
    assert( GameMap.movement_location("8") == "north"   )
    assert( GameMap.movement_location("se") == "south-east"   )
    assert( GameMap.movement_location("south-west") == "south-west"   )
    assert( GameMap.movement_location("France") == :unknown   )
    :ok
  end

  test "Move out of bounds" do

    User.set(%{x: 1, y: 5})
    out_of_bounds = {:error, "You are at the edge of the map and can't move further in this direction."}
    assert(GameMap.move("west") == out_of_bounds   )
    User.set(%{x: 1, y: 1})
    assert(GameMap.move("north") == out_of_bounds   )

    User.set(%{x: 1, y: 2})
    assert(GameMap.move("north-west") == out_of_bounds   )

    User.set(%{x: 12, y: 7})
    assert(GameMap.move("south-east") == out_of_bounds   )

    User.set(%{x: 13, y: 5})
    assert(GameMap.move("east") == out_of_bounds   )

    User.set(%{x: 13, y: 7})
    assert(GameMap.move("south") == out_of_bounds   )

  end

  test "Not enough energy to move" do
    verify =   {:error, "You don't have enough energy to perform this action." }
    User.set(%{x: 10, y: 4, energy: 0})
    assert(GameMap.move("south") == verify   )
  end

  test "Move to new location decreasing energy and changing location" do
    User.set(%{x: 5, y: 5, energy: 7})
    {:ok, return_text } = GameMap.move("south")
    assert( User.get(:energy) == 6   )
    assert( String.match?(return_text, ~r/You moved to 5,6. You see a/iu)   )
  end

  test "LOw energy" do
    User.set(%{x: 5, y: 5, energy: 7})

    assert(
    String.match?(capture_io("",
      fn ->
      GameMap.move("south")
    end
    ),
    ~r/You are getting low on energy. You should find a safehouse to rest./iu)
    )
  end

  test "No such direction" do
    error = {:error, "That direction doesn't exist."}
    User.set(%{x: 5, y: 5, energy: 7})
    assert( GameMap.move("Kogaion") == error  )
  end
  
  test "Move and bounds" do
"""
iex> User.start("Lord Praslea")
iex> User.set(:x,5);  User.set(:y,5)
iex> GameMap.move("west")
{:ok, "You moved to 4,5"}
iex> GameMap.move("south")
iex> GameMap.move("east")
iex> GameMap.move("north")
{:ok, "You moved to 5,5"}
iex> GameMap.move("heaven")
{:error, "That direction doesn't exist."}
iex> GameMap.move("north")
iex> GameMap.move("north")
iex> GameMap.move("north")
iex> GameMap.move("north")
iex> GameMap.move("north")
iex> GameMap.move("north")
{:error, "You are at the edge of the map and can't move further in this direction."}
"""
  end

end
