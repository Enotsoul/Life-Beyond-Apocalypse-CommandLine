defmodule GameUtilities do
  require Logger
  def get(arr, x, y) do
    arr |> Enum.at(x) |> Enum.at(y)
  end

  def set(arr, x, y, value) do
    List.replace_at(arr, x,
    List.replace_at(Enum.at(arr, x), y, value)
    )
  end

  @doc  """
  Generates a random  integer between `min` and `max` both included.

  ## Examples
  iex> GameUtilities.rand(1,100) in  1..100
  true
  """
  def rand(min,max) do
    :rand.uniform() * (max + 1 - min) + min
    |> :math.floor()
    |> round()
  end

  def one_in(chance) do
    if(rand(1,chance) == chance, do: true, else: false)
  end

  def random_tests() do
    randomized = Enum.map(1..100000,  fn (_x) -> rand(1,10) end)
    Enum.each(1..10, fn (nr) ->
      count = randomized |> Enum.count(fn (x) -> x == nr end)
      IO.puts "#{nr}. - count #{count}"
    end)

  end


    @doc  """
    Generates a command line progressbar.

    ## Examples
    iex> GameUtilities.progressbar(1,100) in  1..100
    true
    """

    def progress_bar(current, maximum, char \\ "#", level \\ 25) do
  	current_nr = round((current/maximum)*level)
  	max_nr = round(maximum/maximum*level) - current_nr
  	full_bar = String.duplicate(char, current_nr)
  	empty_bar = String.duplicate("-", max_nr)
  	"[#{full_bar}#{empty_bar}]"
    end


    def report() do
  	"""
  	proc report {type text} {
  	  set data ""
  	  switch -- $type {
  		success {  append data [color green bold]SUCCESS:[color reset] }
  		info {  append data [color blue bold]INFO:[color reset] }
  		notice {  append data [color yellow bold]NOTICE:[color reset] }
  		warning {  append data [color magenta bold]WARNING:[color reset] }
  		danger	{  append data [color red bold]/!\\DANGER/!\\:[color reset] }
  	  }
  	  append data " " $text [color reset]
  	  return $data
  	}
  	"""
    end


    def  colored_progress(min, max, length \\ 25) do
      relative = (min/max)
      color = cond do
        relative > 0.75 ->  [:green]
        relative > 0.50 ->  [:blue]
        relative > 0.25 ->  [:light_yellow]
        true -> [:bright, :red]
      end
      IO.ANSI.format([color, progress_bar(min, max, "#", length)])
    end


######################################################
# Generate coloring to Elixir ansi coloring names..
######################################################
    @doc  """
    Color replacement
    c = custom color
    i = inverse / reverse
    h = highlight (underline)
    freaky stuff happening
    brown -> yellow
    yellow -> light_yellow
  """
    def return_color(color) when color != nil do
     toreturn =   case String.split(color,"_") do
         [what | the_rest] when what in ~w/i h c/ ->
           [custom_color_data(what)] ++ return_color(Enum.join(the_rest,"_"))
         [foreground] ->
           [pick_color_to_atom(foreground)]

         [intensity, "gray"] when intensity in ~w/light dark/  ->
           [pick_color_to_atom("#{intensity} gray" )]
         [intensity, foreground] when intensity in ~w/light/ ->
           Logger.debug "what's happening here with #{intensity} and #{foreground}"
              [pick_color_to_atom(intensity <> "_" <> foreground)]
         [foreground, background] ->
            [pick_color_to_atom(foreground),
              get_background_color(background)]
         [intensity, foreground, background] ->
            [pick_color_to_atom(intensity <> "_" <> foreground),
              get_background_color(background)]
        _ -> :white
       end
       Logger.debug "Incoming color #{color} outgoing #{inspect toreturn}"
       toreturn
    end
    def return_color(_color) do
      :font_2
    end

    def custom_color_data(what) do
      case what do
        "i" -> :inverse
        "h" -> :underline
        _ -> :font_1
      end
    end

    def get_background_color(color) do
        pick_color(color) <> "_background"   |>  String.to_atom
    end

    def pick_color( color) do
      case color do
        "brown" -> "yellow"
        "yellow" -> "light_yellow"
        "light gray" -> "white"
        "dark gray" -> "light_black"
        "pink" -> "magenta"
        _ -> color
      end
    end
    def pick_color_to_atom(color) do
      pick_color(color) |> String.to_atom
    end



end

defmodule FileExt do
  @doc  """
  Get all files recursively

  Thanks to http://www.ryandaigle.com/a/recursively-list-files-in-elixir/
  """
  def ls_r(path \\ ".") do
    cond do
      File.regular?(path) -> [path]
      File.dir?(path) ->
        File.ls!(path)
        |> Enum.map(&Path.join(path, &1))
        |> Enum.map(&ls_r/1)
        |> Enum.concat
      true -> []
    end
  end
end
