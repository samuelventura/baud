defmodule Baud.TransTest do
  use ExUnit.Case
  alias Baud.TTY
  alias Baud.Transport

  test "serial transport close readn test" do
    tty0 = TTY.tty0()
    tty1 = TTY.tty1()
    {:ok, trans} = Transport.open(device: tty0)
    {:ok, baud} = Baud.start_link(device: tty1)

    {:error, {:timeout, ""}} = Transport.readn(trans, 1, 20)
    :ok = Baud.write(baud, "0")
    {:error, {:timeout, "0"}} = Transport.readn(trans, 2, 20)
    :ok = Transport.close(trans)
    {:error, {_, _}} = Transport.readn(trans, 1, 10)
  end

  test "serial transport close readp test" do
    tty0 = TTY.tty0()
    tty1 = TTY.tty1()
    {:ok, trans} = Transport.open(device: tty0)
    {:ok, baud} = Baud.start_link(device: tty1)

    :ok = Baud.write(baud, "0")
    {:ok, "0"} = Transport.readp(trans)
    :ok = Transport.close(trans)
    {:error, {_, _}} = Transport.readp(trans)
  end
end
