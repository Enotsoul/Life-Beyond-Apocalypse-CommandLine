defmodule GameItems do
  require Logger
  import GameUtilities, only: [rand: 2]
  @item_limit 30



  #################################################
  # Search based on point of interest
  #################################################
  @doc """
    search based on point of interests
  """
  def search([point_of_interest | _y_location])  do
    verify_point_of_interest_before_searching(point_of_interest)
  end

  def verify_point_of_interest_before_searching(point_of_interest) do
     local_tinymap = Tinymap.return_tile_info_for_user()
      has_looting?(point_of_interest,local_tinymap)

  end
  @doc  """
    This function verifies if the current tinymap where the user is
    located at has the looting conditions the user typed and if they
    exist within the original mapgen.
    TODO requires fixing
  """
  def has_looting?(point_of_interest, %{mapgen_id: mapgen_id} = local_tinymap) do
    look_for_items_list = ~w/place_loot place_items/
    mapgen_tinymap =  DataStorage.get_nested(GameDatabase.get_database,["mapgen",mapgen_id])
    mapgen_object = mapgen_tinymap["object"]
    found_looting = Enum.reduce(look_for_items_list, {false,false,false}, fn (look_for, acc) ->
      {chance, item_name, id}  = has_looting_for(point_of_interest, mapgen_object, look_for)
      allowed_searchable = local_tinymap[:tinymap][String.to_atom(look_for)]
      if is_list(allowed_searchable) do
      #  IO.puts "#{look_for} : #{ok} - #{allowed_searchable}"
        if(id in   allowed_searchable, do: acc =   {chance, item_name, id})
      end
      acc
    end)
    {chance, item_name, _id} = found_looting
    Logger.debug  "Found looting #{inspect found_looting} "
    if chance != false do
      #The chance for searching a point of interest is 85% of the total chance..
      continue_searching({round(chance*0.85), item_name})
    else
      {:error, "No such point of interest or nothing to be searched here. Type examine to review your options."}
    end
    #      {:error, "No such point of interest, type examine to review your options and then search again."}
    #      {:error, "Nothing interesting exists to be looted here. Try another map."}
  end
  @doc  """
  We verify if the point of interest exists

  """
  def has_looting_for(point_of_interest, mapgen_object, look_for) do
    if Map.has_key?(mapgen_object,look_for) do

        {_acc, data} = Enum.reduce(  mapgen_object[look_for], {0, {nil,nil,nil}},
        fn (loot_object, {acc, data}) ->
         item_name =  cond do
             !is_nil(loot_object["group"])  ->
                loot_object["group"]
             !is_nil(loot_object["item"])  ->
                 loot_object["item"]
              true ->  ""
            end
            #TODO pass the chance?
            Logger.debug "comparing #{item_name} to #{point_of_interest}"
            if(String.replace(item_name,"_", " ") =~ point_of_interest,
              do: data = {loot_object["chance"], item_name, acc})
            {acc+1, data}
        end)
        data
      else
        {nil, nil,nil}
    end
  end



    @doc  """
      Search location  picking a random point of interest from the available
      place_loot and place_items
      Simple and clean method without the complications available with point of interests..

    """
    def search()  do
      %{mapgen_id: mapgen_id}  = Tinymap.return_tile_info_for_user()
      mapgen_tinymap =  DataStorage.get_nested(GameDatabase.get_database,["mapgen",mapgen_id])
      mapgen_object = mapgen_tinymap["object"]
      look_for_items_list = ~w/place_loot place_items/

      loot =  Enum.find(look_for_items_list, fn (i) ->
        mapgen_object[i] != nil
      end)
      if loot != nil do
        random_point_of_interest = mapgen_object[loot]
        |> Enum.shuffle |> Enum.random()
        item_or_group =  Enum.find(~w/group item/, fn (group) ->
          random_point_of_interest[group] != nil
        end)
        continue_searching({random_point_of_interest["chance"], random_point_of_interest[item_or_group]})
      else
        {:error, "There is nothing worth searching here!"}
      end
    end

  def continue_searching(loot_object) do
    if  length(User.get(:items)) < @item_limit do
      {reason, energy_msg}  = User.verify_energy(1)
      if reason == :ok do
         User.use_energy(1)
         search_item(loot_object)
       else
         {:error, energy_msg}
      end
    else
      {:error, "Before you start searching again, be sure you drop something since you're already carrying too many things (30 items limit)"}
    end
  end

    @doc  """
    #TODO allow theuser to succeed searching only a few times in the same tinymap
    #Restricting his searching for a few hours
    #Need to figure out a better algorithm out of these ideas
    Do 2 random verifications? One from the place_loot group/item object "chance"
    And the second from the item itself?

    1. I suppose the chance should be taken for all items and  add each success to a list
    Then just take that one by random out of that list
    This means throwing dice for 195 items if the user selects kitchen

    2. Taking the idea of the chance as a weight, adding it all together and then
    creating a list with ALL the items x times the weight
    Then taking a random item from that list.
    Again for 195 items it means creating a pretty big list.
    However with this one he always gets an item, guaranteed, which is not real gameplay.

    3. Just select a random item, do a chance.. if he's lucky ok, if not bad luck.


    Option 3 is the most efficient.
    Option 2 is the 2nd most efficient AND  realistic

    #TODO chance of the loot object is also important
    #For example guns_pistol_common have 5% while things in bed 90%
    #This means that we also need to do a randomness
    """
  def search_item({chance, group_name})  do
    item_list =  DataStorage.get_nested(:game_database,["item_group", group_name])
    if item_list != nil do
      item = item_list |> Map.get("items") |> Enum.random(item_list)
      if GameUtilities.rand(1,100) >= (100 - chance) do
        search_item_final(item,group_name)
      else
        search_failed()
      end
    else
      #Place_loot has  "group" and "item" but we ignore the later
      search_failed()
    end
  end

  def search_item_final(item,group_name) do
    {count_min, charges_min} = {nil,nil}
  #TODO a case implementation would work best
  #Since some item groups have other groups.......(INCEPTION!)
    if is_list(item) do
      [item_id, chance] =  item
    else
      #Probably a map  like    {"item": "fish_pickled", "prob":  6, "charges": 2, "container-item": "jar_glass_sealed"},
      #TODO Should package it in the container..?
      #rand(chages-min,charges-max) rand(count-min, count-max)
      #And other possibilities
      %{"item" => item_id, "prob" => chance } = item
      {charges_min, charges_max}  = {item["charges-min"] , item["charges-max"]}
      {count_min, count_max} = {item["count-min"], item["count-max"]}

    end
  #  Logger.debug "item #{item_id} chance #{chance}"
    cond do
      !is_nil(count_min) -> count = rand(count_min,count_max)
      !is_nil(charges_min) -> count = rand(charges_min,charges_max)
      true -> count =1
    end
    if GameUtilities.rand(1,100) >= (100 - chance) do
    #  TODO count
      name = GameDatabase.get_name(item_id)
      item_for_inventory = {item_id, name, count}
      User.set(:items, User.get(:items) ++ [item_for_inventory])
      User.incr(:experience,1)
      ##{IO.ANSI.format([:bright,loot_object["group"]])
      #TODO inform user what he found
      search_text = "While searching through the <strong>#{group_name}</strong>
       you've managed to find one <strong>#{name}</strong>! +1 XP, -1 energy"

      {:ok, item_id , String.replace(search_text, "\n"," ")}
    else
      search_failed()
    end
  end

  def search_failed() do
    {:error, "You started searching. You've failed to find a usefull item. Try searching again, maybe you missed a spot -1 energy"}
  end

 #This function is useless at the moment..
  def items() do

  end

  def inventory() do
    {:ok, User.get(:items)}
  end

  #TODO needs to be reimplemented.. since if we add an id it won't search correctly
  #Search based on name
  def find_item(item_name) when is_binary(item_name) do
    item = Enum.find(User.get(:items),
      fn ({id, name, count}) ->
        #GameDatabase.get_name(&1)
      #    String.match?(name,~r/#{item_name}/iu)
        String.downcase(name) =~ item_name
      end)
    if item == nil do
        {:notfound, ~s/You don't seem to have a(n) "#{item_name}" in your inventory/ }
    else
        {:found, item}
    end

  end

    def find_item(inventory_location) when is_integer(inventory_location) do
      {:notfound, "Inventory search by number is not implemented yet"}
    end

    def drop_item(item) do
      User.set(:items, User.get(:items) -- [ item])
      {:ok, item}
    end

    @doc  """
      Use a specific item

    ## Examples
    iex> User.start("Lord Praslea")
    iex> User.set_struct(%User{energy: 30, health: 25})
    iex> GameItems.use_item(  %{name: "Energizer",  type: :energy, value: 10,  price: 10 })
    iex> User.get(:energy)
    39
    iex> GameItems.use_item( %{name: "Pain Killers", type: :health, value: 5, price: 5 })
    iex> User.get(:health)
    30
    iex> GameItems.use_item( %{ type: :something_that_cannot_be_used })
    {:error, "This item cannot be used at the moment"}
    """
    def use_item(item) do
      use_item_energy(User.verify_energy(1), item)
    end
    def use_item_energy({:ok, _} ,item) do
      use_item(item.type, item)
    end
    def use_item_energy({:error, energy_msg} , _item) do
        {:error, energy_msg}
    end

    def use_item(item_type, item) when item_type in [:energy,:health] do
      user = User.get_struct()
      if(item_type == :health, do: maximum = :max_health ,else: maximum = :max_energy )

      {atom, value} = cap_at_maximum(Map.get(user,maximum), Map.get(user,item_type), item.value)
      if atom in [:maximum,:ok] do
          User.use_energy(1)
          User.set(item_type,value)
          drop_item(item)
      end
      {:ok, use_item_maximum_text(atom)
         |> EEx.eval_string([item: item, user: user, maximum: maximum])}
    end

    def use_item(_item_type, _item) do
         {:error, "This item cannot be used at the moment"}
    end


    #Tricky bit  ~S means NO interpolation
    defp use_item_maximum_text(atom) do
      map = %{ok: ~S"You have used <%= item.name %>. Your <%= item.type %> has been increased by <%= item.value %>",
      maximum: ~S"You have used <%= item.name %>. Your <%= item.type %> has hit the maximum of <%=Map.get(user,maximum)  %>",
      already_maximum: ~S"Your <%= item.type %> is already at the maximum. <%= item.name  %> has not been used"}
      Map.get(map, atom)
    end

    defp cap_at_maximum(maximum,current, _increase) when maximum == current   do
        {:already_maximum, maximum}
    end

    defp cap_at_maximum(maximum,current, increase) when maximum <= current + increase  do
        {:maximum, maximum}
    end

    defp cap_at_maximum(_maximum,current, increase)   do
      {:ok, current+increase}
    end

    #This should be added with all the other examine functions to
    #a examine module
    # IDEA: Transforming a list to a string by using Enum.join
    def examine_item(item_name_list) do
      item_name = item_name_list |> Enum.join(" ")
      case GameItems.find_item(item_name) do
        {:found, {item_id, item_name, _count} } ->
            item_info = GameDatabase.get_item_info(item_id)
            Logger.debug "You are examining #{item_name}:"
            examine_item_type(item_info)
        #    case GameItems.use_item(item) do
      #        {:ok, msg} ->   IO.ANSI.format([:green, msg]) |> IO.puts
      #        {:error, msg} ->   IO.ANSI.format([:red, msg]) |> IO.puts
      #      end
        {:notfound, msg} -> IO.puts IO.ANSI.format [:red,msg]
      end
    end


    def examine_item_type( %{"type" => type,
      "description" => description, "warmth" => warmth , "volume" => volume,
      "weight" => weight   } =item_info) when type == "ARMOR" do
      """
      Description: #{description}
      Material(s): #{Enum.join(item_info["material"],", ")}
      Weight: #{weight}  Volume: #{volume}  Warmth: #{warmth}
      """
      |> IO.puts

    end

    #TODO all other types including GUN

    #TODO type COMESTIBLE (food, water, etc..)

    #When all else fails..
    def examine_item_type(item_info) do
      IO.inspect item_info
    end

end
