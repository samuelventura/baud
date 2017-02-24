defmodule Baud.KillTest do
  use ExUnit.Case
  alias Baud.TestHelper

  setup_all do TestHelper.setup_all end
  setup do TestHelper.setup end

  @doc """
  Check the baud genserver API.
  """
  test "baud kill test" do
    Process.flag(:trap_exit, true)
    tty0 = TestHelper.tty0()
    tty1 = TestHelper.tty1()
    {:ok, pid0} = Baud.start_link([portname: tty0, name: Atom.to_string(__MODULE__)])
    {:ok, pid1} = Baud.start_link([portname: tty1, name: Atom.to_string(__MODULE__)])
    #:ok = Baud.debug(pid0, 1)
    #:ok = Baud.debug(pid1, 1)

    loop(pid0, pid1)
    TestHelper.kill_baud
    :timer.sleep(200)
    assert false == Process.alive?(pid0)
    assert false == Process.alive?(pid1)

  end

  defp loop(pid0, pid1) do
    for _ <- 0..10 do
      :ok = Baud.write(pid0, "echo\n")
      {:ok, "echo\n"} = Baud.readln(pid1, 400)
    end
  end

end
