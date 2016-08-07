defmodule Baud.Test do
  use ExUnit.Case
  alias Baud.TestHelper
  @reps 3

  @doc """
  Check the baud genserver API.
  """
  test "baud test" do
    tty0 = TestHelper.tty0()
    tty1 = TestHelper.tty1()
    {:ok, pid0} = Baud.start_link([portname: tty0, packto: 0])
    {:ok, pid1} = Baud.start_link([portname: tty1, packto: 100])
    :ok = Baud.echo(pid0)
    :ok = Baud.echo(pid1)

    #only issue readln on the one with packto=0
    Enum.each 1..@reps, fn _x ->
      :ok = Baud.write(pid1, "echo0\n")
      :ok = Baud.wait4data(pid0, 400)
      #FIXME may require delay
      :timer.sleep(100)
      :ok = Baud.discard(pid0)
      :ok = Baud.write(pid1, "echo1\n")
      {:ok, "echo1\n"} = Baud.readln(pid0, 400)
    end

    #only expect read to return the complete packed on the one with packto=100
    Enum.each 1..@reps, fn _x ->
      :ok = Baud.write(pid0, "echo0\n")
      :ok = Baud.wait4data(pid1, 400)
      #FIXME may require delay
      :timer.sleep(100)
      {:ok, 6} = Baud.available(pid1)
      {:ok, "echo0\n"} = Baud.read(pid1)
    end

    Baud.close(pid0);
    Baud.close(pid1);
    Baud.stop(pid0);
    Baud.stop(pid1);
  end

end
