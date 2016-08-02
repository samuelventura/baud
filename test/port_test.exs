defmodule Baud.PortTest do
  use ExUnit.Case
  alias Baud.TestHelper

  @doc """
  Check native port command interface.
  """
  test "port test" do
    exec = :code.priv_dir(:baud) ++ '/native/baud'
    tty0 = TestHelper.tty0()
    #the writing process requires no packto
    args0 = ["o#{tty0},115200,8N1b32e0"]
    port0 = Port.open({:spawn_executable, exec}, [:binary, packet: 2, args: args0])
    tty1 = TestHelper.tty1()
    #the reading process requires a packto=100*n to be portable
    args1 = ["o#{tty1},115200,8N1b32i100e1"]
    port1 = Port.open({:spawn_executable, exec}, [:binary, packet: 2, args: args1])
    #wait echos to ensure ports are ready
    assert_receive {^port0, {:data, "0"}}, 400
    assert_receive {^port1, {:data, "1"}}, 400
    #write to one read from the other
    true = Port.command(port0, "w")
    true = Port.command(port0, "echo0\n")
    true = Port.command(port1, "r")
    assert_receive {^port1, {:data, "echo0\n"}}, 400
    #write to one, wait data on the other, discard data,
    #send againt, receive only the second one
    #FIXME may require delay
    true = Port.command(port0, "w")
    true = Port.command(port0, "echo0\n")
    true = Port.command(port1, "s400")
    assert_receive {^port1, {:data, "so"}}, 400
    true = Port.command(port1, "afd")
    assert_receive {^port1, {:data, "a6"}}, 400
    true = Port.command(port0, "w")
    true = Port.command(port0, "echo1\n")
    true = Port.command(port1, "r")
    assert_receive {^port1, {:data, "echo1\n"}}, 400
    #send several chunks of data and wait for it as a line
    #receive them on the i0 port or 100msec may add up on each received byte
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
