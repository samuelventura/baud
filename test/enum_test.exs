defmodule Baud.EnumTest do
  use ExUnit.Case
  alias Baud.TTY

  @doc """
  Check hard coded ports are enumerated.
  """
  test "enum test" do
    tty0 = TTY.tty0
    tty1 = TTY.tty1
    assert Enum.member?(Baud.Enum.list, tty0)
    assert Enum.member?(Baud.Enum.list, tty1)
  end

end
