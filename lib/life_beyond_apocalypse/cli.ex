defmodule LifeBeyondApocalypse.CLI do

  @tag ~S"""
 _     _  __        ____                             _
| |   (_)/ _| ___  | __ )  ___ _   _  ___  _ __   __| |
| |   | | |_ / _ \ |  _ \ / _ \ | | |/ _ \| '_ \ / _` |
| |___| |  _|  __/ | |_) |  __/ |_| | (_) | | | | (_| |
|_____|_|_|  \___| |____/ \___|\__, |\___/|_| |_|\__,_|
                               |___/
    _                          _
   / \   _ __   ___   ___ __ _| |_   _ _ __  ___  ___
  / _ \ | '_ \ / _ \ / __/ _` | | | | | '_ \/ __|/ _ \
 / ___ \| |_) | (_) | (_| (_| | | |_| | |_) \__ \  __/
/_/   \_\ .__/ \___/ \___\__,_|_|\__, | .__/|___/\___|
        |_|                      |___/|_|
"""

  @commands %{
    "quit" => "Quits the game",
    "help" => "?<topic>? - Shows help screen and help topics about various commands",
    "move" => "<location> - Moves to location. Valid options are: (w)est, (e)ast, (s)outh, (n)orth, (nw)north-west, (ne)north-east, (sw)south-west, (se)south-east ",
    "map" => "Shows the map with your current location colored in",
    "search" => "Shows the map with your current location colored in",
    "inventory" => "Shows all the items in your inventory",
    "use" => "<item> - Uses the item from your inventory.",
    "drop" => "<item> - Drops a certain item from your inventory",
    "stats" => "Displays information about your stats",
  }
  #  print_help_message()
  #{}"You should authenticate before doing anything else.	Available commands:
  #[color green]\[c\]onnect <username> ?<password>?[color reset] - to connect.
  #[color green]NEW <username> ?<password>? ?<email>?[color reset] - create a new character"
  #  user = %User{name: name}
  def main(_args) do
    IO.puts(@tag)
    name =  read_text("What is your name dear adventurer?")
    IO.puts "Welcome to LifeBeyondApocalypse #{name}!"
    User.start(name)
    read_command(IO.ANSI.format([:italic,"To find out more about a topic type", :magenta, " help <topic>"]))
  end

  defp read_text(text) do
     IO.gets("\n#{text} > ")
     |> String.trim
  end

  defp read_command(text \\ "") do
    IO.gets("\n#{text} > ")
    |> String.trim
    |> String.downcase
    |> String.split(" ")
    |>  execute_command
  end

  defp execute_command(["quit"]) do
    IO.puts "\nThanks for playing Life Beyond Apocalypse. Have a nice day!"
  end
  defp execute_command(["help"]) do
    print_help_message()
    read_command()
  end

  defp execute_command(["move" | location]) do
    GameMap.move(List.to_string(location) )
    read_command()
  end

  defp execute_command([movement_location]) when
  movement_location in ~w/n nw ne s sw se e w 1 2 3 4 5 6 7 8 9
  north south west east north-west north-east  south-west south-east / do
    if(is_integer(movement_location), do: Integer.to_string, else: movement_location)
    |>   GameMap.movement_location
    |>  GameMap.move
    read_command()
  end


  defp execute_command(["map"]) do
    GameMap.show_map()
      read_command()
  end

  defp execute_command(["stats"]) do
      User.user_stats() |> IO.write
      read_command()
  end

  defp execute_command(["search"]) do
    case GameItems.search() do
      {:ok, _item, msg} -> IO.puts IO.ANSI.format([:green, msg])
      {:error, msg} -> IO.puts IO.ANSI.format([:red, msg])
    end
    read_command()
  end

  defp execute_command(["inventory"]) do
    {:ok, items} = GameItems.inventory()
    IO.puts "Inventory consists of #{length items} items:"
      for {item,nr} <- Enum.with_index(items)  do
        IO.puts "(#{nr}) #{item.name} +#{item[:value]} #{item.type |>  Atom.to_string |> String.upcase }"
      end
      IO.puts "Commands to be used with items: use, info, drop"
    read_command()
  end

  @doc """
  Handles the commandline drop function of an item based on the partial name or inventory location
  """
  defp execute_command(["drop" | item_name]) do
      item_name = List.to_string item_name
      integer = Integer.parse(item_name)
      if(integer == :error, do: name_or_number = item_name, else: name_or_number = integer)
      case GameItems.find_item(name_or_number) do
        {:found, item } ->
          response = IO.ANSI.format([:italic,  "Are you sure you want to drop ",
           :green, item.name, " ?", :magenta, " [Y]es/[N]o"]) |> read_text
          if String.match?(response,~r/y(es)|true|ok/iu) do
              GameItems.drop_item(item)
              IO.ANSI.format([:green, "You have dropped #{item.name} from your inventory"])
              |> IO.puts
          else
            IO.puts "You have decided NOT to drop the item."
          end
        {:notfound, msg} -> IO.puts IO.ANSI.format [:red,msg]
      end
      read_command()
  end


  defp execute_command(["use" | item_name]) do
      item_name = List.to_string item_name
      integer = Integer.parse(item_name)
      if(integer == :error, do: name_or_number = item_name, else: name_or_number = integer)
      case GameItems.find_item(name_or_number) do
        {:found, item } ->
            case GameItems.use_item(item) do
              {:ok, msg} ->   IO.ANSI.format([:green, msg]) |> IO.puts
              {:error, msg} ->   IO.ANSI.format([:red, msg]) |> IO.puts
            end

        {:notfound, msg} -> IO.puts IO.ANSI.format [:red,msg]
      end
      read_command()
  end




  defp execute_command(_unknown) do
    IO.puts("\nUnknown command. Try help <topic>.")
    print_help_message()
    read_command()
  end

  defp print_help_message() do
    IO.puts("\nLife Beyond Apocalypse supports the following commands:\n")
    @commands
    |> Enum.map(fn({command, description}) -> IO.puts("  #{command} - #{description}") end)
    IO.puts "Type help <command> to find out more about a specific command"
  end

end
