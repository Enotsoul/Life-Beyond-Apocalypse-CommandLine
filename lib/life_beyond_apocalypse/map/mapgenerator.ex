defmodule MapGenerator do
  #┘┐┌└├┤┴┬│─┼

  import GameUtilities
  require Logger

  #THESE ARE SORTED!
  @road %{
    "nw" => "┘",
    "en" => "└",
    "sw" => "┐",
    "es" => "┌",
    "ns" => "│",
    "ew" => "─",
    "ensw" => "┼",
    "ens" => "├",
    "nws" => "┤",
    "enw" => "┴",
    "esw" => "┬"
  }



  def main(size_x \\ 50, size_y \\ 30) do

  end

  @doc  """
    Generates a new map with random building types and
    random tinymaps for each map tile.

  """
  def generate_new_map(name,size_x \\ 50, size_y \\ 30) do
      map = %{
        name: name,
      max_x: size_x,   max_y: size_y,
      map: generate_empty_map(size_x,size_y),
      mapdrawing: [],
    }
    #{center_x, center_y} = {round(size_x/2), round(size_y/2)}

    map =  generate_roads_linear(map, {rand(3, 6), rand(3, 8), 1})
    map =  Map.put(map,:mapdrawing,map.map)
    buildings_list = generate_building_tiles_for_city(map)
    map = place_building_next_to_road(map,1,1,buildings_list)
      |> draw_correct_road(1,1)
    map =  Map.put(map,:tinymap,map.map)
      |> generate_tinymaps(1,1)

    #The newline is important for the drawing of the map when rendering it to the user
      Map.put(map, :mapdrawing, Enum.map(Map.get(map,:mapdrawing),fn (x) -> List.insert_at(x,-1,"\n") end))
  #  map.map |> Enum.map(fn (x) -> List.insert_at(x,-1,"\n") end) |> IO.puts
  end



  #################################################
  # Road Generation Drunkard Walk
  #################################################

  def generate_road_drunkard_walk(map, location, count \\ 1)

  def generate_road_drunkard_walk(map, {x, y}, count ) when count < 50 do
    {direction, {next_x, next_y}} = next_road_location(map,"news", {x, y})
    if get(map.map, next_x - 1,next_y - 1) != "#" do
      generate_road_drunkard_walk(map, {x, y}, count + 1 )
    else
      map = Map.put(map,:map,set(map.map, next_x - 1 , next_y - 1, "H" )) # Map.get(@road,"ensw")))
      IO.puts "Generate road #{next_x},#{next_y}"
      generate_road_drunkard_walk(map, {next_x, next_y}, count + 2)
    end
  end
  def generate_road_drunkard_walk(map, {x, y}, count)  do
    map
  end


  #################################################
  # Road Generation Rectangle Roads
  #################################################

@doc  """
  Figure out map  size & split in size_x, x size_y chunks
  Generating a random street in each.
  Then connect the streets with eachother

"""
  def generate_rectangle_roads(%{max_x: max_x, max_y: max_y} = map,
  {incr_x, incr_y}, {next_x, next_y}  ) when next_x < max_x and next_y < max_y do

     #10 Pick 1 random x and random y location
     #TODO * 0.75
     rand_x = rand(next_x, (next_x+incr_x)-6 )
     rand_y = rand(next_y, (next_y+incr_y)-6 )
     #2. pick 2 random size (3,5) for x and y
     size_x = rand(2,5)
     size_y = rand(2,5)
    # Logger.debug "#{rand_x},#{rand_y} #{size_x},#{size_y}"
     #3. With these values you can create 4 points
     point1 = {rand_x, rand_y} # top left
     point2 = {rand_x+size_x, rand_y} # top right
     point3 = {rand_x, rand_y+size_y} # bottom left
     point4 = {rand_x+size_x, rand_y+size_y} # bottom right
     map = Enum.reduce([point1, point2, point3, point4], map,
      fn ({next_x, next_y},map) ->
      #     Logger.debug "Next values of point.. #{next_x},#{next_y} "
          Map.put(map,:map,set(map.map, next_x - 1 ,next_y - 1, "H" ))
      end)
     #4. draw roads between points
      # point1 -> point2
      #point1-> point3
      #point2->point4
      #point3-> point4
      map = draw_between_points(map,point1, point2)
      map =  draw_between_points(map,point1, point3)
      map =  draw_between_points(map,point2, point4)
      map =  draw_between_points(map,point3, point4)
     #5. Repeat process 1 - 4 multiple times

     #6. TODO draw roads between them
     # by creating a vertical and a horizontal line..
     key = (rand_x+size_x)*(rand_y+size_y) |> Integer.to_string
     map =  put_in(map, [:road_rectangles,key],{point1,point2,point3,point4})

