defmodule Baud.SockReplaceTest do
  use ExUnit.Case
  alias Baud.TestHelper
  alias Baud.Sock

  setup_all do TestHelper.setup_all end
  setup do TestHelper.setup end

  test "sock replace test" do
    tty0 = TestHelper.tty0()
    tty1 = TestHelper.tty1()
    {:ok, pid0} = Sock.start_link([portname: tty0, mode: :text, name: Atom.to_string(__MODULE__)])
    {:ok, pid1} = Sock.start_link([portname: tty1, mode: :text, name: Atom.to_string(__MODULE__)])
    {:ok, %{port: port0}} = Sock.id(pid0)
    {:ok, %{port: port1}} = Sock.id(pid1)

    {:ok, sock0} = :gen_tcp.connect({127,0,0,1}, port0, [:binary, packet: :line, active: :false], 400)
    {:ok, sock1} = :gen_tcp.connect({127,0,0,1}, port1, [:binary, packet: :line, active: :false], 400)

    loop(sock0, sock1, "#{port0}#{port1}\n")

    {:ok, sock1} = :gen_tcp.connect({127,0,0,1}, port1, [:binary, packet: :line, active: :false], 400)

    #windows fails the first reconnection attempt
    {:ok, sock1} = case :os.type() do
      {:win32, :nt} ->
        :timer.sleep(400) #allow the close/reopen to settle
        :gen_tcp.connect({127,0,0,1}, port1, [:binary, packet: :line, active: :false], 400)
      _ -> {:ok, sock1}
    end
    :timer.sleep(100) #allow the close/reopen to settle

    loop(sock0, sock1, "#{port0}#{port1}\n")
    loop(sock1, sock0, "#{port0}#{port1}\n")

  end

  defp loop(sock0, sock1, line) do
    for _ <- 0..10 do
      :ok = :gen_tcp.send(sock0, line)
      {:ok, ^line} = :gen_tcp.recv(sock1, 0)
    end
  end

end
