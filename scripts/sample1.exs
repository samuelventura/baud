tty = case :os.type() do
  {:unix, :darwin} -> "cu.usbserial-FTYHQD9MA"
  {:unix, :linux} -> "ttyUSB0"
  {:win32, :nt} -> "COM12"
end

#Do not prepend /dev/ to the port name
#Try this with a loopback
{:ok, pid} = Baud.start_link([portname: tty])
#Send data
:ok = Baud.write pid, "Hello"
#Wait data is transmitted
:ok = Baud.wait4tx pid
#Wait at least 5 bytes are available
:ok = Baud.wait4rx pid, 5
#Check at least 5 bytes are available
{:ok, 5} = Baud.available pid
#Read 4 bytes of data
{:ok, "Hell"} = Baud.read pid, 4
#Read all available data
{:ok, "o"} = Baud.readall pid
#Send more data
:ok = Baud.write pid, "World!\n..."
#Wait at least 1 byte is available
:ok = Baud.wait4rx pid, 1
#Read all data up to first newline
{:ok, "World!\n"} = Baud.readln pid
#Discard trailing ...
:ok = Baud.discard pid
#Check nothing is available
{:ok, 0} = Baud.available pid
#Check the native port is responding
:ok = Baud.echo pid
#Close the native serial port
:ok = Baud.close pid
#Stop the server
:ok = Baud.stop pid