#Note that we increase the max_y artifiially so the when kicks in whenever we go over it
     generate_rectangle_roads(map, {incr_x,incr_y},
     calc_x_y(next_x,next_y,max_x,max_y+5,incr_x,incr_y) )
  end

  def generate_rectangle_roads(%{max_x: max_x, max_y: max_y} = map, _, __) do
    #Get the keys from the map that are integers..
    keys = Map.keys(map) |> Enum.reduce([], fn (nr ,acc) ->
        if is_integer(nr) do
          acc = acc  ++ [nr]
        end
        acc
    end)
    # Now we only want to draw a few roads to not overcomplicate everything..
    #the roads should
    keys = Map.keys(Map.get(map,:road_rectangles))

    key_combinations = Enum.shuffle(keys)|> Enum.zip(keys)
    IO.puts "#{inspect keys} combinations #{inspect key_combinations}"
  map =  Enum.reduce(key_combinations, map, fn ({town1,town2},map) ->
        IO.puts "combinations #{town1},#{town2}"
      {town1_point1,town1_point2,town1_point3,town1_point4} = get_in(map,[:road_rectangles,town1])
      {town2_point1,town2_point2,town2_point3,town2_point4} = get_in(map,[:road_rectangles,town2])
      draw_between_points(map, town1_point1, town2_point1)
    end)

  #
    #TODO finish this maybe? 2 for loops.. draw points between all of them

     map
  end

  #################################################
  # Road Generation Linear Roads (Best one working)
  #################################################
  def generate_roads_linear(%{max_x: max_x, max_y: max_y} = map,
    {every_x, y, last_y}) when y < max_y do
      #Draw the horizontal line
      point1 = {1, y}
      point2 = {max_x, y}
      map = draw_between_points(map,point1, point2)

      #Draw multiple vertical lines
      total = round(max_x/every_x)
      map =   Enum.reduce(1..total, map,
       fn (next_x,map) ->
         next_x = next_x * every_x
           draw_between_points(map,{next_x,last_y},{next_x, y})
       end)
        generate_roads_linear(map, {rand(3, 7), rand(y + 3, y + 6), y})
  end
  def generate_roads_linear(map, _location_info) do
    map
  end


  #################################################
  # Utility functions
  #################################################

    def generate_empty_map(max_x,max_y) do
      full_map = for _y <- 1..max_y do
        String.duplicate("#",max_x) |> String.graphemes()
      end
      full_map
    end

  def draw_between_points(map,{x1,y1},{x2,y2}) do
    road =  "road" #"H"
     {x,y} = {abs(x1 - x2),abs(y1-y2)}
     {min_x, min_y} = {min(x1, x2),min(y1,y2)}
     #x = horizontal
     if x != 0 do
       map =   Enum.reduce(x1..x2, map,
        fn (next_x,map) ->
            Map.put(map,:map,set(map.map, next_x - 1 , min_y + y - 1, road ))
        end)
     end
     #y = vertical
     if y != 0 do
       map = Enum.reduce(y1..y2, map,
        fn (next_y,map) ->
            Map.put(map,:map,set(map.map, min_x + x - 1 , next_y - 1, road ))
        end)
     end
     map
  end

  def get_road_for_direction(direction) do
    case direction do
      "w" -> "ew"
      "e" -> "ew"
      "s" -> "ns"
      "n" -> "ns"
    end
  end

  def opposite_of(direction) do
    case direction do
      "w" -> "e"
      "e" -> "w"
      "s" -> "n"
      "n" -> "s"
    end
  end

  #Rotation type
  #http://langintro.com/elixir/article2/
  def get_house_direction(direction) do
    case direction do
      "w" -> "<"
      "e" -> ">"
      "s" -> "V"
      "n" -> "^"
      _ -> "O"
    end
  end

  def is_house_symbol(symbol)  when symbol in ~w/V > < ^/ do
      true
  end
  def is_house_symbol(_symbol) , do: false

  # Implement a function that starts from the centre going outwards..



    #################################################
    # Road GEneration  parent history  Algorithm
    #TODO needs modification
    #################################################
  def generate_random_starting_road(map, {x, y}) do
    {road, map_char} = Enum.random(@road)
      map = Map.put(map,:map,set(map.map, x - 1, y - 1, map_char))
      {map, road}
  end

  def next_road_location(map, current_road, {x, y}, exclude \\ []) do

    direction = current_road |> String.graphemes() |> Enum.sort()
    direction = direction -- exclude |> Enum.random()
