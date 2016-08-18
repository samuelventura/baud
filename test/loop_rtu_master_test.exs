defmodule Baud.LoopRtuMasterTest do
  use ExUnit.Case
  alias Baud.TestHelper

  test "modbus rtu master echo" do
    exec = :code.priv_dir(:baud) ++ '/native/baud'
    tty0 = TestHelper.tty0()
    args0 = ["o#{tty0},115200,8N1b32i0fde0lm", Atom.to_string(__MODULE__)]
    port0 = Port.open({:spawn_executable, exec}, [:binary, packet: 2, args: args0])
    tty1 = TestHelper.tty1()
    {:ok, pid1} = Baud.start_link([portname: tty1, name: Atom.to_string(__MODULE__)])
    assert_receive {^port0, {:data, "0"}}, 400
    :ok = Baud.discard(pid1)

    #read 1 from coil at 0
    true = Port.command(port0, <<01,01,00,00,00,01>>)
    {:ok, <<01,01,00,00,00,01,0xFD,0xCA>>} = Baud.read(pid1, 8, 400)
    :ok = Baud.write(pid1, <<01,01,01,01,0x90,0x48>>)
    assert_receive {^port0, {:data, <<01,01,01,01>>}}, 800
    #write 0 to coil at 3200
    true = Port.command(port0, <<01,05,0x0C,0x80,00,00>>)
    {:ok, <<01,05,0x0C,0x80,00,00,0xCF,0x72>>} = Baud.read(pid1, 8, 400)
    :ok = Baud.write(pid1, <<01,05,0x0C,0x80,00,00,0xCF,0x72>>)
    assert_receive {^port0, {:data, <<01,05,0x0C,0x80,00,00>>}}, 800
    #write 1 to coil at 3200
    true = Port.command(port0, <<01,05,0x0C,0x80,0xFF,00>>)
    {:ok, <<01,05,0x0C,0x80,0xFF,00,0x8E,0x82>>} = Baud.read(pid1, 8, 400)
    :ok = Baud.write(pid1, <<01,05,0x0C,0x80,0xFF,00,0x8E,0x82>>)
    assert_receive {^port0, {:data, <<01,05,0x0C,0x80,0xFF,00>>}}, 800

    true = Port.close(port0)
    :ok = Baud.close(pid1)
  end

end
