defmodule Baud.SockKillTest do
  use ExUnit.Case
  alias Baud.TestHelper
  alias Baud.Sock

  setup_all do TestHelper.setup_all end
  setup do TestHelper.setup end

  test "sock kill test" do
    tty0 = TestHelper.tty0()
    tty1 = TestHelper.tty1()
    {:ok, pid0} = Sock.start_link([portname: tty0, mode: :text, name: Atom.to_string(__MODULE__)])
    {:ok, pid1} = Sock.start_link([portname: tty1, mode: :text, name: Atom.to_string(__MODULE__)])
    {:ok, %{port: port0}} = Sock.id(pid0)
    {:ok, %{port: port1}} = Sock.id(pid1)

    {:ok, sock0} = :gen_tcp.connect({127,0,0,1}, port0, [:binary, packet: :line, active: :false], 400)
    {:ok, sock1} = :gen_tcp.connect({127,0,0,1}, port1, [:binary, packet: :line, active: :false], 400)

    loop(sock0, sock1, "#{port0}#{port1}\n")

    1 = count_child(pid0)
    kill_child(pid0)
    :timer.sleep(100)
    0 = count_child(pid0)
    check_closed(sock0)

    1 = count_child(pid1)
    TestHelper.kill_baud
    :timer.sleep(200)
    0 = count_child(pid1)
    check_closed(sock1)
  end

  defp loop(sock0, sock1, line) do
    for _ <- 0..10 do
      :ok = :gen_tcp.send(sock0, line)
      :ok = :gen_tcp.send(sock1, line)
      {:ok, ^line} = :gen_tcp.recv(sock0, 0)
      {:ok, ^line} = :gen_tcp.recv(sock1, 0)
    end
  end

  defp check_closed(socket) do
    :ok = :gen_tcp.send(socket, "\n")
    #close status detected on receive
    #mac returns :closed windows :econnaborted
    {:error, _} = :gen_tcp.recv(socket, 0)
    {:error, _} = :gen_tcp.send(socket, "\n")
  end

  defp kill_child(agent) do
    %{sup: sup} = Sock.state(agent)
    [child_pid] = Supervisor.which_children(sup)
      |> Enum.map(fn {_, pid, _, _} -> pid end)
    true = Process.exit(child_pid, :kill)
  end

  defp count_child(agent) do
    %{sup: sup} = Sock.state(agent)
    Supervisor.which_children(sup)
      |> Enum.map(fn {_, pid, _, _} -> pid end)
      |> Enum.count
  end

end
