defmodule Baud.SockTextTest do
  use ExUnit.Case
  alias Baud.TestHelper
  alias Baud.Sock

  test "text mode test" do
    tty0 = TestHelper.tty0()
    tty1 = TestHelper.tty1()
    {:ok, pid0} = Sock.start_link([portname: tty0, mode: :raw, name: Atom.to_string(__MODULE__)])
    {:ok, pid1} = Sock.start_link([portname: tty1, mode: :text, name: Atom.to_string(__MODULE__)])
    {:ok, _ip0, port0, _name0} = Sock.id(pid0)
    {:ok, _ip1, port1, _name1} = Sock.id(pid1)

    {:ok, sock0} = :gen_tcp.connect({127,0,0,1}, port0, [:binary, packet: :raw, active: :false], 400)
    {:ok, sock1} = :gen_tcp.connect({127,0,0,1}, port1, [:binary, packet: :raw, active: :false], 400)

    #text mode should packetize up to \n
    :ok = :gen_tcp.send(sock0, "echo0");
    :ok = :gen_tcp.send(sock0, "echo1");
    :ok = :gen_tcp.send(sock0, "echo2");
    :ok = :gen_tcp.send(sock0, "echo3");
    :ok = :gen_tcp.send(sock0, "\n");
    {:ok, "echo0echo1echo2echo3\n"} = :gen_tcp.recv(sock1, 0, 400)

    Sock.stop(pid0)
    Sock.stop(pid1)
  end

end
