defmodule Game.DrawMap do
  import GameUtilities
  require Logger

  @moduledoc  """
    Some experimenting done in creating HTML tileset files from the tinymap.
  """

  @doc  """
  Draw correct map from tiles

  """
  def drawmap() do
    random_tinymap = DataStorage.get_nested(:game_database, ["mapgen_tiles","house"])
    |> Enum.random()
    tinymap = DataStorage.get_nested(:game_database, ["mapgen",random_tinymap])
    json = File.read!("data/tilesets/MshockXotto+/tile_config.json")
    tile_config = Poison.decode!(json)
    tile_config_to_database(tile_config)
    generate_tinymap_tiles(tinymap)

  end

  defp write_to_file(file) do
    IO.puts(file, "<canvas id='tinymap-canvas'></canvas>")
    IO.puts(file, "<script src='./lba_tinymap.js'></script>")
    IO.puts(file, "<script src='./tile_config.js'></script>")
    IO.puts(file, "<div style='position:relative;top:15px;'>")
  end
  defp inspect_info(tinymap,terrain_furniture) do
    IO.inspect       tinymap["object"]["rows"]
    IO.inspect        terrain_furniture
    IO.inspect        tinymap["object"]["terrain"]
    IO.inspect        tinymap["object"]["furniture"]
  end

  def generate_tinymap_tiles(tinymap) do
    {:ok, file} = File.open("data/tilesets/MshockXotto+/tinymap.html", [:write])
    terrain_furniture = Map.merge(tinymap["object"]["terrain"],tinymap["object"]["furniture"])
    fill_terrain = tinymap["object"]["fill_ter"]

    write_to_file(file)
    inspect_info(tinymap,terrain_furniture)

    map = Enum.map(tinymap["object"]["rows"], fn (x) -> String.split(x,"", trim: true ) end)

    tinymap["object"]["rows"]
    |>  Enum.reduce(1,fn (row_list,y) ->
      row_list |> String.graphemes()
      |> Enum.reduce(1,fn (column_list,x) ->
        tile = get_tile_from_char(column_list,fill_terrain, terrain_furniture)

        tile_info = DataStorage.get_nested(:tile_config, [:id, tile])
        fg= tile_info["fg"] ;    bg = tile_info["bg"]

        if is_list(fg) do
          fg = fg |> Enum.random()
          if(!is_integer(fg), do: fg = fg["sprite"])
        end

    #    if tile == "t_wall" do
      #    r = tile_info["additional_tiles"]  |> Enum.at(2) # |> Enum.random
    #      bg = Map.get(r,"bg")
      #  end
      #  if(tile == "t_grass", do:     {bg,fg} = {3306,nil} )

      direction_rotation =  if(!is_nil(tile_info["multitile"]),
        do: handle_tile_direction_rotation(tile,x,y,map,fill_terrain,terrain_furniture), else:  {nil, nil, 0})
        generate_template({bg,fg},{x,y},tile_info,direction_rotation)
    #    IO.puts(file, generate_html_template({bg,fg},{x,y},tile_info))
        x + 1
      end)
      y + 1
    end)
    IO.puts(file,"</div>")
    File.close(file)
    save_tinymap_to_json()
    save_tile_config_to_json()
  end

  def get_tile_from_char(char,fill_terrain, terrain_furniture) do
    tile =   if(char == " ", do:  fill_terrain,  else: terrain_furniture[char])
    if(char == "t", do: tile= "f_toilet")

  #  if(tile == nil, do:  tile = fill_terrain)
    if tile == nil do
      Logger.error("Character #{char} has tile nil")
       tile = fill_terrain
     end
    tile
  end

    @doc  """
      Handle the tiles which need to be drawn in concordance to other tiles
      placed there
    """
    def handle_tile_direction_rotation(tile, x ,y ,map,fill_terrain,terrain_furniture) do
      max_x =24
      max_y = 24
      #4 directions for  maybe if needed all directions ["n","e","w","s","ne","nw","sw","se"]
      similair_tiles =  Enum.reduce(["n","e","w","s"],[], fn (direction, acc) ->
        {local_x, local_y} = direction   |>  GameMap.movement_location()
        |> GameMap.move_to(%User{x: x, y: y})
        if (local_x < max_x && 0 <= local_x && local_y < max_y && 0 <= local_y) do
          char = get(map, local_x-1, local_y-1)
          if get_tile_from_char(char,fill_terrain, terrain_furniture) == tile do
            #  IO.puts "char #{inspect char} acc #{inspect acc} direction #{inspect direction} #{x},#{y} "
            acc = acc ++ [direction]
          end
        end
        acc
      end)
      if similair_tiles  != []  do
        direction = similair_tiles |> Enum.sort() |> List.to_string
      final_direction =  cond do
          #center when it's effectively in the middle and n w e s are all indicated
          direction == "ensw" -> "center"
          # corner when  e n (90 rot),   n w(180 rot),  e s (0 rot),  s w (270rot)  are occupied
          direction in ~w/en nw es sw/ -> "corner"
          #edge when there are 2 opposite directions  n s(0 rot) or e w(90 rot)
          direction in ~w/ew ns/ -> "edge"
          #end_piece can connect to only one direction s(0rot) n(180rot) e(90rot) w(270 rot)
          direction in ~w/s n e w/ -> "end_piece"
          #t connection when  e n w - e s w
          direction in ~w/esw ens enw  nsw / -> "t_connection"
        end
        {final_direction, direction, direction_rotation(direction)}
      else
        #unconnected alone in the world
        {"unconnected",0, 0}
      end
    end

    def direction_rotation(direction) do
      case direction  do
        "ensw" -> 0 ;# center
        #corner
        "en" -> 270
        "nw" -> 180
        "es" -> 0
        "sw" -> 90
        #edge
        "ns" -> 0
        "ew" -> 90
        #end_piece
        "s" -> 0
        "n" -> 180
        "e" -> 270
        "w" -> 90
        #t_connection
        "esw" -> 0
        "nsw" -> 90
        "enw" -> 180
        "ens" -> 270
        _ -> 0
      end
    end

    def generate_template({bg,fg},{x,y},tile_info,{direction, location_direction, rotation}) do
        bg_image = tile_info["file"]
      #  [{bg, "bg"},{fg, "fg"}]
      #  |> Enum.reject(fn {fg, _z_index} -> is_nil(fg) end)
      #  |> Enum.map(fn {fg,z_index} ->
      [bg,fg]
      |> Enum.reject(fn fg -> is_nil(fg) end)
      |> Enum.map(fn fg ->
        z_index = "fg"
        if(fg == nil, do: {fg,z_index} = {bg,"bg"} )
        width = 32; height =32
        gid = fg
      #  additional = DataStorage.get_nested(:tile_config, [:id, gid, :additional])
        if !is_nil(direction) do
          gid_new = get_in(tile_info,[:additional,direction,"fg"])
        #  IO.puts "Direction #{direction} #{location_direction}  #{x},#{y} #{gid}  gid_new #{gid_new} #{inspect tile_info} \n ++++"

          if(gid_new != nil, do: gid = gid_new)
        end
        {column, row} = {rem(gid,16), div(gid,16) }

        json_map = %{width: width, height: height, column: column, row: row,
        rotation: rotation, gid: gid, x: x, y: y, bg_image: bg_image, z: z_index} ; #, tile_id: tile_info["id"]
        DataStorage.append(:json_tinymap,:map, json_map)
      end)
    end

    # Legacy HTML generation
    #TODO update this to the newesr version of the JS
    def generate_html_template({bg,fg},{x,y},tile_info) do
      bg_image = tile_info["file"]
  #  [{bg, 15},{fg, 17}]
    [{bg, "bg"},{fg, "fg"}]
    |> Enum.reject(fn {fg, _z_index} -> is_nil(fg) end)
    |> Enum.map(fn {fg,z_index} ->
      if(fg == nil, do: fg = bg)
      {column, row} = {rem(fg,16), div(fg,16) }

      width = 32; height =32 ; #z_index = 15
      #locx = rem(width * column,16*width)
      locx = width * column
      locy =  height * row
      left = x*width ; top = y * height
      rotationcss = 0
      x_class =  "x-#{x}"
      y_class =  "y-#{y}"
      bg_pos =  "bg-pos-#{column}-#{row}"
      json_map = %{width: width, height: height, column: column, row: row, gid: fg, x: x, y: y}
#TODO UPDATE css style
#css_style[column + "," + row] = useTemplate("bg-pos-style", {
#column: column, row: row, x: locx , y: locy  })
#	.bg-pos-{{column}}-{{row}} { background-position: -{{x}}px -{{y}}px }
      DataStorage.append(:json_tinymap,:map, json_map)
      """
      <div   class="#{z_index} img-1 r-#{rotationcss} #{x_class} #{y_class} #{bg_pos}">        </div>
      """

    end)

    end

