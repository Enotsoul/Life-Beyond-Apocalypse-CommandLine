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
    "move" => "<location> - Moves to location. Valid options are: (w)est, (e)ast, (s)outh, (n)orth ",
    "map" => "Shows the map with your current location colored in",
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
    user = %User{name: name}
    read_command("To get started type in a command, or help", user)
  end

  defp read_text(text) do
     IO.gets("\n#{text} > ")
     |> String.trim
  end

  defp read_command(text \\ "", user) do
    IO.gets("\n#{text} > ")
    |> String.trim
    |> String.downcase
    |> String.split(" ")
    |>  execute_command user
  end

  defp execute_command(["quit"],_user) do
    IO.puts "\nThanks for playing Life Beyond Apocalypse. Have a nice day!"
  end
  defp execute_command(["help"],user) do
    print_help_message()
    read_command(user)
  end

  defp execute_command(["move" | location],user) do
    GameMap.move(List.to_string(location), user )
    read_command(user)
  end

  defp execute_command(["map"],user) do
    GameMap.show_map(user)
      read_command(user)
  end


  defp execute_command(_unknown,user) do
    IO.puts("\nUnknown command. Try help <topic>.")
    print_help_message()

    read_command(user)
  end

  defp print_help_message() do
    IO.puts("\nLife Beyond Apocalypse supports the following commands:\n")
    @commands
    |> Enum.map(fn({command, description}) -> IO.puts("  #{command} - #{description}") end)
  end

end
