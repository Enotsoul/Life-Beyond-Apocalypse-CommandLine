defmodule DataStorage do
  @moduledoc  """
  Data Storage Abstraction  that uses processes with send/recieve
  """

  #Server API
    def new(data_structure) do
     receive do
        {:get, key, pid} ->
          if  is_list(key) do
            return_data = Map.take(data_structure,key)
          else
            return_data = Map.get(data_structure,key)
          end
          send pid, {:value, return_data}
        {:get_nested, keys, pid} ->
          return_data = get_in(data_structure,keys)
          send pid, {:get_nested, return_data}
        {:get_struct,pid} ->
          send pid, {:data_structure, data_structure}
        {:set, key, value} ->
            data_structure = Map.put(data_structure,key,value)
         {:set, mapped_values} ->
            data_structure = Map.merge(data_structure, mapped_values)
        {:set_struct, structure} -> data_structure  = structure
        {:incr, key, incr} -> data_structure =  Map.update(data_structure,key,incr, &(incr+&1))
        {:append,key,item} ->  data_structure = Map.update(data_structure, key, [item], &(&1 ++ [item]))
        {:add, keys, value} ->
            data_structure = put_in(data_structure,keys,value)
        {:exists, key , pid} ->
            send pid, {:exists, Map.has_key?(data_structure,key)}

      end
      new(data_structure)
    end

    #Client API
    @doc  """
      Start a DataProcess
    """
    def start(process_name,module,function,data)   do
      if  Process.whereis(process_name) == nil do
        pid = spawn(module, function, [data])
        Process.register(pid, process_name)
      end
      true
    end
    # Process.exit(Process.whereis(:user_pid),:kill)

    @doc  """
      Gets a key from the process
      Either a simple key, a list of keys  using the Take
      """
    def get(process, key) do
      send(process, {:get, key, self()})
      receive do
        {:value, value} -> value
        5000 -> {:error, "Did not respond on time"}
      end
    end

    @doc  """
      Gets the keys using get_in
      """
    def get_nested(process, keys) do
      send(process, {:get_nested, keys, self()})
      receive do
        {:get_nested, value} -> value
        5000 -> {:error, "Did not respond on time"}
      end
    end

    @doc  """
      Returns the full user structure
    """
    def get_struct(process) do
      send(process, {:get_struct, self()})
      receive do
        {:data_structure, data_structure} -> data_structure
          5000 -> {:error, "Did not respond on time"}
      end
    end

    @doc  """
      Sets a key with value
    """
    def set(process,key,value) do
      send(process, {:set, key, value})
    end

    @doc  """
      Updates the structure with a map
      %{key1: "value1", key2: "value2"}
    """
    def set(process, map) do
      send(process, {:set, map})
    end

    @doc  """
      Sets the full structure in the selected process.
    """
    def set_struct(process, data_structure) do
      send(process, {:set_struct, data_structure})
    end

    @doc  """
      Increases a specific key
    """
    def incr(process, key,incr) do
      send(process, {:incr, key, incr})
    end

    @doc  """
      Gets the value of a key from our process.
    """
    def append(process, key,item) do
      send(process, {:append, key, item})
    end

    @doc  """
      Updates nested maps
    """
    def add(process, keys, item) do
      send(process, {:add, keys, item})
    end

    @doc  """
      Verify if key exists
    """
    def exists(process, key) do
      send(process, {:exists, key, self()})
      receive do
        {:exists, value} -> value
        5000 -> {:error, "Did not respond on time"}
      end
    end



end
