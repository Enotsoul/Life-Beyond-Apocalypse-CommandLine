defmodule GameHelp do
  @location "data/help/"
  @database :game_help

  @doc """
  Loads help file for topic by loading an Elixir Template file (.eex)
    IDEA verify if things changed.. timestamp+sha1
  """
  def get_help_for_topic(topic) do
    full_path = @location <> topic <> ".eex"
    if File.exists?(full_path) do
      data =  EEx.eval_file(full_path)
      dup =  String.duplicate("=",13)
      separator = "#{dup} #{topic} #{dup}\n"
      data =   separator <> data <> separator
      DataStorage.set(@database, String.to_atom(topic), data)
      {:ok, data}
    else
      {:error, "No help available for the topic #{topic}"}
    end
  end



  def start() do
    DataStorage.start(@database, DataStorage, :new, %{})
  end

  def get_commands() do
      DataStorage.get_nested(@database,[:help,:commands])
  end
  def get_command_list() do
      DataStorage.get_nested(@database,[:help,:command_list])
  end
end
