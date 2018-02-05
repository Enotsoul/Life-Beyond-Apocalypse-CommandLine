defmodule GameItems do
  @item_limit 30

  def search([point_of_interest | _y_location])  do
    verify_point_of_interest_before_searching(point_of_interest)
  end

  def verify_point_of_interest_before_searching(point_of_interest) do
      {reason, tinymap} = Tinymap.return_tile_info_for_user()
      if reason == :ok do
        has_looting?(point_of_interest,tinymap)
      else
        {:error, tinymap}
      end
  end
  def has_looting?(point_of_interest, tinymap) do
    object = tinymap["object"]
    if Map.has_key?(object,"place_loot") do
      item =  tinymap["object"]["place_loot"]
        |> Enum.find(fn (loot_object) ->
            if !is_nil(loot_object["group"]) do
              String.match?(loot_object["group"],~r/#{point_of_interest}/iu)
            end
        end)
        if item != nil do
          continue_searching(item, tinymap)
        else
          {:error, "No such point of interest, type examine to review your options and then search again."}
        end
      else
        {:error, "Nothing interesting exists to be looted here. Try another map."}
    end
  end

  def continue_searching(loot_object, _tinymap) do
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
  def search_item( loot_object)  do
      items =  DataStorage.get_nested(:game_database,["item_group",   loot_object["group"]])
      |> Map.get("items")
    #  Logger.debug "Items #{inspect items}"
      item = Enum.random(items)
      #TODO chance

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

      end
      if GameUtilities.rand(1,100) >= (100 - chance) do
      #  TODO count
        name = GameDatabase.get_name(item_id)
        item_for_inventory = {item_id,name}
        User.set(:items, User.get(:items) ++ [item_for_inventory])
        User.incr(:experience,1)
        ##{IO.ANSI.format([:bright,loot_object["group"]])
        #TODO inform user what he found
        search_text = "While searching through the <strong>#{loot_object["group"]}</strong>
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
      fn ({id, name}) ->
        #GameDatabase.get_name(&1)
          String.match?(name,~r/#{item_name}/iu)
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
        {:found, {item_id, item_name} } ->
            item_info = GameDatabase.get_item_info(item_id)
            IO.puts "You are examining #{item_name}:"
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

    end

    #TODO all other types including GUN

    #When all else fails..
    def examine_item_type(item_info) do
      IO.inspect item_info
    end

end
