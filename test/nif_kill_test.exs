defmodule Baud.NifKillTest do
  use ExUnit.Case
  alias Baud.TestHelper

  #Ensure resource is auto closed on process normal exit
  test "kill test" do
    tty0 = TestHelper.tty0
    pid = spawn(fn ->
      {:ok, _} = Baud.Nif.open tty0, 115200, "8N1"
      receive do
        pid -> send pid, :ok
      end
    end)
    send pid, self()
    assert_receive :ok
    :timer.sleep 200
    {:ok, _nid0} = Baud.Nif.open tty0, 115200, "8N1"
  end

end
