defmodule GameMap do
  import GameUtilities

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
    {x, y} = {length(map), String.length(Enum.at(map,1))}
    map = Enum.map(map, fn (x) -> String.split(x,"", trim: true ) end)
    |> Enum.map(fn (x) -> List.insert_at(x,-1,"\n") end)
    %{map: map, x: x, y: y}
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
  def move(location) do
    user = User.get_struct()
    where_to = move_to(location,user)
    case verify_bounds(where_to,generate_map()) do
      {:ok, msg, {x,y}} ->
          IO.puts IO.ANSI.format([:green, msg])
          User.set_struct(%User{ user | x: x, y: y})
          {:ok, msg}
      {:error, msg} ->
          IO.puts IO.ANSI.red  <> msg <> IO.ANSI.reset
          {:error, msg}
      end
    end

      defp move_to("west", %User{x: x, y: y}),  do: {x-1,y}
      defp move_to("east", user),  do:     {user.x + 1 ,user.y}
      defp move_to("north", user),  do: {user.x, user.y - 1 }
      defp move_to("south", user),  do:       {user.x,user.y + 1}

      #In case we get an invalid location, we say it's unknown
      defp  move_to(_where_to, _user), do:    {:unknown}

      defp verify_bounds({:unknown}, _mapinfo), do: {:error, "That direction doesn't exist."}

      defp verify_bounds({x,y}, %{x: max_x, y: max_y}) when x>=1  and y>=1 and max_x>= x and max_y>=y  do
        {:ok, "You moved to #{x},#{y}", {x,y}}
      end
      defp verify_bounds({_x,_y},_mapinfo) do
        {:error, "You are at the edge of the map and can't move further in this direction."}
      end

      def show_map() do
        %User{x: x, y: y} = User.get_struct()
        map = generate_map()
        text = IO.ANSI.format_fragment([:bright, :green, get(map.map,   x - 1,    y - 1), :reset, :white])
        IO.write  IO.ANSI.format([:white, set(map.map, x - 1, y - 1, text  )])
      end


    end