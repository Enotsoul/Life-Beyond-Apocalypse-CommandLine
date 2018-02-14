defmodule GameState do
  @moduledoc  """
  Functions to handle the game state.
  Creating new random maps for the user.
  Saving and loading the game state.
  """

  @save_location "data/save/"
  @doc  """
  Creating a new map
  """
  def create() do

  end

  def get_all_saves() do
    File.ls!(@save_location)
  end

  def save_game(file_name  \\ nil) do
    game_map = DataStorage.get_struct(:game_map)
    user = User.get_struct()
    if file_name == nil do
      file_name = user.name <> "_" <> game_map.name <> "_" <> DateTime.to_string(DateTime.utc_now()) <> ".sav"
    else
      file_name =file_name  <> ".sav"
    end

    File.write!(@save_location <> file_name  , :erlang.term_to_binary(%{game_map: game_map  ,
    user: user ,
    zombies: "",
    npc: ""}))
    full_path = @save_location  <> file_name
    {:ok, "Game has been saved under #{full_path}"}
  end

  def load_game(filename) do
    if !File.exists?(filename) do
      selected_file = get_all_saves()
      |> Enum.find(fn (file) ->
        String.downcase(file) =~ filename
      end)
      if !is_nil(selected_file) do
        load_existing_game(selected_file)
      else
        {:error, "I couldn't find any load game with this name"}
      end
    else
      load_existing_game(filename)
    end
  end

  def load_existing_game(filename) do
    data = :erlang.binary_to_term(File.read!(@save_location <> filename))
    GameMap.load_map(data.game_map)
    user = Map.get(data,:user)
    User.start(user.name)
    User.set_struct(data.user)
    {:ok, "Loaded game from #{filename} - Happy Surviving!"}
  end

end
