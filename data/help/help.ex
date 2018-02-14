%{
  command_list: ~w/move map search inventory use examine look info see stats help drop quit/,
  commands: %{
    "quit" => "Quits the game",
    "help" => "?<topic>? - Shows this help screen and help topics about various commands",
    "move" => "<location> - Moves to the specified location. Valid options are: (w)est, (e)ast, (s)outh, (n)orth, (nw)north-west, (ne)north-east, (sw)south-west, (se)south-east ",
    "map" => "Shows the map with your current location colored in",
    "search" => "?<point of interest>? -  Search for an item. You can specify a point of interest as shown by the examine command.",
    "inventory" => "Shows all the items in your inventory",
    "use" => "<item> - Uses the item from your inventory.",
    "drop" => "<item> - Drops a certain item from your inventory",
    "examine" => "?<item|character|direction|keyword> -  Examines the given item, character, direction or keyword.
If you don't specify anything it examines the current location
Aliases: info, look, see",
    "save" => "?<filename>? - Saves your current game to disk.",
    "load" => "?<name>? - Shows you a list of all the saved game files you can load. Load a previously saved game.",
    "new_game" => "Creates a new world game and a new character",
    "stats" => "Displays information about your stats",
    },
    aliases:  %{
    }
}
