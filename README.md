# baud

Elixir Serial Port with Modbus RTU.

## Installation and Usage

  1. Add `baud` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:baud, "~> 0.5.0"}]
    end
    ```

  2. Enumerate your serial ports.

    ```elixir
    ["COM1", "ttyUSB0", "cu.usbserial-FTVFV143"] = Baud.Enum.list()
    ```

  3. Interact with your serial port.

    ```elixir
    tty = case :os.type() do
      {:unix, :darwin} -> "cu.usbserial-FTYHQD9MA"
      {:unix, :linux} -> "ttyUSB0"
      {:win32, :nt} -> "COM12"
    end

    #Try this with a loopback
    {:ok, pid} = Baud.start_link([device: tty])

    Baud.write pid, "01234\n56789\n98765\n43210"
    {:ok, "01234\n"} = Baud.readln pid
    {:ok, "56789\n"} = Baud.readln pid
    {:ok, "98765\n"} = Baud.readln pid
    {:to, "43210"} = Baud.readln pid

    Baud.write pid, "01234\r56789\r98765\r43210"
    {:ok, "01234\r"} = Baud.readch pid, 0x0d
    {:ok, "56789\r"} = Baud.readch pid, 0x0d
    {:ok, "98765\r"} = Baud.readch pid, 0x0d
    {:to, "43210"} = Baud.readch pid, 0x0d

    Baud.write pid, "01234\n56789\n98765\n43210"
    {:ok, "01234\n"} = Baud.readn pid, 6
    {:ok, "56789\n"} = Baud.readn pid, 6
    {:ok, "98765\n"} = Baud.readn pid, 6
    {:to, "43210"} = Baud.readn pid, 6

    Baud.write pid, "01234\n"
    Baud.write pid, "56789\n"
    Baud.write pid, "98765\n"
    Baud.write pid, "43210"
    :timer.sleep 100
    {:ok, "01234\n56789\n98765\n43210"} = Baud.readall pid
    ```

  4. Interact with your **RTU** devices.

    ```elixir    
    alias Modbus.Rtu.Master

    tty = case :os.type() do
      {:unix, :darwin} -> "cu.usbserial-FTVFV143"
      {:unix, :linux} -> "ttyUSB0"
      {:win32, :nt} -> "COM10"
    end

    #rs485 usb adapter to modport
    {:ok, pid} = Master.start_link([device: tty, speed: 57600])
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
    ```

## Roadmap

0.5.1

- [ ] Remote compile mix task to Linux & Windows
- [x] Extract NIF to its own repo (sniff)
- [ ] Document deploy dependencies

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

- Implement Modbus ASCII support (no available device)
- Get port names required for unit testing from environment variables
