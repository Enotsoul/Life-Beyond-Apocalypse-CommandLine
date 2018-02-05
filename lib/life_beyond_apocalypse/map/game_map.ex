defmodule GameMap do
  import GameUtilities
  @moduledoc  ~S"""
    http://cddawiki.chezzo.com/cdda_wiki/index.php?title=Map

Overmap is the world map, what you see when you hit the m key, it is essentially
endless and can be limited only by external means.
Character can see five tiles on the overmap in any direction,
binoculars double that distance, but some structures still obstruct range of view.

Each overmap tile (e.g. house, crossroad, forest) equates to a single tinymap,
or 24x24 player-size tiles. Tinymap is not really used in the code much,
but it is available because it is more efficient than a map.

Map is 156x156 player-size tiles and used in normal gameplay;
the game has a map m, which is the area which is considered "in-play,"
inside which monsters, fields, traps, etc. will be processed.
Other than their respective sizes, map and tinymap are completely identical.

Both tinymap and map are formed of an array of submaps.
A submap is 12x12 player-sized tiles,
and also keeps track of any fields, items, traps,
and computers in that area.
Tinymap is made up of 2x2 submaps; map is made up of 13x13 submaps.

submap 12x12 player tiles
Tinymap 24x24 player-tiles  (2x2 submap)-> track fields, items, traps, computers
Tinymaps -> used inside
Map 156x156 player-size tiles (6.5 tiny maps) or 7 tiny maps 168x168
A map shows various "locations"
Overmap or world map=> Multiple maps

Enum.each(0..255, fn (c) ->
  IO.puts IO.ANSI.color(c) <> "COLOR #{c} HELLO THERE"

end)

http://cddawiki.chezzo.com/cdda_wiki/index.php?title=Map
http://cddawiki.chezzo.com/cdda_wiki/index.php?title=Terrain_types

  """

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

  def start_map(name \\ "Zombie City") do
    DataStorage.start(:game_map, DataStorage, :new,
      MapGenerator.generate_new_map(name, 48,24))
  end
  def get_map() do
      DataStorage.get_struct(:game_map)
  end

  @doc  """
    Moves the user to the chosen location.
    Can be north, south, west, east

    ## Examples
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
  def movement_location(location) do
    #  n nw ne s sw se e w north south west east north-west north-east
    #  south-west south-east 1 2 3 4 5 6 7 8 9
    cond  do
      location in ~w/ne north-east 9/ -> "north-east"
      location in ~w/n north 8/ -> "north"
      location in ~w/nw north-west 7/ -> "north-west"
      location in ~w/e east 6/ -> "east"
      # location in  ~w/center 5/ -> "center"
      location in   ~w/w west 4/ -> "west"
      location in   ~w/se south-east 3/ -> "south-east"
      location in   ~w/s south 2/ -> "south"
      location in   ~w/sw south-west 1/ -> "south-west"
      true -> :unknown
    end
  end

  def move(location) do
    #Logger.debug "Move to #{location}"
    user = User.get_struct()
    where_to = move_to(location,user)
    {reason, energy_msg}  = User.verify_energy(1)
    if reason == :ok do
      case verify_bounds(where_to,get_map()) do
        {:ok, msg, {x,y}} ->
          User.use_energy(1)
          move_the_player({reason, energy_msg}, msg, {x, y})
          {:error, msg} ->
            IO.puts IO.ANSI.red  <> msg <> IO.ANSI.reset
            {:error, msg}
          end
        else
          {reason, energy_msg}
        end
      end

    def move_the_player({reason, _energy_msg}, msg, {x,y}) when reason in [:rest, :ok] do
      IO.puts IO.ANSI.format([:green, msg])
    #  User.set_struct(%User{ user | x: x, y: y})
      User.set(%{x: x, y: y})
      {:ok, msg}
    end
    def move_the_player({reason, energy_msg}, _msg, {_x, _y}) when
      reason == :not_enough_energy, do: {:error, energy_msg}

    def move_to("west", %User{x: x, y: y}),  do: {x-1,y}
    def move_to("east", user),  do:     {user.x + 1 ,user.y}
    def move_to("north", user),  do: {user.x, user.y - 1 }
    def move_to("south", user),  do:       {user.x,user.y + 1}
    def move_to("north-west", user),  do: {user.x - 1, user.y - 1 }
    def move_to("north-east", user),  do: {user.x + 1, user.y - 1 }
    def move_to("south-west", user),  do:       {user.x - 1,user.y + 1}
    def move_to("south-east", user),  do:       {user.x + 1,user.y + 1}

    #In case we get an invalid location, we say it's unknown
    def  move_to(_where_to, _user), do:    {:unknown}

    def verify_bounds({:unknown}, _mapinfo), do: {:error, "That direction doesn't exist."}

      def verify_bounds({x,y}, %{max_x: max_x, max_y: max_y}) when x>=1  and y>=1 and max_x >= x and max_y >= y  do
        {:ok, "You moved to #{x},#{y}", {x,y}}
      end
      def verify_bounds({_x,_y},_mapinfo) do
        {:error, "You are at the edge of the map and can't move further in this direction."}
      end

      def show_map() do
        %User{x: x, y: y} = User.get_struct()
        map = get_map()
        text = IO.ANSI.format_fragment([:green_background, :light_yellow, get(map.map, y - 1, x - 1), :reset, :white])
        IO.write  IO.ANSI.format([:white, set(map.map,  y - 1,x - 1, text  )])
      end


    end
