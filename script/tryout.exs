defmodule Waiter do
  def waitOneOrMore(pid) do
    case Baud.readall(pid, 100) do
      {:ok, <<>>} ->
        :timer.sleep(10)
        waitOneOrMore(pid)

      {:ok, data} ->
        data
    end
  end
end

tty0 =
  case :os.type() do
    {:unix, :darwin} -> "cu.usbserial-FTYHQD9MA"
    {:unix, :linux} -> "ttyUSB0"
    {:win32, :nt} -> "COM10"
  end

tty1 =
  case :os.type() do
    {:unix, :darwin} -> "cu.usbserial-FTYHQD9MB"
    {:unix, :linux} -> "ttyUSB1"
    {:win32, :nt} -> "COM11"
  end

{:ok, pid0} = Baud.start_link(device: tty0, speed: 921_600)

parent = self()

spawn(fn ->
  {:ok, pid1} = Baud.start_link(device: tty1, speed: 921_600)
  IO.inspect({self(), "Entering wait loop..."})
  data = Waiter.waitOneOrMore(pid1)
  IO.inspect({self(), "data:", data})
  send(parent, data)
end)

IO.inspect({self(), "Sleeping..."})
:timer.sleep(2000)
IO.inspect({self(), "Writing..."})
Baud.write(pid0, "0123456789")

receive do
  data -> IO.inspect({self(), "data:", data})
  5_000 -> IO.inspect({self(), "Timeout!"})
end
