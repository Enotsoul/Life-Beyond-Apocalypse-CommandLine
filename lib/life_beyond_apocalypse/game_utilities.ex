defmodule GameUtilities do

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

  def random_tests() do
    randomized = Enum.map(1..100000,  fn (_x) -> rand(1,10) end)
    Enum.each(1..10, fn (nr) ->
      count = randomized |> Enum.count(fn (x) -> x == nr end)
      IO.puts "#{nr}. - count #{count}"
    end)

  end

end
