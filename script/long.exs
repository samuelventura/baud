tty0 = case :os.type() do
  {:unix, :darwin} -> "cu.usbserial-FTYHQD9MA"
  {:unix, :linux} -> "ttyUSB0"
  {:win32, :nt} -> "COM10"
end

tty1 = case :os.type() do
  {:unix, :darwin} -> "cu.usbserial-FTYHQD9MB"
  {:unix, :linux} -> "ttyUSB1"
  {:win32, :nt} -> "COM11"
end

{:ok, pid0} = Baud.start_link([device: tty0, speed: 921600])
{:ok, pid1} = Baud.start_link([device: tty1, speed: 921600])

to = 60
long = String.duplicate "0123456789", 200

for i <- 1..100000 do
  
  :ok = Baud.write pid0, long, to
  case Baud.readn pid1, 2000, to do
    {:ok, ^long} -> :ok #IO.inspect {i, "Packet complete"}
    {:ok, other} -> IO.inspect {i, "Mismatch", byte_size(other)}
    {:to, part} -> 
      IO.inspect {i, "Timeout", byte_size(part)}
      #discard what was left to start clean
      :timer.sleep to
      Baud.readall pid1 
  end
end
