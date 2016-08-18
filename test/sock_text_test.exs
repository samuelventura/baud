defmodule Baud.SockTextTest do
  use ExUnit.Case
  alias Baud.TestHelper
  alias Baud.Sock

  test "text mode test" do
    tty0 = TestHelper.tty0()
    tty1 = TestHelper.tty1()
    {:ok, pid0} = Sock.start_link([portname: tty0, port: 4000, mode: :raw, name: Atom.to_string(__MODULE__)])
    {:ok, pid1} = Sock.start_link([portname: tty1, port: 4001, mode: :text, name: Atom.to_string(__MODULE__)])

    {:ok, sock0} = :gen_tcp.connect({127,0,0,1}, 4000, [:binary, packet: :raw, active: :false], 400)
    {:ok, sock1} = :gen_tcp.connect({127,0,0,1}, 4001, [:binary, packet: :raw, active: :false], 400)

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
