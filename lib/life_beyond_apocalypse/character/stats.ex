defmodule Stats do
  @moduledoc  """


  For all stats, minimal values are 4 and increasing values above 14
   will cost 2 points instead of 1! 14 is considered to be very high,
   the max human value. Players can go higher,
    but those values should be considered exceptionally high.

    http://cddawiki.chezzo.com/cdda_wiki/index.php?title=Stats
  """



@doc  """
base hp50 +4*5=70
Each point increases your HP by 3. +5
Each point increases your Carry Weight by 9lbs. (4kg)
Every 2 points increase your Melee Damage by 1.

Strength also makes you more resistant to many diseases and poisons,
and makes actions which require brute force
(pushing heavy stuff, bashing down furniture and walls) more effective.
http://dev.narc.ro/cataclysm/doxygen/Effects_Stat_Strength.html
"""
  def strength() do

  end

@doc  """
Every 2 points increase your Melee to-hit bonus by 1.
Every point above 9 (10, 11, etc.) increases your throwing bonus by 1.
Each point decreases your Ranged Penalty by 15. It cannot be brought above zero.

Dexterity also enhances many actions which require finesse,
such as dodging, martial arts special attacks and bonus attacks granted by mutations.

http://dev.narc.ro/cataclysm/doxygen/Effects_Stat_Dexterity.html
"""
  def dexterity() do

  end

@doc  """
Each point decreases your Read Times by 5%.
Each point decreases you Skill Rust by 3.5% (rounded up).

Intelligence is also used when crafting, installing bionics, and
interacting with NPCs. Advanced books also have intelligence requirement.
 Not meeting this requirement significantly increases reading time.

http://dev.narc.ro/cataclysm/doxygen/Effects_Stat_Intelligence.html
"""
  def intelligence() do

  end


@doc  """
Each point decreases your Ranged Penalty by 15. It cannot be brought above zero.

Perception is also used for detecting traps and other things of interest

Detailed Perception Effects
http://dev.narc.ro/cataclysm/doxygen/Effects_Stat_Perception.html
"""
  def perception() do

  end


  @doc  """
Hidden stats
  http://cddawiki.chezzo.com/cdda_wiki/index.php?title=Hidden_stats
  Every 5 minutes (50 turns) increase by 1 point
  Or every 1 Action. This means that with every action all hidden stats increase by 1.
  They are updated every 10 actions.

  Hunger < 0 Full
  Hunger > 40 Hungry
  Hunger > 80  Very Hungry
  Hunger > 300 Famished
  Hunger > 1400 Near starving
  Hunger > 2800  Starving!
  Hunger level 6000 -> You have starved to death
  Hunger levels above 100 impact speed
  Hunger levels above 2000 impact
  Eating food

  Thirst < 0 	Slaked
  Thirst > 40 	Thirsty
  Thirst > 80 	Very thirsty
  Thirst > 240 	Dehydrated
  Thirst > 520 	Parched

  Drinking liquids
  1200 -> you hvae died of dehydratation


  # Fatigue
  Default value: 0 | Min value: -- | Max value: 1000

Fatigue > 191 	Tired - Warned every 50 turns
Fatigue > 383 	Dead tired -> stat penalties "disease"
Fatigue > 575 	Exhausted -> Microsleep, no fatigue help, dangerous
Fatigue > 800   1 in 10 chance to fall in sleep instantly, fatigue reduced by 10.
Fatigue 1000 >  You fall asleep instantly and sleep for a while


# Energy (needs to be figured out)
Energy 1000 - 1500 => Extra Fresh
Energy 700 - 1000 => Good condition
Energy 500 - 700  - Tired - Warned every 50 turns/actions
Energy 350 - 500  Dead tired -> stat penalties
Energy 100 - 350 	Exhausted -> Microsleep, no fatigue/energy given,
  dangerous if you're doing various activities like fighting..
  Microsleep means you go out and for 1 minute you won't do anything
Energy 0 - 100   1 in 10 chance to fall in sleep instantly.
  => 5 minutes of waiting is necessary, fatigue is reduced and energy increased by 10
  => This means you can fall asleep
Energy 0 - You fall asleep instantly. 30 minutes you won't be able to do anything.


# Sleeping $
## High energy sleep
High energy sleep gives you energy at a rate of +50 energy per hour
You need to be in a safe environment for this to work.
You also need to feel warm and not be disturbed by anything.

## Low energy sleep
When you are offline you go into a low energy sleep.
Any sleep that is not safe, warm and that could "make you happy" is a low energy sleep.
Meaning you get 10 energy per hour. 240 energy per day
You will therefore need 4 days of offline gaming to be full again
So it's best to sleep while "in the game" while safe.


For the offline game..
Consuming stimulants increases energy


    # Moves / Actions / Speed / Energy
    Default value: 1000 | Min value: 0 | Max value: 1000
    Each action in the game requires a certain amount of energy and increases fatigue

    Energy is replenished whenever we consume certain items (food, water)
    and when we sleep.
    You may not be fatigued but have no energy if your hunger is great.

    A certain action may fatigue you by 3 points.
    But the same action may require 5 energy points.

    Certain actions add to your fatigue but do not use any energy.
    Examining items, people etc ads to fatigue but doesn't use any energy.
    Moving ads fatigue but doesn't use energy

    For each action we increase the actions and total_actions variables.
    When we get to 10 actions regardless of the type of action 1 energy is decreased.

    Energy is replenished for every 10 actions
    Food < 100  Water < 100   Fatigue < 100   Energy +

    ## Penalties

    Weight: when the weight carried is 25% higher than the weight capacity
    Pain: when pain is higher than the potency of the consumed painkillers. This penalty is more severe if the difference is higher than 60
    Painkillers: when the potency of the consumed painkillers is 10 or higher than the pain. More severe if it's higher than 30.
    Morale: when morale bonus (morale level / 25) is below -10
    Radiation: when radiation is 20 or higher. 40 or higher increases the penalty further
    Thirst: when thirst is above 40
    Hunger: when hunger is above 100
    Sunlight dependent mutation: penalties relative to the current light level when not under sunlight
    Cold blood mutation: when temperature is below 60F
    Speed down artifact: 20 penalty points


  ##  Bonus

    Morale: when morale is higher than 100 there will be a bonus that can't be higher than 10.
    Stimulants: Based on the potency of all stimulants taken. It can't be higher than 40.
    Quick trait: gives a 10% bonus

  #  Pain
  when your health is under a certain treshhold you feel pain
    """
end