#    direction = direction
    location = direction   |>  GameMap.movement_location()
    |> GameMap.move_to(%User{x: x, y: y})
    {next_x,next_y} = location
    #IO.puts "#{ get(map.map,next_y - 1, next_x - 1)}  #{get(map.map,y - 1, x - 1)}"
    if get(map.map, next_x - 1, next_y - 1) == "#" do
      {direction, location}
    else
      next_road_location(map,current_road, {x, y}, [opposite_of(direction)])
      #{direction, location}
    end
  end


#NOTE: this may have an issue if the current road is a corner
# since putting another corner is not efficient:)
#However le'ts hope it's a slight small chance to be this way
  def next_road(direction) do
    cond do
        !one_in(5) ->
            #4 out of 5 it's a straight road
            find_next_road(["ns","ew"], direction)
        one_in(3) ->
           #Otherwise  1 in 3 it might be a 4 way bifurcation
             "ensw"
        one_in(3) ->
           #3 way bifurcation
           roads = ["ens","nws" ,"enw" ,"esw"] |> Enum.shuffle
             find_next_road(roads,direction)
        true ->
          #  IF all else fails.. it's a corner
            roads =  ["nw","en","sw" ,"es"] |> Enum.shuffle
          find_next_road(roads,direction)
      end
  end

  def find_next_road(options, direction) do
    Enum.find(options, fn(x) ->
    #  IO.puts "#{direction} ==  #{String.graphemes(x)}"
      direction in  String.graphemes(x)
    end)
  end

  def generate_road(map, current_road, location, count \\ 1)

#TODO verify if where we want to put a road doesn't already have one..
#Go at it again..
  def generate_road(map, current_road, {x, y }, count ) when count <= 50 do
    #PUt a continuation on the last road generated
    count = count + 1
    {direction, {next_x, next_y}} = next_road_location(map, current_road, {x, y})
    road =  next_road(direction)
    map = Map.put(map,:map,set(map.map, next_x - 1 , next_y - 1, Map.get(@road,road)))
#IO.puts "Direction #{direction} Current Road #{current_road} #{x},#{y} next one #{road} #{next_x},#{next_y}"
      generate_road(map, road, {next_x,next_y}, count)

  end

    def generate_road(map, _current_road, {_x, _y }, _count )  do
        map
    end


    #################################################
    # Road drawing
    #################################################

