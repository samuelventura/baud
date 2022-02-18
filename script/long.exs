tty0 =
  case :os.type() do
    {:unix, :darwin} -> "/dev/tty.usbserial-FTYHQD9MA"
    {:unix, :linux} -> "/dev/ttyUSB0"
    {:win32, :nt} -> "COM10"
  end

tty1 =
  case :os.type() do
    {:unix, :darwin} -> "/dev/tty.usbserial-FTYHQD9MB"
    {:unix, :linux} -> "/dev/ttyUSB1"
    {:win32, :nt} -> "COM11"
  end

{:ok, pid0} = Baud.start_link(device: tty0, speed: 115_200)
{:ok, pid1} = Baud.start_link(device: tty1, speed: 115_200)

to = 100
long = String.duplicate("0123456789", 20)

for i <- 1..100_000 do
  :ok = Baud.write(pid0, long, to)

  case Baud.readn(pid1, byte_size(long), to) do
    {:ok, ^long} ->
      IO.inspect({i, "Packet complete"})
      :ok

    {:ok, other} ->
      IO.inspect({i, "Mismatch", byte_size(other)})

    {:to, part} ->
      IO.inspect({i, "Timeout", byte_size(part)})
      # discard what was left to start clean
      :timer.sleep(to)
      Baud.readall(pid1)
  end
end
