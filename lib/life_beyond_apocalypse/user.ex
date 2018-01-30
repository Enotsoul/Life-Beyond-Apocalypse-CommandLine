defmodule User do
  defstruct name: "", health: 50, max_health: 50, energy: 100, max_energy: 100,
      x: 5, y: 5, items: [], coins: 0, map_id: 1, experience: 0, attack: 3, defense: 3

#Server API
  def new(user) do
   receive do
      {:get, key, pid} ->
        send pid, {:value, Map.get(user,key)}
      {:get_struct,pid} ->
        send pid, {:user, user}
      {:set,key,value} ->
       user = Map.put(user,key,value)
      {:set_struct, struct} -> user = struct
      {:incr,key,incr} -> user =  Map.update(user,key,incr, &(incr+&1))
      {:append,key,item} ->  user = Map.update(user, key, [item], &(&1 ++ [item]))
    end
    new(user)
  end

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
    if  Process.whereis(:user_pid) == nil do
      pid = spawn(User, :new, [%User{name: player_name}])
      Process.register(pid, :user_pid)
    end
    true
  end
  # Process.exit(Process.whereis(:user_pid),:kill)

  @doc  """
    Gets the value of a key from our process.

    ## Examples
    iex> User.start("Lord Praslea")
    iex> User.set(:name,"Lord Praslea")
    iex> User.get(:name)
    "Lord Praslea"

  """
  def get(key) do
    send(:user_pid, {:get, key, self()})
    receive do
      {:value, value} -> value
      5000 -> {:error, "Did not respond on time"}
    end
  end

  @doc  """
    Returns the full user structure
  """
  def get_struct() do
    send(:user_pid, {:get_struct, self()})
    receive do
      {:user, user} -> user
        5000 -> {:error, "Did not respond on time"}
    end
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
    send(:user_pid, {:set, key, value})
  end

  @doc  """
    Sets the full structure.

    ## Examples
    iex> user = %User{experience: 10}
    iex> User.set_struct(user)
    iex> user = Map.put(user,:coins,33)
    iex> User.set(:coins, 33)
    iex> user2 = User.get_struct()
    iex> user2 == user
    true
  """
  def set_struct(user) do
    send(:user_pid, {:set_struct, user})
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
    send(:user_pid, {:incr, key, incr})
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
    send(:user_pid, {:append, key, item})
  end





end
