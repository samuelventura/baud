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

pk =
  Enum.reduce(0..255, [], fn i, list ->
    [<<i>> | list]
  end)
  |> Enum.reverse()
  |> :erlang.iolist_to_binary()

Stream.iterate(0, &(&1 + 1))
|> Enum.each(fn i ->
  :ok = Baud.write(pid0, pk)

  case Baud.readn(pid1, byte_size(pk), to) do
    {:ok, ^pk} ->
      IO.inspect({i, "Packet ok"})
      :ok

    {:ok, other} ->
      IO.inspect({i, "Mismatch", byte_size(other)})

    {:to, part} ->
      IO.inspect({i, "Timeout", byte_size(part)})
      # discard what was left to start clean
      :timer.sleep(to)
      Baud.readall(pid1)
  end
end)
