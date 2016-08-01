defmodule Baud.ModbusTest do
  use ExUnit.Case
  alias Baud.TestHelper
  @reps 3

  @doc """
  Check baud works against itself in modbus+raw mode.

  #Using Modbus Master
  #COM8 USB-RS485 Adapter
  #10.77.0.107:8899 USR-WIFI232-630
  #TCP Read 1 from coil at 0
  00,05,00,00,00,06,01,01,00,00,00,01
  00,05,00,00,00,04,01,01,01,01
  #RTU Read 1 from coil at 0
  01,01,00,00,00,01,FD,CA
  01,01,01,01,90,48
  #RTU Write 0 to coil at 3200
  01,01,0C,80,00,01,FF,72
  01,01,01,00,51,88
  #TCP Write 0 to coil at 3200
  00,04,00,00,00,06,01,05,0C,80,00,00
  00,04,00,00,00,06,01,05,0C,80,00,00
  """
  test "modbus echo" do
    exec = :code.priv_dir(:baud) ++ '/native/baud'
    tty0 = TestHelper.tty0()
    args0 = ["o#{tty0},115200,8N1b32i0e0lm"]
    port0 = Port.open({:spawn_executable, exec}, [:binary, packet: 2, args: args0])
    tty1 = TestHelper.tty1()
    args1 = ["o#{tty1},115200,8N1b32i100e1lr"]
    port1 = Port.open({:spawn_executable, exec}, [:binary, packet: 2, args: args1])
    assert_receive {_, {:data, "0"}}, 400
    assert_receive {_, {:data, "1"}}, 400

    Enum.each 1..@reps, fn _x ->
      true = Port.command(port0, <<00,05,00,00,00,06,01,01,00,00,00,01>>)
      assert_receive {p1, {:data, echo0}}, 400
      assert {port1, <<01,01,00,00,00,01,0xFD,0xCA>>} == {p1, echo0}
      true = Port.command(port1, <<01,01,01,01,0x90,0x48>>)
      assert_receive {p0, {:data, echo1}}, 800
      assert {port0, <<00,05,00,00,00,04,01,01,01,01>>} == {p0, echo1}
    end

    Enum.each 1..@reps, fn _x ->
      true = Port.command(port0, <<00,04,00,00,00,06,01,05,0x0C,0x80,00,00>>)
      assert_receive {p1, {:data, echo0}}, 400
      assert {port1, <<01,05,0x0C,0x80,00,00,0xCF,0x72>>} == {p1, echo0}
      true = Port.command(port1, <<01,05,0x0C,0x80,00,00,0xCF,0x72>>)
      assert_receive {p0, {:data, echo1}}, 800
      assert {port0, <<00,04,00,00,00,06,01,05,0x0C,0x80,00,00>>} == {p0, echo1}
    end

    true = Port.close(port0)
    true = Port.close(port1)
    :timer.sleep(200)
  end

end
