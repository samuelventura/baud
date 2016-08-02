defmodule Baud.ModportTest do
  use ExUnit.Case
  alias Baud.TestHelper
  alias Baud.Rtu
  @reps 3

  @doc """
  #Modport 57600,8N1 thru USB-RS485-WE USB to RS485 Adapter
  """
  test "modport test" do
    tty = TestHelper.tty()
    {:ok, pid} = Rtu.start_link([portname: tty, baudrate: 57600, packto: 0])
    :ok = Rtu.echo(pid)

    #MDDIDC8 Digital Input (Rotary switch = 1)
    {:ok, 1} = Rtu.rcoil(pid, 1, 0)
    {:ok, 0} = Rtu.rcoil(pid, 1, 1)

    #MDDORL8 Relay Digital Output (Rotary switch = 1)
    :ok = Rtu.wcoils(pid, 1, 3200, [0,0,1,1,1,0,0,1])
    {:ok, [0,0,1,1,1,0,0,1]} = Rtu.rcoils(pid, 1, 3200, 8)

    Enum.each 0..7, fn x ->
      :ok = Rtu.off(pid, 1, 3200 + x)
      {:ok, 0} = Rtu.rcoil(pid, 1, 3200 + x)
    end

    Enum.each 0..7, fn x ->
      :ok = Rtu.on(pid, 1, 3200 + x)
      {:ok, 1} = Rtu.rcoil(pid, 1, 3200 + x)
    end

    Enum.each 0..7, fn x ->
      :ok = Rtu.wcoil(pid, 1, 3200 + x, 0)
      {:ok, 0} = Rtu.rcoil(pid, 1, 3200 + x)
    end

    Enum.each 0..7, fn x ->
      :ok = Rtu.wcoil(pid, 1, 3200 + x, 1)
      {:ok, 1} = Rtu.rcoil(pid, 1, 3200 + x)
    end

    Rtu.close(pid);
    Rtu.stop(pid);
  end

end