@doc  """
  Takes a map where the roads have been added and draws the correct road junctions.
  Effectively replaces "H" by the special markers.
  It looks at each position if it's a road or not.
"""
    def draw_correct_road(%{max_x: max_x, max_y: max_y} = map, x,y, count \\ 1)
      when x <= max_x and y <= max_y and count < 20000 do
        {new_x,new_y} = calc_x_y(x,y,max_x,max_y+5)

        road_list = Map.values(@road) ++ ["H", "road"]

        if  get(map.map,  x- 1, y- 1) in road_list do
        existing_roads =  Enum.reduce(["n","e","w","s"],[], fn (direction, acc) ->
            {local_x, local_y} = direction   |>  GameMap.movement_location()
              |> GameMap.move_to(%User{x: x, y: y})
              char = get(map.map, max(rem(local_x,max_x+1),1)-1,  max(rem(local_y,max_y+1),1)-1)
              if char in road_list do
    #  IO.puts "char #{inspect char} acc #{inspect acc} direction #{inspect direction} #{x},#{y} "
                  acc = acc ++ [direction]
              end
              acc
          end)
          if existing_roads  != [] do
            direction = existing_roads |> Enum.sort() |> List.to_string
          #  IO.puts "existing_roads #{inspect existing_roads} direction #{direction}"
            if(String.length(direction) == 1, do: direction = get_road_for_direction(direction))
            map = Map.put(map,:mapdrawing,set(map.mapdrawing, x - 1 , y - 1, Map.get(@road,direction,"Z")))

          end
            count = count+1
        end

          draw_correct_road(map, new_x, new_y, count)
    end

    def draw_correct_road(map, _,_, _) do
      map
    end

    @doc """
      Given a current x and y location and the max_x and max_y
      it moves to the next x ,y location based off the increments given.
    """
    def calc_x_y(x,y ,max_x,max_y, incr_x \\1 , incr_y \\ 1) do
      new_x = max(rem(x+incr_x,max_x+1),1)
      new_y = y
      if x > new_x do
         new_y = max(rem(y+incr_y,max_y+1),1)
         new_x = 1
      end
      {new_x, new_y}
    end

    def road_list() do
       Map.values(@road) ++ ["H", "road"]
    end

    def get_building_overmap_symbol(building_name, color \\ nil)

    #Some buildings have issues (really, like real people)
    def get_building_overmap_symbol(building_name, _)
    when building_name in ~w/house_two_story_basement/ do
      {"F", "c_green"}
    end
  #  def get_building_overmap_symbol(building_name, color \\ nil) do
    def get_building_overmap_symbol(building_name, color) do
      overmap_terrain =   DataStorage.get_nested(GameDatabase.get_database,
      ["overmap_terrain",building_name])
      {sym,copy_from,tile_color} = {overmap_terrain["sym"],overmap_terrain["copy-from"],
      overmap_terrain["color"]}
    #  Logger.debug "Building_name #{building_name} - Sym #{sym} - copy_from #{copy_from} -      Overmap Terrain #{inspect overmap_terrain} "
      passed_color = if(is_nil(color), do: tile_color, else: color)
      if is_nil(sym) do
        #  key = if(!is_nil(id), do: id, else: abstract)
        if !is_nil(copy_from) do
          get_building_overmap_symbol(copy_from,passed_color)
        end
      else
        {<<sym>>, passed_color}
      end
    end

    #################################################
    # Building generation and drawing functions
    #################################################


    @doc  """
      Places buildings from the building_list V,>,<,^ next to roads so that they face the road.
      IN case of a building facing multiple roads a random position will be taken.

      The following line is meant to avoid infinite loops:)
            {new_x,new_y} = calc_x_y(x,y,max_x,max_y+5)
    """
    def place_building_next_to_road(%{max_x: max_x, max_y: max_y} = map,
      x,y,  buildings_list)
        when x <= max_x and y <= max_y and length(buildings_list) >= 1  do
          {new_x,new_y} = calc_x_y(x,y,max_x,max_y+5)
          road_list = road_list()
          if  get(map.map, x-1, y-1) == "#" do
          existing_roads =  Enum.reduce(["n","e","w","s"],[], fn (direction, acc) ->
              {local_x, local_y} = direction   |>  GameMap.movement_location()
                |> GameMap.move_to(%User{x: x, y: y})
                char = get(map.map,  max(rem(local_x,max_x+1),1)-1, max(rem(local_y,max_y+1),1)-1)
                if(char in road_list, do:  acc ++ [direction], else: acc)
            end)
            if existing_roads  != [] do

              direction = existing_roads |> Enum.sort() |> Enum.random() #|>  List.to_string
              [current_building | buildings_list] = buildings_list

            #  if(String.length(direction) > 1, do: direction = direction )
            #  IO.puts "#{x},#{y} - House next to road in #{inspect direction}"
            #IDEA have 2 maps, one with the name of each tile, another with the final drawing
              map = Map.put(map,:map,set(map.map, x - 1 , y - 1, current_building ))
              #TODO color hack
              {symbol, color} = get_building_overmap_symbol(current_building)
              color = return_color(color)
              if is_house_symbol(symbol) do
                symbol = get_house_direction(direction)
              end
              map = Map.put(map,:mapdrawing,set(map.mapdrawing, x - 1 , y - 1,
                IO.ANSI.format([[color], symbol])  ))
            #    Logger.debug "Great, placed building #{current_building} #{symbol} #{inspect color} "
            end
          end
        place_building_next_to_road(map, new_x, new_y, buildings_list)
    end
    def place_building_next_to_road(map, _x,_y, []) do
        map
    end
    def place_building_next_to_road(%{max_y: max_y} = map, _x,y, buildings) when  max_y < y do
      Logger.debug "Exceeding Y size of map, and still have unasigned buildings  #{length buildings} #{inspect buildings}"
        map
    end



