defmodule User do
  defstruct name: "", health: 50, max_health: 50, energy: 100, max_energy: 100,
      x: 5, y: 5, items: [], coins: 0, map_id: 1, experience: 0,
      attack: 3, defense: 3,      hunger: 0, thirst: 0, fatigue: 0,
      strength: 4, dexterity: 4, intelligence: 4, perception: 4,
      max_carry_weight: 1300 + 1600,
      focus: 100, actions: 0, morale: 100


  #import GameUtilities, only: [rand: 2, progress_bar: 2, colored_progress: 2]
  import GameUtilities, only: [colored_progress: 2]
  @storage :user_storage

  #Client API
  @doc  """
    Starts and names a process as :user_pid so we can save the user data.
    If the start function is ran multiple times, we verify if :user_pid already exists
    And return true anyway.

    ## Examples
    iex> User.start("Lord Praslea")
    true

  """
  def start(player_name)   do
    DataStorage.start(@storage, DataStorage, :new, %User{name: player_name})
  end

@doc  """
  Kills the process, this is used mainly for testing.
"""
  def destroy() do
    Process.exit(Process.whereis(@storage),:kill)
  end

  @doc  """
    Gets the value of a key from our process.

    The "key" can also be a list of keys and we expect a map to be returned.

    ## Examples
    iex> User.start("Lord Praslea")
    iex> User.set(:name,"Lord Praslea")
    iex> User.get(:name)
    "Lord Praslea"

    iex> User.start("Lord Praslea")
    iex> User.set(:energy,47)
    iex> User.set(:health,33)
    iex> User.get(~W/energy health/a)
    %{energy: 47, health: 33}

  """
  def get(key) do
    DataStorage.get(@storage,key)
  end

  @doc  """
    Returns the full user structure
  """
  def get_struct() do
      DataStorage.get_struct(@storage)
  end

  @doc  """
    Sets a key

    ## Examples
    iex> User.start("Lord Praslea")
    true
    iex> User.set(:energy,73)
    iex> User.get(:energy)
    73

  """
  def set(key,value) do
    DataStorage.set(@storage, key, value)
  end

  @doc  """
    Update multiple key, value pairs by using a map

    ## Examples
    iex> User.start("Lord Praslea")
    iex> User.set(%{energy: 25, health: 30, experience: 70})
    iex> User.get(:energy)
    25
    iex> User.get(:health)
    30
    iex> User.get(:experience)
    70
    iex> User.get(~W/energy health experience/a)
    %{energy: 25, experience: 70, health: 30}
  """
  def set(map) do
    DataStorage.set(@storage, map)
  end

  @doc  """
    Sets the full structure.

    ## Examples
    iex> User.start("Zamolxis")
    iex> user = %User{experience: 10}
    iex> User.set_struct(user)
    iex> user = Map.put(user,:coins,33)
    iex> User.set(:coins, 33)
    iex> user2 = User.get_struct()
    iex> user2 == user
    true
  """
  def set_struct(user) do
    DataStorage.set_struct(@storage, user)
  end

  @doc  """
    Increases the `key` by `incr`.
    If it does not exist we create it

    ## Examples
    iex> User.start("Lord Praslea")
    true
    iex> User.incr(:does_not_exist, 7)
    iex> User.incr(:does_not_exist, -2)
    iex> User.get(:does_not_exist)
    5

  """
  def incr(key,incr) do
    DataStorage.incr(@storage, key, incr)
  end

  @doc  """
    Gets the value of a key from our process.

    ## Examples
    iex> User.start("Lord Praslea")
    true
    iex> User.set(:test, [])
    iex> User.append(:test, 1)
    iex> User.append(:test, 3)
    iex> User.append(:test, 5)
    iex> User.append(:test, 7)
    iex> User.get(:test)
    [1, 3, 5, 7]

  """
  def append(key,item) do
    DataStorage.append(@storage, key, item)
  end

  # Game specific functions
  @doc  """
    Verify if the user has enough energy to perform an action.
    If he does, decrease the energy and return the appropiate message.
    IN the event he doesn't have enough energy return the appropiate message.

    This function depends on all 3 has_enough_energy  variants


    ## Examples
    iex> User.start("Lord Praslea")
    iex> User.set(%{energy: 5, max_energy: 10})
    iex> User.use_energy(1)
    {:ok, nil}
    iex> User.use_energy(3)
    {:rest,
    "You are getting low on energy. You should find a safehouse to rest. 1 energy left."}
    iex> User.use_energy(3)
    {:not_enough_energy, "You don't have enough energy to perform this action."}


  """
  def use_energy(decrease_energy) do
      user = User.get_struct()
     {reason, msg} =  has_enough_energy(user, decrease_energy)
     if reason in [:ok, :rest] do
       User.incr(:energy, -decrease_energy)
     end
     {reason, msg}
  end

  def has_enough_energy(%User{energy: energy, max_energy: max_energy}, decrease) when
    (energy - decrease) <=  (max_energy*0.25) and (energy - decrease) > 0  do
      msg = "You are getting low on energy. You should find a safehouse to rest. \
#{energy - decrease} energy left."
      IO.ANSI.format([:yellow, msg]) |> IO.puts
    {:rest, msg }
  end

  def has_enough_energy(%User{energy: energy}, decrease) when
    (energy - decrease) <= 0  do
    {:not_enough_energy, "You don't have enough energy to perform this action." }
  end

    def has_enough_energy(%User{energy: energy}, decrease) when
      (energy - decrease) > 0,  do:       {:ok, nil}

  def user_stats() do
user = User.get_struct()
"""
[Stats]:
#{IO.ANSI.format([:white, String.duplicate("=-", 33), :reset])}
Health: #{colored_progress(user.health,user.max_health)} (#{user.health}/#{user.max_health})
Energy: #{colored_progress(user.energy,user.max_energy)} (#{user.energy}/#{user.max_energy})
#{Enum.reduce(~w/attack defense coins experience /a,"", fn (x, acc) ->
title = Atom.to_string(x) |> String.capitalize
"#{acc}#{title}: #{Map.get(user,x)}\n"
end)}
Items in inventory: #{length(user.items)}
#{IO.ANSI.format([:white, String.duplicate("=-", 33), :reset])}
[/Stats]
"""
end


end
