alias Modbus.Rtu.Master

tty =
  case :os.type() do
    {:unix, :darwin} -> "/dev/tty.usbserial-FTVFV143"
    {:unix, :linux} -> "/dev/ttyUSB0"
    {:win32, :nt} -> "COM5"
  end

{:ok, pid} = Master.start_link(device: tty, speed: 57600)

delay = 60
points = [0, 1, 2, 3, 4, 5, 6, 7]

for i <- 0..100_000 do
  :io.format("~p ~n", [i])

  for n <- Enum.shuffle(points) do
    :ok = Master.exec(pid, {:fc, 1, 3000 + n, 1})
    {:ok, [1]} = Master.exec(pid, {:rc, 1, 3000 + n, 1})
    :timer.sleep(delay)
    {:ok, [1]} = Master.exec(pid, {:rc, 1, 0 + n, 1})
  end

  :timer.sleep(delay)
  {:ok, [1, 1, 1, 1, 1, 1, 1, 1]} = Master.exec(pid, {:rc, 1, 0, 8})

  for n <- Enum.shuffle(points) do
    :ok = Master.exec(pid, {:fc, 1, 3000 + n, 0})
    {:ok, [0]} = Master.exec(pid, {:rc, 1, 3000 + n, 1})
    :timer.sleep(delay)
    {:ok, [0]} = Master.exec(pid, {:rc, 1, 0 + n, 1})
  end

  :timer.sleep(delay)
  {:ok, [0, 0, 0, 0, 0, 0, 0, 0]} = Master.exec(pid, {:rc, 1, 0, 8})
end
