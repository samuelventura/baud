defmodule Baud.KillTest do
  use ExUnit.Case
  alias Baud.TestHelper

  test "kil test" do
    Process.flag(:trap_exit, true)
    tty0 = TestHelper.tty0
    {:ok, pid0} = Baud.start_link [device: tty0]
    Baud.write pid0, "hello"
    Process.exit(pid0, :kill)
    :timer.sleep 100
    {:ok, _} = Baud.start_link [device: tty0]
  end

end
