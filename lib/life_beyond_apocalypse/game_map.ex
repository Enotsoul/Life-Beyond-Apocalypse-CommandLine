defmodule GameMap do
  def map() do
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

  def move(location, user) do
    where_to = move_to(location,user)
    case verify_bounds(where_to,User.get(:map)) do
      {:ok, msg, {x,y}} ->
        IO.puts IO.ANSI.green  <> msg
        %User{ user | x: x, y: y}
        {:error, msg} ->
          IO.puts IO.ANSI.red  <> msg
          user
        end
      end

      defp move_to("west", %User{x: x, y: y}),  do: {x-1,y}
      defp move_to("east", user),  do:     {user.x + 1 ,user.y}
      defp move_to("north", user),  do: {user.x, user.y - 1 }
      defp move_to("south", user),  do:       {user.x,user.y + 1}
      #In case we get an invalid location, we just sit put
    #  defp  move_to(_where_to, user), do:    {user.x,user.y}


      defp verify_bounds({x,y}, %{x: max_x, y: max_y}) when x>=1  and y>=1 and max_x>= x and max_y>=y  do
        {:ok, "You moved to #{x},#{y}", {x,y}}
      end
      defp verify_bounds({_x,_y},_mapinfo) do
        {:error, "You are at the edge of the map and can't move further in this direction."}
      end

      def show_map(%User{x: x, y: y}) do
        map = map()
        text = IO.ANSI.format_fragment([:bright, :green, get(map.map,   x - 1,    y - 1), :reset, :white])
        IO.write  IO.ANSI.format([:white, set(map.map, x - 1, y - 1, text  )])
      end


      def get(arr, x, y) do
        arr |> Enum.at(x) |> Enum.at(y)
      end

      def set(arr, x, y, value) do
        List.replace_at(arr, x,
        List.replace_at(Enum.at(arr, x), y, value)
        )
      end
    end
