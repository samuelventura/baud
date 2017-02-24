
tty = case :os.type() do
  {:unix, :darwin} -> "cu.usbserial-FTVFV143"
  {:unix, :linux} -> "ttyUSB0"
  {:win32, :nt} -> "COM10"
end

{:ok, pid} = Baud.start_link([portname: tty, baudrate: 57600])
Baud.debug(pid, 1)

#40ms works on MAC 60ms required for linux
#Delay required because of response times of modport modules
delay = 60
points = [0,1,2,3,4,5,6,7]

for i <- 0..100000 do

  :io.format "~p ~n", [i]

  for n <- Enum.shuffle points do
    :ok = Baud.rtu(pid, {:fc, 1, 3000 + n, 1}, 400)
    {:ok, [1]} = Baud.rtu(pid, {:rc, 1, 3000 + n, 1}, 400)
    :timer.sleep(delay)
    {:ok, [1]} = Baud.rtu(pid, {:rc, 1, 0 + n, 1}, 400)
  end
  :timer.sleep(delay)
  {:ok, [1,1,1,1,1,1,1,1]} = Baud.rtu(pid, {:rc, 1, 0, 8}, 400)

  for n <- Enum.shuffle points do
    :ok = Baud.rtu(pid, {:fc, 1, 3000 + n, 0}, 400)
    {:ok, [0]} = Baud.rtu(pid, {:rc, 1, 3000 + n, 1}, 400)
    :timer.sleep(delay)
    {:ok, [0]} = Baud.rtu(pid, {:rc, 1, 0 + n, 1}, 400)
  end
  :timer.sleep(delay)
  {:ok, [0,0,0,0,0,0,0,0]} = Baud.rtu(pid, {:rc, 1, 0, 8}, 400)

end
