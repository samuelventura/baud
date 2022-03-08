# baud

Elixir Serial Port with Modbus RTU.

## Installation and Usage

  1. Add [`baud`](https://hex.pm/packages/baud) to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:baud, "~> MAJOR.MINOR"}]
  end
  ```

  2. Enumerate your serial ports.

  ```elixir
  ["COM1", "/dev/ttyUSB0", "/dev/tty.usbserial-FTVFV143"] = Baud.Enum.list()
  ```

  3. Interact with your serial port.

  ```elixir
  # this echo sample requires a loopback plug
  tty =
    case :os.type() do
      {:unix, :darwin} -> "/dev/tty.usbserial-FTYHQD9MA"
      {:unix, :linux} -> "/dev/ttyUSB0"
      {:win32, :nt} -> "COM5"
    end

  {:ok, pid} = Baud.start_link(device: tty)

  Baud.write(pid, "01234\n56789\n98765\n43210")
  {:ok, "01234\n"} = Baud.readln(pid)
  {:ok, "56789\n"} = Baud.readln(pid)
  {:ok, "98765\n"} = Baud.readln(pid)
  {:to, "43210"} = Baud.readln(pid)

  Baud.write(pid, "01234\r56789\r98765\r43210")
  {:ok, "01234\r"} = Baud.readcr(pid)
  {:ok, "56789\r"} = Baud.readcr(pid)
  {:ok, "98765\r"} = Baud.readcr(pid)
  {:to, "43210"} = Baud.readcr(pid)

  Baud.write(pid, "01234\n56789\n98765\n43210")
  {:ok, "01234\n"} = Baud.readn(pid, 6)
  {:ok, "56789\n"} = Baud.readn(pid, 6)
  {:ok, "98765\n"} = Baud.readn(pid, 6)
  {:to, "43210"} = Baud.readn(pid, 6)
  {:ok, ""} = Baud.readn(pid, 0)

  Baud.write(pid, "01234\n")
  Baud.write(pid, "56789\n")
  Baud.write(pid, "98765\n")
  Baud.write(pid, "43210")
  :timer.sleep(100)
  {:ok, "01234\n56789\n98765\n43210"} = Baud.readall(pid)

  Baud.stop(pid)
  ```

  4. Connect the RTU master to the testing RTU slave:

  ```elixir    
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
  ```

## Testing

```bash
# test with socat ttys
./test.sh
# test with custom ttys (null modem)
export TTY0="/dev/ttyUSB0"
export TTY1="/dev/ttyUSB1"
mix test
#in Windows
#requires COM98/COM99 com0com ports
test.bat
```

## Development

### Windows

Install `Visual C++ 2015 Build Tools` by one of the following methods:
  - Download and install [visualcppbuildtools_full.exe](http://landinghub.visualstudio.com/visual-cpp-build-tools)
  - Thru [Chocolatey](https://chocolatey.org/) `choco install VisualCppBuildTools`.

From the Windows run command launch `cmd /K c:\Users\samuel\Desktop\baud\setenv.bat` adjusting your code location accordingly.

### Ubuntu

Give yourself access to serial ports with `sudo gpasswd -s samuel dialout`. Follow the official Elixir installation instructions and install `build-essential erlang-dev` as well.

### MacOS

Give yourself access to serial ports with `sudo dseditgroup -o edit -a samuel -t user wheel`.

## Roadmap

Future

- [ ] Remote compile mix task to Linux & Windows

0.6.1

- [x] Added test.bat for Windows com0com ports

0.6.0

- [x] Using now the transport and protocol behaviors defined in modbus package

0.5.7

- [x] Updated to sniff 0.1.7
- [x] Updated to modbus 0.3.9
- [x] Added RTU slave for testability
- [x] Master module rewrite for readability
- [x] Baud module rewrite for readability

0.5.6

- [x] Updated to sniff 0.1.6 (bug fix)
- [x] Test with fake socat ttys
- [x] Full posix tty paths required
- [x] Pass test serial port thru environment variables

0.5.4

- [x] Updated to sniff 0.1.4

0.5.3

- [x] Updated to sniff 0.1.3
- [x] Document Windows/Ubuntu dependencies

0.5.2

- [x] Updated to sniff 0.1.2 need for ´iex -S mix´ to find native library in Elixir 1.5.1
- [x] Updated to modbus 0.3.7

0.5.1

- [x] Updated to sniff 0.1.1
- [x] Extract NIF to its own repo (sniff)

0.5.0

- [x] Posix NIF implementation
- [x] Win32 NIF implementation
- [x] Baud api simplification
- [x] Refactored to NIF for improved speed and test isolation
- [x] Removed sock/loop (will be implemented as part of forward)

0.4.3

- [x] Add wait4ch to handle non standard line/packet terminators

0.4.2

- [x] Port proxy added to ensure proper closing on exit status msg
- [x] Kill tests added for both baud and sock
- [x] Refactored from genserver to actor

0.4.1

- [x] Updated Makefile for Windows 10

0.4.0

- [x] Added sample script (1 y 2)
- [x] Improved documentation
- [x] Update to modbus 0.2.0 (refactoring required)

0.3.0

- [x] Integration test script for modport
- [x] Added test.sh to isolate tests run
- [x] RTU master, slave, and tcpgw loop modes
- [x] Serial port export to socket in raw, text, and modbus mode
- [x] RTU API matched to `modbus` package (1,2,3,4,5,6,15,16)
- [x] Improved timeout handling for shorter test times

0.2.0

- [x] Interactive RTU: read/write up to 8 coils at once

0.1.0

- [x] Cross platform native serial port (mac, win, linux)
- [x] Modbus (tcu-rtu), raw and text loop mode

## Research

- [ ] Support udoo neo
- [ ] Support beaglebone black
- [ ] Support raspberry pi 3 B
- [ ] Assess rewriting the windows native code using the win32 api
- [ ] Assess rewriting the windows native code using c#/.net
- [ ] Split into a core package and OS dependant packages holding native code
- [ ] loop* tests still show data corruption when run all at once
- [ ] Implement Modbus ASCII support (no available device)
- [ ] Implement DTR/RTS control and CTS/DSR monitoring
- [ ] Implement separate discard for input and output buffers
- [ ] Unit test 8N1 7E1 7O1 and baud rate setup against a confirmed gauge
- [ ] Get port names required for unit testing from environment variables
- [ ] Implement a clean exit to loop mode for a timely port close and to ensure test isolation
- [ ] Improve debugging: stderr messages are interlaced in mix test output
- [ ] Improve debugging: dev/test/prod conditional output
- [ ] Move from polling to overlapped on Windows
- [ ] Research why interchar timeout is applied when reading a single byte even having many already in the input buffer. Happens on MAC.
- [ ] Research how to bypass the 0.1s minimum granularity on posix systems
- [ ] Research higher baud rates support for posix and win32
- [ ] Research Mix unit test isolation (OS resources cleanup)
- [ ] Research printf to embed variable sized arrays as hex strings
