defmodule Baud.EnumTest do
  use ExUnit.Case
  alias Baud.TestHelper

  setup_all do TestHelper.setup_all end
  setup do TestHelper.setup end

  @doc """
  Check hard coded ports are enumerated.
  """
  test "enum test" do
    tty0 = TestHelper.tty0()
    tty1 = TestHelper.tty1()
    assert Enum.member?(Baud.Enum.list, tty0)
    assert Enum.member?(Baud.Enum.list, tty1)
  end

end
