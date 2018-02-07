defmodule GameDatabase do
  require Logger

  @moduledoc  """
  This module imports all the JSON files linking them together
  Items
  Recipes
  Terrains
  Groups

  """

  @database :game_database

  def get_database() do
    @database
  end
  @doc  """
  Adds the data to the appropiate  object
  based on the type it adds the id
  """
  def add_to_appropiate_object() do

  end

  @doc  """
    Goes over all the files in the json folder and transforms each one
    into elixir data structures (lists, keys,maps)
    Then iterates over each one of them adding it to
    the appropiate key/value structure.

    At first we will use a nested structure.. maybe later we will convert it

    %GlobalMap{%"type" =>  %{"id" => "object" } }

    We know that each json file has a list of objects [{...},{...},{...},..]
   @TODO file which stores a sha1 hash of all JSON files
    if something has changed, go over the changed files
    reloading the data
  """
  def convert_all_json_to_elixir_data(json_folder \\ "data/json/",
    output_file \\ "data/game/life_beyond_apocalypse.db") do
    json_files = FileExt.ls_r(json_folder)
    DataStorage.start(@database, DataStorage, :new, %{})
    DataStorage.set(@database, :unique_mapgen_id, 1 )
    Enum.each(~w/uncraft names name_to_id mapgen mapgen_tiles overmap_terrain_list/,
        &create_category_for_type(&1, %{}))
    Enum.each(json_files, fn (file) ->
        #Logger.debug "Parsing file #{file}"
        json = File.read!(file)
        object_list = Poison.decode!(json)
        if is_list(object_list) do
             Enum.each(object_list, &handle_object(&1))
         else
            handle_object(object_list)
        end
    end)

    #Truncates map data:)
  #  File.write!(output_file, inspect(DataStorage.get_struct(@database), pretty: true))

    #{:ok, pid} =  File.open("data/game/regional_map_settings.map",[:write, :utf8])

    File.write!(output_file,:erlang.term_to_binary(DataStorage.get_struct(@database)))
    File.write!(output_file <> "map",
      inspect(DataStorage.get_struct(@database), pretty: true,
      printable_limit: :infinity, limit: :infinity))
  end

  @doc  """
    Loading the database file into our dedicated process in memory.
  """
  def load_database(db_file \\ "data/game/life_beyond_apocalypse.db") do
      database_from_file = File.read!(db_file) |> :erlang.binary_to_term
      DataStorage.start(@database, DataStorage, :new, %{})
      DataStorage.set_struct(@database,database_from_file)
  end

    @doc  """
    #Pattern matching fails if id, or abstract don't exist..
    #so we need to manually get the data
    #Map.Take is not what we're searching for either..

    The ID is usually either "id", "abstract" or "ident"
    I haven't observed other ID's but if a json object doesn't have other info

    TODO: type MONSTER_FACTION is again "special"
    since it seems that the "name" works like an ID.. will modify it later
    """

  def handle_object(object) do
    {id, ident, type, abstract, name} = { object["id"], object["ident"],
     object["type"],  object["abstract"], object["name"]}

    #IO.inspect object
    cond do
      !is_nil(id) ->
        create_category_for_type(type, %{})
        DataStorage.add(@database,[type,id], object)
      !is_nil(abstract) ->
        create_category_for_type(type, %{})
        DataStorage.add(@database,[type,abstract], object)
      type == "uncraft" ->
        DataStorage.add(@database,[type, object["result"]], object)
      !is_nil(ident) ->
        create_category_for_type(type, %{})
        DataStorage.add(@database,[type,ident], object)
      type == "mapgen" ->
          id = mapgen_building_tinymaps(object)
      true ->
        create_category_for_type(type, [])
        DataStorage.append(@database,type,object)
    end
    #TODO IDEA type "overmap_terrain" contains id's but maybe it's a good idea to do
    #something simiar for mapgen_building_tinymaps for the name & id:) in a list
    overmap_terrain_tinymaps(object,type)

    if !is_nil(name) and !(type in ~w/monstergroup/) do
        key = if(!is_nil(id), do: id, else: abstract)
        key = if(is_nil(key), do: ident, else: key)
        if is_nil(key) do
          Logger.warn "OOPS.. nil key for  #{inspect key} name #{inspect name} type #{inspect type} "
        end
        DataStorage.add(@database,["names",key],%{"name" => name, "type" => type})
    end
  end
  #Used for reverse searching when the user types certain names
  #The downside is that the user is more likely to mistype so we need to
  #Use enum find
