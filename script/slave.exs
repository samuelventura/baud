# run with: mix slave
alias Baud.Slave
alias Baud.Master

tty0 =
  case :os.type() do
    {:unix, :darwin} -> "/dev/tty.usbserial-FTYHQD9MA"
    {:unix, :linux} -> "/dev/ttyUSB0"
    {:win32, :nt} -> "COM5"
  end

tty1 =
  case :os.type() do
    {:unix, :darwin} -> "/dev/tty.usbserial-FTYHQD9MB"
    {:unix, :linux} -> "/dev/ttyUSB1"
    {:win32, :nt} -> "COM6"
  end

# start your slave with a shared model
model = %{
  0x50 => %{
    {:c, 0x5152} => 0,
    {:i, 0x5354} => 0,
    {:i, 0x5355} => 1,
    {:hr, 0x5657} => 0x6162,
    {:ir, 0x5859} => 0x6364,
    {:ir, 0x585A} => 0x6566
  }
}

{:ok, slave} = Slave.start_link(model: model, device: tty0, speed: 115_200)
{:ok, master} = Master.start_link(device: tty1, speed: 115_200)

# read input
{:ok, [0, 1]} = Master.exec(master, {:ri, 0x50, 0x5354, 2})
# read input registers
{:ok, [0x6364, 0x6566]} = Master.exec(master, {:rir, 0x50, 0x5859, 2})

# toggle coil and read it back
:ok = Master.exec(master, {:fc, 0x50, 0x5152, 0})
{:ok, [0]} = Master.exec(master, {:rc, 0x50, 0x5152, 1})
:ok = Master.exec(master, {:fc, 0x50, 0x5152, 1})
{:ok, [1]} = Master.exec(master, {:rc, 0x50, 0x5152, 1})

# increment holding register and read it back
{:ok, [0x6162]} = Master.exec(master, {:rhr, 0x50, 0x5657, 1})
:ok = Master.exec(master, {:phr, 0x50, 0x5657, 0x6163})
{:ok, [0x6163]} = Master.exec(master, {:rhr, 0x50, 0x5657, 1})

:ok = Master.stop(master)
:ok = Slave.stop(slave)
