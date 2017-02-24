defmodule Baud.LoopTextTest do
  use ExUnit.Case
  alias Baud.TestHelper

  setup_all do TestHelper.setup_all end
  setup do TestHelper.setup end

  @doc """
  Check baud native port works against itself in text mode.
  """
  test "text echo" do
    exec = :code.priv_dir(:baud) ++ '/native/baud'
    tty0 = TestHelper.tty0()
    args0 = ["o#{tty0},115200,8N1b12i0fde0lt", Atom.to_string(__MODULE__)]
    port0 = Port.open({:spawn_executable, exec}, [:binary, packet: 2, args: args0])
    tty1 = TestHelper.tty1()
    {:ok, pid1} = Baud.start_link([portname: tty1, name: Atom.to_string(__MODULE__)])
    assert_receive {^port0, {:data, "0"}}, 400
    :ok = Baud.discard(pid1)

    true = Port.command(port0, "echo0")
    true = Port.command(port0, "echo0\n")
    {:ok, "echo0echo0\n"} = Baud.read(pid1, 11, 400)
    :ok = Baud.write(pid1, "echo1")
    :ok = Baud.write(pid1, "echo1\n")
    assert_receive {^port0, {:data, "echo1echo1\n"}}, 400

    true = Port.close(port0)
    :ok = Baud.close(pid1)
  end

end
