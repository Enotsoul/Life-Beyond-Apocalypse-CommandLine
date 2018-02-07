defmodule Tinymap do
  import GameUtilities
  require Logger
  #################################################
  # Tinymap
  #################################################

  @doc  """
    This function examines the local tinymap at user's current position.

  """
  def examine_local_tinymap() do
    #TODO verify energy.. decrease eenrgy
    {reason, tinymap_tile} =  return_tile_info_for_user()
    if :ok == reason do
      examination_report(tinymap_tile)
    else
      IO.puts tinymap_tile
    end
  end

  def examination_report(tinymap_tile) do

    drawing = get_in(tinymap_tile, ["object","rows"])
    |> draw_tile()
  #  IO.puts "Hey Dude! #{inspect tinymap_tile} \n\n #{drawing}"

    describe(tinymap_tile) |> IO.puts
    IO.write drawing
    #TODO draw the "set" points
    #TODO place loot..
    #Todo search loot:)
    show_loot(tinymap_tile) |> List.to_string |> IO.write
  end

  def return_tile_info_for_user() do
    #TODO verify energy.. decrease eenrgy
    %{x: x, y: y} = User.get(~w/x y/a)
    tinymap = DataStorage.get_nested(:game_map, [:tinymap])
      |>   get(x-1,y-1) |> Map.get(:tinymap)
      {:ok, tinymap}
  #  get_tinymap_tile(tinymap)
  end



  def get_tinymap_tile(tile) when tile in ~w/V > < ^/ do
    json = File.read!("data/json/mapgen/house/house04.json")
    [house] = Poison.decode!(json)
    {:ok, house}
  end
  #   MapGenerator.draw_tinymap("V")  |> Enum.map(fn (x) -> x<> "\n" end) |> IO.puts
  #

  def get_tinymap_tile("road")  do
    # mall_a_27
    json = File.read!("data/json/mapgen/mall.json")
    mall = Poison.decode!(json)
    {:ok, find_in_list(mall, "om_terrain","mall_a_27")}
  end

  def get_tinymap_tile(_) do
      {:nothing, "You're in the middle of nowhere.. Nothing interesting to see"}
  end


  def find_in_list(list, key, value) do
     Enum.find(list, fn (object) ->
       existing = Map.get(object,key)
        if existing != nil do
         if(value in existing, do: true, else: false)
       end
     end)
  end

  @doc  """
    Add a newline at the end of each line
  """
  def draw_tile(tile_data) do
    tile_data |> Enum.map(fn (x) -> x<> "\n" end)
    # |> Enum.map(fn (x) -> x<> "\n" end) |> IO.puts
    #  |> Enum.map(fn (x) -> List.insert_at(x,-1,"\n") end)
  end

  #Ignore the chance.. it's used for finding
  def show_loot(tile) do
    loot_big = [get_in(tile,["object","place_loot"]), get_in(tile,["object","place_items"])]
    Enum.map(loot_big, fn loot ->
    #TODO each of the object or group must have a beautiful name translation
    if !is_nil(loot) do
    {map, _acc} =  Enum.map_reduce(loot, 0, fn (object,acc) ->
        group_or_item = if(object["group"] != nil, do:  object["group"], else: object["item"])
        name = GameDatabase.get_name(group_or_item)
        if(is_nil(name), do:
          name = String.replace(group_or_item,"_", " ") |> String.capitalize,
        else: name = name |> String.capitalize)

        x = get_object_xy(object,"x")
        y = get_object_xy(object,"y")
          {~s/(#{IO.ANSI.format([:magenta, Integer.to_string(acc)])}). #{IO.ANSI.format([:green, name])} at (#{x},#{y}), /, acc+1}
      end)
      Enum.into(map,["You can search the following points of interest: \n"])
    else
          "Nothing interesting to search..."
    end
    end)
  end

  def get_object_xy(object, loc) do
    if is_list(object[loc]) do
      [xy, _] =  object[loc]
    else
      xy = object[loc]
    end
    xy
  end

  @doc  """
  Describe the tile..
  """
  def describe(tile) do
    #TODO The terrain name should be taken from overmap_terrain,json
    [tile_terrain] = get_in(tile,["om_terrain"])

    description = Map.merge(get_in(tile,["object","terrain"]), get_in(tile,["object","furniture"]))
    tile_description = Enum.reduce(description, "", fn ({tile,id}, acc) ->
      name = GameDatabase.get_name(id) |> String.capitalize
        acc <> "#{IO.ANSI.format([:blue, tile])} <= " <> name <> ", "
    end)
    tile_terrain_name = GameDatabase.get_name(tile_terrain) |> String.capitalize
    """
      You are currently outside in front of a #{IO.ANSI.format([:magenta, tile_terrain_name])}.
      Each tinymap tile means the following:
      #{tile_description}
    """
  end

  #TODO show vehicles.
  #TODO DRAW vehicles..

  @doc  """
  Rotate a tinymap by 90 degrees starting from the topleft corner  counterclockwise clockwise
  NOTE: this ONLY works when MxN are the same size
  But since tinymaps are 24x24 it should work
  NOTE certain things like - and | need to be intechanged when rotating

  ## Examples
  iex>    tinymap = ~w/  ABCDE    FGHIJ    KLMNO    PQRTS    UVWXY    /
  iex> MapGenerator.rotate_tinymap(tinymap,3,true)
  [["E", "J", "O", "S", "Y"], ["D", "I", "N", "T", "X"],
  ["C", "H", "M", "R", "W"], ["B", "G", "L", "Q", "V"],
  ["A", "F", "K", "P", "U"]]

€
  """
  def rotate_tinymap(tinymap, rotation, split \\ false) when rotation <= 4 and rotation > 0 do
    if split do
      tinymap = Enum.map(tinymap, fn (x) -> String.split(x,"", trim: true ) end)
    end
    #THe important piece of art!
    tinymap =  tinymap |> Enum.reverse |> List.zip |> Enum.map(&Tuple.to_list/1)
    |> exchange_wall_characters()

    rotate_tinymap(tinymap, rotation-1, false)
  end

  def rotate_tinymap(tinymap, _rotation, _split) do
    tinymap
  end

  @doc  """
    This function iterates over the tinymap replacing "-" with "|"
    AND viceversa. Effectively beautifying our rotation of a map.

    This should be used when generating a map so we save computation in
    client-server environments instead of recalculating each time.
  """

  def exchange_wall_characters(tinymap) do
    Enum.map(tinymap, fn (row) ->
      Enum.map(row, fn (column) ->
        case column do
          "-" -> "|"
          "|" -> "-"
          _ -> column
        end
      end)
    end)
  end

  ######################################################
  # Tinymap generation functions (MapGenerator)
  ######################################################
  #If they don't exist look for abstract
  #THESE ARE PROBLEM FACTOS! we need to generate a random thing for most of these
  # for example we can generate buildings and fill them with items randomly..
  def random_tinymap_from_tilename(tile) when tile in
    ~w/forest forest_thick station_radio house_base spider_pit s_lot s_sports police  mil_surplus pawn/ do
    case tile do
      "road" ->
        #TODO not used yet
        DataStorage.get_nested(:game_database,["overmap_terrain_list","road"])
        "generate a  random road .."
      "house_base" -> random_tinymap_from_tilename("house")
      "pawn" ->
        random = DataStorage.get_nested(:game_database,["overmap_terrain_list", "pawn shop"])
        |> Enum.reject(fn (x) -> x == "pawn" end)
        |> Enum.random
        random_tinymap_from_tilename(random)
      "police" ->
          random = DataStorage.get_nested(:game_database,["overmap_terrain_list", "police station"])
          |> Enum.reject(fn (x) -> x == "police" end)
          |> Enum.random
          random_tinymap_from_tilename(random)
      _ ->
        # ===== TODO=====
        # TODO generate a forest automatically & in another clause..
        # ===== TODO=====
        # flags => ~w/TREE SHRUBS
        random = DataStorage.get_nested(:game_database,["overmap_terrain_list",
          "forest"])     -- ~w/forest forest_thick spider_pit/    |> Enum.random
          Logger.debug "Tile #{tile}  not supported.. else putting forest probably .. #{random}"
        random_tinymap_from_tilename(random)
    end
  end

  #Probably doesn't exist.. so we need to get a different type of random
  def random_tinymap_from_tilename(tile) do
    random_mapgen_id = DataStorage.get_nested(GameDatabase.get_database,["mapgen_tiles",tile])
      |> Enum.random
    DataStorage.get_nested(GameDatabase.get_database,["mapgen",random_mapgen_id])
  end


  @doc  """
    Get a terrain type by certain traits
    Like flags
  """
  def get_terrain_by_flags() do

  end
end
