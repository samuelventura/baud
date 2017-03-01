defmodule Baud.NifCrudTest do
  use ExUnit.Case
  alias Baud.TestHelper

  test "api test" do
    tty0 = TestHelper.tty0
    tty1 = TestHelper.tty1
    {:ok, nid0} = Baud.Nif.open tty0, 115200, "8N1"
    {:ok, nid1} = Baud.Nif.open tty1, 115200, "8N1"
    :ok = Baud.Nif.write nid0, "echo"
    :timer.sleep 100
    {:ok, "echo"} = Baud.Nif.read nid1
    :ok = Baud.Nif.close nid0
    :ok = Baud.Nif.close nid1
  end

end
