defmodule Baud.ConfigTest do
  use ExUnit.Case
  alias Baud.TestHelper

  test "setup test" do
    test_setup("115200", "7E1")
    test_setup("115200", "7O1")
    test_setup("57600", "8N1")
    test_setup("38400", "8N1")
    test_setup("19200", "8N1")
    test_setup("9600", "8N1")
    test_setup("4800", "8N1")
    test_setup("2400", "8N1")
    test_setup("1200", "8N1")
    test_setup("115200", "8N1")
  end

  @doc """
  Make sure this does a proper closing or delays may be needed to wait
  previous iteration serial port to close and random failures will appear.

  Things like:
  ```elixie
     Assertion with == failed
     code: {port0, "echo1"} == {p0, echo1}
     lhs:  {#Port<0.5225>, "echo1"}
     rhs:  {#Port<0.5225>, "ecoo1"}
  ```
  """
  def test_setup(baudrate, bitconfig) do
    exec = :code.priv_dir(:baud) ++ '/native/baud'
    tty0 = TestHelper.tty0()
    #the writing process requires no packto
    args0 = ["o#{tty0},#{baudrate},#{bitconfig}b32e0"]
    port0 = Port.open({:spawn_executable, exec}, [:binary, packet: 2, args: args0])
    tty1 = TestHelper.tty1()
    #the reading process requires a packto=100*n to be portable
    args1 = ["o#{tty1},#{baudrate},#{bitconfig}b32i100e1"]
    port1 = Port.open({:spawn_executable, exec}, [:binary, packet: 2, args: args1])
    #wait echos to ensure ports are ready
    assert_receive {_, {:data, "0"}}, 400
    assert_receive {_, {:data, "1"}}, 400
    #write to one read from the other
    true = Port.command(port0, "w")
    true = Port.command(port0, "echo0\n")
    true = Port.command(port1, "r")
    assert_receive {p1, {:data, echo0}}, 400
    assert {port1, "echo0\n"} == {p1, echo0}
    #close and wait for echos
    true = Port.command(port0, "ce0")
    true = Port.command(port1, "ce1")
    assert_receive {_, {:data, "0"}}, 400
    assert_receive {_, {:data, "1"}}, 400
    #kill the native port
    true = Port.close(port0)
    true = Port.close(port1)
  end
end
