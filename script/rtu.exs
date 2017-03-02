alias Modbus.Rtu.Master

tty = case :os.type() do
  {:unix, :darwin} -> "cu.usbserial-FTVFV143"
  {:unix, :linux} -> "ttyUSB0"
  {:win32, :nt} -> "COM10"
end

#rs485 usb adapter to modport
{:ok, pid} = Master.start_link([portname: tty, baudrate: 57600])
#force 0 to coil at slave 1 address 3000
:ok = Master.exec pid, {:fc, 1, 3000, 0}
#read 0 from coil at slave 1 address 3000
{:ok, [0]} = Master.exec pid, {:rc, 1, 3000, 1}
#force 10 to coils at slave 1 address 3000 to 3001
:ok = Master.exec pid, {:fc, 1, 3000, [1, 0]}
#read 10 from coils at slave 1 address 3000 to 3001
{:ok, [1, 0]} = Master.exec pid, {:rc, 1, 3000, 2}
#preset 55AA to holding register at slave 1 address 3300
:ok = Master.exec pid, {:phr, 1, 3300, 0x55AA}
#read 55AA from holding register at slave 1 address 3300 to 3301
{:ok, [0x55AA]} = Master.exec pid, {:rhr, 1, 3300, 1}
