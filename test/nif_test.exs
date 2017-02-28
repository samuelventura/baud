defmodule Baud.ApiTest do
  use ExUnit.Case
  alias Baud.TestHelper

  test "baud test" do
    tty0 = TestHelper.tty0
    tty1 = TestHelper.tty1
    {:ok, fd0} = Baud.Nif.open tty0, 115200, "8N1"
    {:ok, fd1} = Baud.Nif.open tty1, 115200, "8N1"
    :ok = Baud.Nif.write fd0, "echo"
    :timer.sleep 100
    {:ok, "echo"} = Baud.Nif.read fd1
    :ok = Baud.Nif.close fd0
    :ok = Baud.Nif.close fd1
  end

end
