defmodule Baud.KillTest do
  use ExUnit.Case
  alias Baud.TTY

  test "kill test" do
    Process.flag(:trap_exit, true)
    tty0 = TTY.name 0
    {:ok, pid0} = Baud.start_link [device: tty0]
    Baud.write pid0, "hello"
    Process.exit(pid0, :kill)
    :timer.sleep 100
    {:ok, pid0} = Baud.start_link [device: tty0]
    :ok = Baud.stop(pid0)
  end

end
