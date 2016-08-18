defmodule Baud.SockRtuTcpGwTest do
  use ExUnit.Case
  alias Baud.TestHelper
  alias Baud.Sock

  test "rtu tcp gw mode test" do
    tty0 = TestHelper.tty0()
    tty1 = TestHelper.tty1()
    {:ok, pid0} = Sock.start_link([portname: tty0, port: 4000, mode: :rtu_tcpgw, name: Atom.to_string(__MODULE__)])
    {:ok, pid1} = Sock.start_link([portname: tty1, port: 4001, mode: :raw, name: Atom.to_string(__MODULE__)])

    {:ok, sock0} = :gen_tcp.connect({127,0,0,1}, 4000, [:binary, packet: :raw, active: :false], 400)
    {:ok, sock1} = :gen_tcp.connect({127,0,0,1}, 4001, [:binary, packet: :raw, active: :false], 400)

    #read 1 from coil at 0
    :ok = :gen_tcp.send(sock0, <<00,05,00,00,00,06,01,01,00,00,00,01>>);
    {:ok, <<01,01,00,00,00,01,0xFD,0xCA>>} = :gen_tcp.recv(sock1, 8, 400)
    :ok = :gen_tcp.send(sock1, <<01,01,01,01,0x90,0x48>>);
    {:ok, <<00,05,00,00,00,04,01,01,01,01>>} = :gen_tcp.recv(sock0, 10, 400)
    #write 0 to coil at 3200
    :ok = :gen_tcp.send(sock0, <<00,04,00,00,00,06,01,05,0x0C,0x80,00,00>>)
    {:ok, <<01,05,0x0C,0x80,00,00,0xCF,0x72>>} = :gen_tcp.recv(sock1, 8, 400)
    :ok = :gen_tcp.send(sock1, <<01,05,0x0C,0x80,00,00,0xCF,0x72>>)
    {:ok, <<00,04,00,00,00,06,01,05,0x0C,0x80,00,00>>} = :gen_tcp.recv(sock0, 12, 400)
    #write 1 to coil at 3200
    :ok = :gen_tcp.send(sock0, <<00,04,00,00,00,06,01,05,0x0C,0x80,0xFF,00>>)
    {:ok, <<01,05,0x0C,0x80,0xFF,00,0x8E,0x82>>} = :gen_tcp.recv(sock1, 8, 400)
    :ok = :gen_tcp.send(sock1, <<01,05,0x0C,0x80,0xFF,00,0x8E,0x82>>)
    {:ok, <<00,04,00,00,00,06,01,05,0x0C,0x80,0xFF,00>>} = :gen_tcp.recv(sock0, 12, 400)

    Sock.stop(pid0)
    Sock.stop(pid1)
  end

end
