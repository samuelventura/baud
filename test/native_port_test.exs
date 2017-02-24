defmodule Baud.NativePortTest do
  use ExUnit.Case
  alias Baud.TestHelper

  setup_all do TestHelper.setup_all end
  setup do TestHelper.setup end

  @doc """
  Check native port command interface.
  """
  test "port test" do
    exec = :code.priv_dir(:baud) ++ '/native/baud'
    tty0 = TestHelper.tty0()
    args0 = ["o#{tty0},115200,8N1b32e0", Atom.to_string(__MODULE__)]
    port0 = Port.open({:spawn_executable, exec}, [:binary, packet: 2, args: args0])
    tty1 = TestHelper.tty1()
    args1 = ["o#{tty1},115200,8N1b32e1", Atom.to_string(__MODULE__)]
    port1 = Port.open({:spawn_executable, exec}, [:binary, packet: 2, args: args1])
    #wait echos to ensure ports are ready
    assert_receive {^port0, {:data, "0"}}, 400
    assert_receive {^port1, {:data, "1"}}, 400
    #write to one, read from the other
    true = Port.command(port0, "w")
    true = Port.command(port0, "echo0\n")
    true = Port.command(port1, "r6+400")
    assert_receive {^port1, {:data, "echo0\n"}}, 400
    #write to one, wait data on the other, discard data,
    #send againt, receive only the second one
    true = Port.command(port0, "w")
    true = Port.command(port0, "echo0\n")
    true = Port.command(port1, "s6+400e+")
    assert_receive {^port1, {:data, "+"}}, 400
    true = Port.command(port1, "afd")
    assert_receive {^port1, {:data, "a6"}}, 400
    true = Port.command(port0, "w")
    true = Port.command(port0, "echo1\n")
    true = Port.command(port1, "r6+400")
    assert_receive {^port1, {:data, "echo1\n"}}, 400
    #send several chunks of data and wait for it as a line
    true = Port.command(port1, "wp100wft")
    true = Port.command(port1, "echo0")
    true = Port.command(port1, "echo1\n")
    true = Port.command(port0, "n200")
    assert_receive {^port0, {:data, "echo0echo1\n"}}, 400
    #close and then wait for echos
    true = Port.command(port0, "ce0")
    true = Port.command(port1, "ce1")
    assert_receive {^port0, {:data, "0"}}, 400
    assert_receive {^port1, {:data, "1"}}, 400
    #kill the native port
    true = Port.close(port0)
    true = Port.close(port1)
  end

end