#####################################################################
# Utility functions JSON to MAP and save to JSON again
#####################################################################
#WARNING! Needs care and optimizing like the json imported in game_database.ex !
  def tile_config_to_database(object) do
    DataStorage.start(:tile_config, DataStorage, :new, %{})
    DataStorage.start(:json_tinymap, DataStorage, :new, %{})
    DataStorage.set(:tile_config,:id, %{})
    DataStorage.set(:tile_config,:tile_info, object["tile_info"] |> Enum.at(0))
    DataStorage.set(:json_tinymap,:map,[])

    Enum.each(object["tiles-new"], fn (file_tile) ->
        file = file_tile["file"]
        Enum.each(file_tile["tiles"], fn (tile) ->
            id = tile["id"]
            tile = Map.put(tile, "file", file)

            if tile["multitile"] == true do
              additional =  Enum.reduce(tile["additional_tiles"], %{}, fn (i,acc) ->
                  new_id = i["id"]
                #          IO.puts "Additional #{inspect i} newid #{new_id}"
                  Map.put(acc,new_id, i)
              end)
                tile = Map.put(tile, :additional, additional)
            end
            tile = Map.delete(tile, "id")
            tile = Map.delete(tile, "additional_tiles")

            DataStorage.add(:tile_config,[:id, id], tile)
      end)
    end)
  end

  def save_tile_config_to_json() do
    File.write!("data/tilesets/MshockXotto+/tile_config.js",
    DataStorage.get_struct(:tile_config)
    |> Poison.encode!())
  end
  def save_tinymap_to_json() do
    json =   DataStorage.get_struct(:json_tinymap)
      |> Poison.encode!()
    File.write!("data/tilesets/MshockXotto+/tinymap.js", "var tinymap = " <> json )
  end


    #Replace empty with filler
  defp replace_empty() do
    ~S"""
    for x <- 1..24 do
      IO.puts ".x-#{x} { left: #{x*32-32}px; }"
    end

    for y <- 1..24 do
      IO.puts ".y-#{y} {  top: #{y*32-32}px ; }"
    end


    for x <- 1..16 do
      IO.puts ".bg-x-#{x} {  background-position-x: #{x*32}px ; }"
    end
    #should be 325 but png is empty from 8500px to 10400px
    for y <- 1..280 do
      IO.puts ".bg-y-#{y} {  background-position-y: #{y*32}px ; }"
    end
    """
      tinymap["object"]["rows"]
    |>  Enum.map(fn row ->
      Enum.map(fn column ->
          if (column == " ") do

          else
            column
          end
      end)
    end)

  end

end
