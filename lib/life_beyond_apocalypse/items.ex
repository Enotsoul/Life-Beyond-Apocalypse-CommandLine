defmodule GameItems do
@items [
  %{name: "Pain Killers", type: :health, value: 5, price: 5 },
	%{name: "First Aid Kit", 	type: :health,  value: 10,  price: 10  },
  %{name: "Energizer",  type: :energy, value: 10,  price: 10 },

	%{name: "Baseball Bat" , type: :attack ,value:  2 ,accuracy: 50 ,price: 30 ,infection_chance: 4 },
	%{name: "Axe" , type: :attack ,value: 3 ,accuracy: 50 ,price: 70 ,infection_chance: 5 },
	%{name: "Kantana" , type: :attack ,value:  4 ,accuracy: 60 ,price: 100  ,infection_chance: 7},
	%{name: "Gun", type: :attack, accuracy: 50, requires: "Bullet", value: 5 ,price: 170 ,infection_chance: 13},

	%{name: "Basic Clothes" , type: :defense ,value: 2 ,price: 30 },
	%{name: "Advanced Clothes" , type: :defense ,value:  3 ,price: 70  },
	%{name: "Kevlar Clothing" , type: :defense ,value:  4 ,price: 100  },
	%{name: "Riot Gear" , type: :defense ,value:  5 ,price: 170  },

	%{name: "Canned Food",  type: :food,  value: 5 },
	%{name: "Water Bottle",  type: :water, value:  5 },

	%{name: "Survival Syringe", type: :revival, price: 50  },


	%{name: "Bullet" , type: :ammunition, price: 0.2 },
	%{name: "Battery" , type: :electronic, price: 5 },

  	%{name: "Flashlight" , type: :electronic, requires: "Battery", price: 30 },
  	%{name: "Mobile Phone" , type: :electronic, requires: "Battery", price: 50 },
]

  @item_limit 30

  def search() do
    if  length(User.get(:items)) < @item_limit do
      {reason, energy_msg}  = User.use_energy(1)
      if reason != :not_enough_energy do
         search_item(GameUtilities.rand(1,10))
       else
         {:error, energy_msg}
      end
    else
      {:error, "Before you start searching again, be sure you drop something since you're already carrying too many things (30 items limit)"}
    end
  end

  def search_item(chance) when chance > 5 do
    item = Enum.random(@items)
    User.set(:items, User.get(:items) ++ [ item])
    User.set(:experience,User.get(:experience) - 1)
    {:ok, item ,"You've found a(n) #{item.name}! +1 XP, -1 energy"}
  end

  def search_item(_) do
    {:error, "You've failed to find a usefull item. -1 energy"}
  end

  def items() do
    @items
  end
  def inventory() do
    {:ok, User.get(:items)}
  end

  def find_item(item_name) when is_binary(item_name) do
    item = Enum.find(User.get(:items), &String.match?(&1.name,~r/#{item_name}/iu))
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
      use_item(item.type, item)
    end

    def use_item(item_type, item) when item_type in [:energy,:health] do
      user = User.get_struct()
      if(item_type == :health, do: maximum = :max_health ,else: maximum = :max_energy )

      {atom, value} = cap_at_maximum(Map.get(user,maximum), Map.get(user,item_type), item.value)
      if atom in [:maximum,:ok] do

        {reason, energy_msg}  = User.use_energy(1)
        if reason != :not_enough_energy do
            User.set(item_type,value)
            drop_item(item)
         else
           {:error, energy_msg}
        end
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



end
