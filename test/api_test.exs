defmodule Baud.ApiTest do
  use ExUnit.Case
  alias Baud.TTY

  test "baud api test" do
    tty0 = TTY.tty0()
    tty1 = TTY.tty1()
    {:ok, pid0} = Baud.start_link(device: tty0)
    {:ok, pid1} = Baud.start_link(device: tty1)

    Baud.write(pid0, "01234\n56789\n98765\n43210")
    assert {:ok, "01234\n"} == Baud.readln(pid1)
    assert {:ok, "56789\n"} == Baud.readln(pid1)
    assert {:ok, "98765\n"} == Baud.readln(pid1)
    assert {:to, "43210"} == Baud.readln(pid1)

    Baud.write(pid0, "01234\r56789\r98765\r43210")
    assert {:ok, "01234\r"} == Baud.readcr(pid1)
    assert {:ok, "56789\r"} == Baud.readcr(pid1)
    assert {:ok, "98765\r"} == Baud.readcr(pid1)
    assert {:to, "43210"} == Baud.readcr(pid1)

    Baud.write(pid0, "01234\n56789\n98765\n43210")
    assert {:ok, "01234\n"} == Baud.readn(pid1, 6)
    assert {:ok, "56789\n"} == Baud.readn(pid1, 6)
    assert {:ok, "98765\n"} == Baud.readn(pid1, 6)
    assert {:to, "43210"} == Baud.readn(pid1, 6)
    assert {:ok, ""} == Baud.readn(pid1, 0)

    Baud.write(pid0, "01234\n")
    Baud.write(pid0, "56789\n")
    Baud.write(pid0, "98765\n")
    Baud.write(pid0, "43210")
    :timer.sleep(100)
    assert {:ok, "01234\n56789\n98765\n43210"} == Baud.readall(pid1)
    :ok = Baud.stop(pid0)
    :ok = Baud.stop(pid1)
  end
end
