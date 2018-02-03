defmodule NPC do
  @moduledoc  """
    NPC
      Alignment (friendly | neutral | hostile)
      Status (:alive | :dead | :zombie )
  """
  import GameUtilities
  defstruct name: "", health: 50, max_health: 50, energy: 100, max_energy: 100,
      x: 5, y: 5, items: [], coins: 0, map_id: 1, experience: 0, gender: nil,
      alignment: nil, options: [], status: :alive, attack: nil, defense: nil



      def generate_npcs(number) do
        %{map: _map, x: x_max, y: y_max} = GameMap.generate_map()

        items = GameItems.items()
        multiplied_items = items ++ items ++ items ++ items ++ items |> Enum.shuffle()
        npc_list =  Enum.map(1..number, fn (number) ->
          npc_items = multiplied_items |> Enum.take_random(rand(1,10))
          %NPC{
            health:  rand(25,100), coins: rand(0,100),
            name: "Survivor #{number}", x: rand(1,x_max), y: rand(1,y_max),
            attack: rand(3,7), defense: rand(3,7),
            items: npc_items,
            alignment: generate_alignment(),
            gender: if(rand(1,2) == 1, do: :male, else: :female )
          }
        end)
        Enum.map(npc_list, fn npc -> IO.inspect npc end)

      end

      def generate_alignment() do
         rand = rand(1, 100)
         cond do
            rand < 30 -> :hostile
            rand  >= 30 and rand < 70 -> :neutral
            rand >= 70 -> :friendly
         end
      end
end