#  DataStorage.add(@database,["name_to_id",object["name"]],key)

  def create_category_for_type(type, empty_struct_type) do
    if !DataStorage.exists(@database,type) do
    #   Logger.debug "Creating a new type #{type}"
       DataStorage.set(@database, type, empty_struct_type )
    end
  end

  @doc  """
    objects with the mapgen type don't have an id.
    When we generate a map we will need to group them by the "om_terrain"
    key value type. Let's generate a unique id mapgen_1234355
    We'll just use the GameDatabase with a key mapgen_unique_id which we will
    increment for each mapgen. Each object will be added under the mapgen key
    Afterwards we create another key mapgen_tiles which contains the "om_terrain"
    subkey and reference to the object id's

    This way we have a ordered way of handling map generation
  """
  def mapgen_building_tinymaps(object)  do
    type = object["type"]
    unique_mapgen_id = "mapgen_#{DataStorage.get(@database, :unique_mapgen_id)}"
    DataStorage.add(@database,[type,unique_mapgen_id], object)

    om_terrain = object["om_terrain"]
    if is_nil(om_terrain) do
      om_terrain = [object["nested_mapgen_id"]]
    end
  #  Logger.debug "What is om_terrain #{inspect om_terrain} for object:\n #{inspect object}"
    Enum.each(om_terrain, fn (terrain) ->
      existing_data =  DataStorage.get_nested(@database,["mapgen_tiles",terrain])
      if !is_nil(existing_data) do
        data = existing_data ++ [unique_mapgen_id]
      else
        data = [unique_mapgen_id]
      end
      DataStorage.add(@database,["mapgen_tiles",terrain], data)
    end)
    DataStorage.incr(@database, :unique_mapgen_id,1)
  end


  @doc  """
    Groups overmap terrains based on name & id
    Similair to mapgen_building_tinymaps
  """
  def overmap_terrain_tinymaps(object,type) when type == "overmap_terrain"  do
    name = object["name"]
    id = object["id"]

  #  Logger.debug "Overmap Terrain #{name} with id #{id}"
    if !is_nil(id) do
      existing_data =  DataStorage.get_nested(@database,["overmap_terrain_list",name])
      if !is_nil(existing_data) do
        data = existing_data ++ [id]
      else
        data = [id]
      end
      DataStorage.add(@database,["overmap_terrain_list",name], data)
    end
    overmap_terrain_tinymaps_mapgen(object,object["mapgen"])
  end

  def overmap_terrain_tinymaps(_,_), do: false

  @doc  """
    Some JSON files can contain overmap_terrain that contain mapgen   data..
    We need to build a new object and pass it to mapgen_building_tinymaps.
    I've only counted 15 such mapgen buildings, however
    the overmap_terrain.json file contains 31 mapgen for builtin generation .
    mods could contain more
  """
  def overmap_terrain_tinymaps_mapgen(object,mapgen) when mapgen != nil do
    Enum.each(mapgen, fn (single_mapgen) ->
      if Map.get(single_mapgen,"method") == "json" do
        newobject = single_mapgen
        |>  Map.put("om_terrain", [object["id"]])
        |> Map.put("type", "mapgen")
        mapgen_building_tinymaps(newobject)

      end
    end)
  end
  def overmap_terrain_tinymaps_mapgen(_object,_mapgen), do: false



  def get_all_keys_count(database) do
    Map.keys(database) |> Enum.each(fn (x) ->
      data = Map.get(database,x)
      if !is_list(data) do
        keys = data |> Map.keys() |> Enum.count
        IO.puts "#{x} has #{keys} keys"
      else
        keys = data |> Enum.count
        IO.puts "#{x} has #{keys} items in it's list"
      end

     end)
  end

  @doc  """
  Gets the name from the database for a certain key..
  """
  def get_name(key) do
    DataStorage.get_nested(@database,["names", key,"name"])
  end

  def get_type(key) do
    DataStorage.get_nested(@database,["names", key,"type"])
  end

  def get_item_info(key) do
    type = get_type(key)
  #  Logger.debug "Get item info #{key} type #{type} "
    DataStorage.get_nested(@database,[type, key])
  end

  @doc  """
    Goes over all the files in the json folder and transforms each one
    into elixir data structures (lists, keys,maps)
    Then saves the output to files in the data_folder.

    TODO file which stores a sha1 hash of all JSON files
    if something has changed, go over the changed files
    reloading the data
  """
  def convert_all_json_to_elixir_data_file(json_folder, data_folder) do
    #{:ok, pid} =  File.open("data/game/regional_map_settings.map",[:write, :utf8])
    #File.write!("data/game/regional_map_settings.map",inspect(city_data, pretty: true))
    #File.write!("data/game/regional_map_settings.term",:erlang.term_to_binary(city_data))
  end
end
