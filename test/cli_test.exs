defmodule LifeBeyondApocalypseCliTest do
  use ExUnit.Case
  doctest LifeBeyondApocalypse.CLI

  import ExUnit.CaptureIO

  test "Starting the game expecting input name" do
    assert(
    String.match?(capture_io("Andrei\nquit\n",
    fn ->
      LifeBeyondApocalypse.CLI.main("")
    end
    ),
    ~r/What is your name dear adventurer\?/iu)
    )
  end

  test "Asking for name, expecting name welcome" do
    name = "Andrei"
    assert(
    String.match?(capture_io("#{name}\nquit\n",
    fn ->
      LifeBeyondApocalypse.CLI.main("")
    end
    ),
    ~r/name/iu)
    )
  end

  test "Help menu" do
    name = "Andrei"
    assert(
    String.match?(capture_io("#{name}\nhelp\nquit\n",
    fn ->
      LifeBeyondApocalypse.CLI.main("")
    end
    ),
    ~r/to find out more about a specific command/iu)
    )
  end

  test "Unknown command" do
    name = "Andrei"
    assert(
    String.match?(capture_io("#{name}\n unknown stuff  \nquit\n",
    fn ->
      LifeBeyondApocalypse.CLI.main("")
    end
    ),
    ~r/Unknown command. Try help/iu)
    )
  end


  test "Search for items" do
    name = "Andrei"
    assert(
    String.match?(capture_io("#{name}\n search \n search  \n search \nquit\n",
    fn ->
      LifeBeyondApocalypse.CLI.main("")
    end
    ),
    ~r/You've failed to find a usefull item.|You've found a/iu)
    )
  end

  test "inventory with items" do
    name = "Andrei"
    commands = "#{name}\n
     search \n search  \n search \n
     inventory
     quit\n"
    assert(
    String.match?(capture_io(commands,
    fn ->
      LifeBeyondApocalypse.CLI.main("")
    end
    ),
    ~r/Inventory consists of ([0-9]+) items:/iu)
    )
  end


  test "Drop an item, by mistake, refuse" do
    name = "Andrei"
    commands = "#{name}\n
     search \n search  \n search \n      search \n      search \n

     drop a\n
     no\n
     quit\n"
    assert(
    String.match?(capture_io(commands,
    fn ->
      LifeBeyondApocalypse.CLI.main("")
    end
    ),
    ~r/You have decided NOT to drop the item./iu)
    )
  end


#|You don't seem to have a\(n\) "\w{1,}" in your inventory

test "Drop an item, accept it being dropped" do
  name = "Andrei"
  commands = "#{name}\n
   search \n search  \n search \n  search \n      search \n
    search \n      search \n   search \n search \n
   drop a\n
   yes\n
   true\n
   quit\n"
   output =capture_io(commands,
   fn ->
     LifeBeyondApocalypse.CLI.main("")
   end
   )
  assert(
  String.match?(output,
  ~r/You have dropped|You have decided NOT/iu)
  )
end

end