@doc  """
Calculates total building occurence for the building types in a map.
Total possible buildings = mapsize - roads
Since houses would be the most we try to  tweak it increasing the shops likelyhood

Iterates over shops,parks houses and creates the correct calculation based on the weight.

Regional_map_settings is full of wonderful ideas.. to implement in the future
"""
  def generate_building_tiles_for_city(map) do
    total_buildings_list = calculate_buildings_for_city(map)
    #Building our big list
    total_buildings_list = total_buildings_list |> List.flatten
    full_buildings_list = Enum.map(total_buildings_list, fn ({name, building_count}) ->
      List.duplicate(name,building_count)
    end)
    |> List.flatten |> Enum.shuffle()

    full_buildings_list
  end

    def calculate_buildings_for_city(map) do
     city_data =  DataStorage.get_nested(GameDatabase.get_database,["region_settings","default"])
    #  Logger.debug "Citydata #{inspect city_data}"
      types = ["shops","parks","houses"]
      total_weight = calculate_building_weights(types, city_data)

      remaining_available_tiles = Enum.count(List.flatten(map.map), fn (x) ->
        if(x == "#", do: true, else: false)
      end)
      #First time i've used 2 for's in Elixir. Enum functions are better
      # probably should split this up in subfunctions or multiple enum reduces like above with total_weight
      priority = %{"houses" => 0.5 , "shops" => 2, "parks" => 1.5 }
      total_buildings_list =   for type <- types do
          multiply = Map.get(priority,type)
         for {name, individual_weight} <- get_in(city_data,["city",type]) do
           building_count = 0
           if name != "//" do
            building_count = round(remaining_available_tiles*(individual_weight*multiply/total_weight))
          #  IO.puts "#{name} has #{building_count} buildings"
          end
          {name, building_count}
         end
      end
      total_buildings_list
    end

    def calculate_building_weights(types, city_data)  do
       Enum.reduce(types,0, fn (type, calc) ->
          total = get_in(city_data,["city",type])
          |> Enum.reduce(0,fn ({_name, count},acc) ->
            if(is_integer(count), do: acc+count, else: acc)
        end)
        total + calc
      end)
    end

    def debug_calculation(_) do
      ~S"""
      mapsize = map.max_y*map.max_x
         total_buildings =  List.flatten(total_buildings_list) |> Enum.reduce(0,fn ({name, count},acc) -> count + acc end)
          IO.puts "mapsize #{mapsize} non road tiles: #{remaining_available_tiles}
        totalweight #{total_weight} total calculated buildings = #{total_buildings}"
"""
    end

    @doc  """
      For each tile in the map we will generate a random tinymap
      We will store these in map.tinymap as a structure map
      %{type: "house", tinymap: "tinymap data" }

      # For roads we'll do the infamous overmap terrain "mall_a_27"
      Untill we refactor our database for the _overmap_terrain type
    """
    def generate_tinymaps(%{max_x: max_x, max_y: max_y} = map,  x,y)
        when x <= max_x and y <= max_y   do
      {new_x,new_y} = calc_x_y(x,y,max_x,max_y+5)
    #  road_list = road_list()
      tile_name =  get(map.map, x-1, y-1)
      #TODO fix road and "unknown" tiles
      tile_name = case tile_name  do
        "road" -> "mall_a_27"
        "#" -> Enum.random(~w/orchard forest/)
        _  -> tile_name
      end
    #  Logger.debug "Tilename #{tile_name} at #{x},#{y}"

      {mapgen_id, tinymap}  = Tinymap.create_random_tinymap(tile_name)
      tile_map  = %{ type: tile_name, tinymap: tinymap, mapgen_id: mapgen_id}

      map = Map.put(map,:tinymap, set(map.tinymap, x - 1 , y - 1, tile_map))
      generate_tinymaps(map, new_x, new_y)
    end

    def generate_tinymaps(map, _x,_y) do
        map
    end

end
