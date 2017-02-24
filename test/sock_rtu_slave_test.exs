defmodule Baud.SockRtuSlaveTest do
  use ExUnit.Case
  alias Baud.TestHelper
  alias Baud.Sock

  setup_all do TestHelper.setup_all end
  setup do TestHelper.setup end

  test "rtu slave mode test" do
    tty0 = TestHelper.tty0()
    tty1 = TestHelper.tty1()
    {:ok, pid0} = Sock.start_link([portname: tty0, mode: :rtu_slave, name: Atom.to_string(__MODULE__)])
    {:ok, pid1} = Sock.start_link([portname: tty1, mode: :raw, name: Atom.to_string(__MODULE__)])
    {:ok, %{port: port0}} = Sock.id(pid0)
    {:ok, %{port: port1}} = Sock.id(pid1)

    {:ok, sock0} = :gen_tcp.connect({127,0,0,1}, port0, [:binary, packet: :raw, active: :false], 400)
    {:ok, sock1} = :gen_tcp.connect({127,0,0,1}, port1, [:binary, packet: :raw, active: :false], 400)

    #read 1 from coil at 0
    :ok = :gen_tcp.send(sock1, <<01,01,01,01,0x90,0x48>>);
    {:ok, <<01,01,01,01>>} = :gen_tcp.recv(sock0, 4, 400)
    :ok = :gen_tcp.send(sock0, <<01,01,00,00,00,01>>);
    {:ok, <<01,01,00,00,00,01,0xFD,0xCA>>} = :gen_tcp.recv(sock1, 8, 400)
    #write 0 to coil at 3200
    :ok = :gen_tcp.send(sock1, <<01,05,0x0C,0x80,00,00,0xCF,0x72>>)
    {:ok, <<01,05,0x0C,0x80,00,00>>} = :gen_tcp.recv(sock0, 6, 400)
    :ok = :gen_tcp.send(sock0, <<01,05,0x0C,0x80,00,00>>)
    {:ok, <<01,05,0x0C,0x80,00,00,0xCF,0x72>>} = :gen_tcp.recv(sock1, 8, 400)
    #write 1 to coil at 3200
    :ok = :gen_tcp.send(sock1, <<01,05,0x0C,0x80,0xFF,00,0x8E,0x82>>)
    {:ok, <<01,05,0x0C,0x80,0xFF,00>>} = :gen_tcp.recv(sock0, 6, 400)
    :ok = :gen_tcp.send(sock0, <<01,05,0x0C,0x80,0xFF,00>>)
    {:ok, <<01,05,0x0C,0x80,0xFF,00,0x8E,0x82>>} = :gen_tcp.recv(sock1, 8, 400)

    Sock.stop(pid0)
    Sock.stop(pid1)
  end

end
