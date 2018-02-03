defmodule MapGeneratorTest do
  use ExUnit.Case
  doctest MapGenerator


  test "Testing Rotation of tinymap" do
    #Rotation 1 90
   tinymap = ~w/  ABCDE    FGHIJ    KLMNO    PQRTS    UVWXY    /
  assert( MapGenerator.rotate_tinymap(tinymap,1,true) ==    [["U", "P", "K", "F", "A"], ["V", "Q", "L", "G", "B"],
    ["W", "R", "M", "H", "C"], ["X", "T", "N", "I", "D"],
    ["Y", "S", "O", "J", "E"]])

    #Rotation 2 180
  assert( MapGenerator.rotate_tinymap(tinymap,2,true) ==
    [["Y", "X", "W", "V", "U"], ["S", "T", "R", "Q", "P"],
    ["O", "N", "M", "L", "K"], ["J", "I", "H", "G", "F"],
    ["E", "D", "C", "B", "A"]])

    #Rotation 3 270
      assert(  MapGenerator.rotate_tinymap(tinymap,3,true) ==
    [["E", "J", "O", "S", "Y"], ["D", "I", "N", "T", "X"],
    ["C", "H", "M", "R", "W"], ["B", "G", "L", "Q", "V"],
    ["A", "F", "K", "P", "U"]])

    #Rotation 4 is 360 thus we should get the same map!
      assert( MapGenerator.rotate_tinymap(tinymap,4,true) ==
    [["A", "B", "C", "D", "E"], ["F", "G", "H", "I", "J"],
    ["K", "L", "M", "N", "O"], ["P", "Q", "R", "T", "S"],
    ["U", "V", "W", "X", "Y"]])

  end
end
