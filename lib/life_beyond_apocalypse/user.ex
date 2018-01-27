defmodule User do
  defstruct name: "", health: 30, energy: 100, x: 5, y: 5, items: %{}, coins: 0, map_id: 1

#Server API
  def new(user) do
    user = receive do
      {:get, key, pid} ->
        send pid, {:value, Map.get(user,key)}
        user
      {:get_struct,pid} ->
        send pid, {:user, user}
      {:set,key,value} ->
       Map.put(user,key,value)
      {:set_struct, struct} -> struct
    end
    new(user)
  end

#Client API
  def start(player_name) do
       pid = spawn(User, :new, [%User{name: player_name}])
      Process.register(pid, :user_pid)
  end

  def get(key) do
    send(:user_pid, {:get, key, self()})
    receive do
      {:value, value} -> value
      5000 -> {:error, "Did not respond on time"}
    end
  end

  def get_struct() do
    send(:user_pid, {:get_struct, self()})
    receive do
      {:user, user} -> user
        5000 -> {:error, "Did not respond on time"}
    end
  end

  def set(key,value) do
    send(:user_pid, {:set, key, value})
  end

  def set_struct(user) do
    send(:user_pid, {:set_struct, user})
  end

end
