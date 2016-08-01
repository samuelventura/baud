defmodule Baud.Enum.Test do
  use ExUnit.Case
  alias Baud.TestHelper
  @reps 3

  test "enum test" do
    tty0 = TestHelper.tty0()
    tty1 = TestHelper.tty1()
    assert Enum.member?(Baud.Enum.list, tty0)
    assert Enum.member?(Baud.Enum.list, tty1)
  end

end
