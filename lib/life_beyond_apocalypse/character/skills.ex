defmodule Skills do
  @moduledoc  """

  http://cddawiki.chezzo.com/cdda_wiki/index.php?title=Skills
  You start with level 0 for all skills.
  You increase your skills by practicing them with the basics.

  You can  increase skills by reading books which requires focus.
  You can also be thaught by NPC's
  Or by experienced players (online version)

As level 0 you can do level 0 things.
You can attempt to train your skill based on items of a higher level
however failure chance is greater.

  Practicing a skill with successs ads 1 point towards your experience in that skill
  Level Exp
  1     32
  2     64
  3     128
  4     256
  5     512
  6     1024
  7     2048
   32*:math.pow(2,level-1)
  For each additional level after level 7 you will need
  double the experience of the previous ..
  The biggest usefull skill is at 7, and can increase untill 10.
  Then it's capped as the maximum Master level

  #  Overall level
  With each new level gained you get 2 pickpoints
  which can be used to increase your stats and traits.
  No points for skill incresing since these should be increased
  by experimenting, reading or learning next to a NPC/human.
  Overall level can go unlimited.
  1   48
  2   72
  3   108
  4   162
  5   243
  6   365
  7   545
  8   820
  ...
  Calculation:
# 32*level*(level-1)



  """
  #   Enum.each(1..50, fn (x) -> IO.puts "Level #{x}  #{32*x*(x-1)}" end)
end
