tty =
  case :os.type() do
    {:unix, :darwin} -> "/dev/tty.usbserial-FTYHQD9MA"
    {:unix, :linux} -> "/dev/ttyUSB0"
    {:win32, :nt} -> "COM5"
  end

# Try this with a loopback
{:ok, pid} = Baud.start_link(device: tty)

Baud.write(pid, "01234\n56789\n98765\n43210")
{:ok, "01234\n"} = Baud.readln(pid)
{:ok, "56789\n"} = Baud.readln(pid)
{:ok, "98765\n"} = Baud.readln(pid)
{:to, "43210"} = Baud.readln(pid)

Baud.write(pid, "01234\r56789\r98765\r43210")
{:ok, "01234\r"} = Baud.readch(pid, 0x0D)
{:ok, "56789\r"} = Baud.readch(pid, 0x0D)
{:ok, "98765\r"} = Baud.readch(pid, 0x0D)
{:to, "43210"} = Baud.readch(pid, 0x0D)

Baud.write(pid, "01234\n56789\n98765\n43210")
{:ok, "01234\n"} = Baud.readn(pid, 6)
{:ok, "56789\n"} = Baud.readn(pid, 6)
{:ok, "98765\n"} = Baud.readn(pid, 6)
{:to, "43210"} = Baud.readn(pid, 6)

Baud.write(pid, "01234\n")
Baud.write(pid, "56789\n")
Baud.write(pid, "98765\n")
Baud.write(pid, "43210")
:timer.sleep(100)
{:ok, "01234\n56789\n98765\n43210"} = Baud.readall(pid)
