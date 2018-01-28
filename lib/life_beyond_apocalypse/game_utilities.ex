defmodule GameUtilities do

        def get(arr, x, y) do
          arr |> Enum.at(x) |> Enum.at(y)
        end

        def set(arr, x, y, value) do
          List.replace_at(arr, x,
          List.replace_at(Enum.at(arr, x), y, value)
          )
        end
end
