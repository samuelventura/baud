defmodule Baud.TextTest do
  use ExUnit.Case
  alias Baud.TestHelper
  @reps 3

  @doc """
  Check baud works against itself in text mode.
  """
  test "text echo" do
    exec = :code.priv_dir(:baud) ++ '/native/baud'
    tty0 = TestHelper.tty0()
    args0 = ["o#{tty0},115200,8N1b8i0e0lt"]
    port0 = Port.open({:spawn_executable, exec}, [:binary, packet: 2, args: args0])
    tty1 = TestHelper.tty1()
    args1 = ["o#{tty1},115200,8N1b8i0e1lt"]
    port1 = Port.open({:spawn_executable, exec}, [:binary, packet: 2, args: args1])
    assert_receive {^port0, {:data, "0"}}, 400
    assert_receive {^port1, {:data, "1"}}, 400

    Enum.each 1..@reps, fn _x ->
      true = Port.command(port0, "echo0\n")
      assert_receive {^port1, {:data, "echo0\n"}}, 400
      true = Port.command(port1, "echo1\n")
      assert_receive {^port0, {:data, "echo1\n"}}, 400
    end

    true = Port.close(port0)
    true = Port.close(port1)
    :timer.sleep(200)
  end

end
