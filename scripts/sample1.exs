#Do not prepend /dev/ to the port name
#Try this with a loopback
{:ok, pid} = Baud.start_link([portname: "cu.usbserial-FTYHQD9MA"])
#Send data
:ok = Baud.write(pid, "Hello");
#Wait data is transmitted
:ok = Baud.wait4tx(pid, 400)
#Wait at least 5 bytes are available
:ok = Baud.wait4rx(pid, 5, 400)
#Check at least 5 bytes are available
{:ok, 5} = Baud.available(pid);
#Read 4 bytes of data
{:ok, "Hell"} = Baud.read(pid, 4, 400);
#Read all available data
{:ok, "o"} = Baud.read(pid);
#Send more data
:ok = Baud.write(pid, "World!\n...");
#Wait at least 1 byte is available
:ok = Baud.wait4rx(pid, 1, 400)
#Read all data up to first newline
{:ok, "World!\n"} = Baud.readln(pid, 400);
#Discard the trailing ...
:ok = Baud.discard(pid)
#Check nothing is available
{:ok, 0} = Baud.available(pid);
#Check the native port is responding
:ok = Baud.echo(pid)
#Close the native serial port
:ok = Baud.close(pid)
#Stop the server
:ok = Baud.stop(pid)
