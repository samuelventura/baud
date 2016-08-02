# baud

Serial port with RTU support.

## Installation and Usage

  1. Add `baud` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:baud, "~> 0.2.0"}]
    end
    ```

  2. Build & test it:

  See [NOTES](NOTES.md) for platform specific instructions on setting up you development environment.

  ```bash
  #Serial port names are hard coded in test_helper.exs
  #A couple of null modem serial ports and one RS485 to a modport rack
  mix test
  ```

  3. Use it:

    ```elixir
    ["COM1", "ttyUSB0", "cu.usbserial-FTYHQD9MA"] = Baud.Enum.list()
    #Do not prepend /dev/ to the port name
    {:ok, pid} = Baud.start_link([portname: "cu.usbserial-FTYHQD9MA"])
    :ok = Baud.write(pid, "Hello!\n");
    {:ok, "Hi!\n"} = Baud.read(pid);
    {:ok, "Hi!\n"} = Baud.readln(pid, 400);
    {:ok, 24} = Baud.available(pid);
    :ok = Baud.wait4data(pid, 400)
    :ok = Baud.discard(pid)
    :ok = Baud.echo(pid)
    :ok = Baud.close(pid)
    ```

    ```elixir    
    alias Baud.Rtu
    {:ok, pid} = Rtu.start_link([portname: "cu.usbserial-FTVFV143", baudrate: "57600"])
    :ok = Rtu.wcoils(pid, 1, 3200, [0,0,0,0,0,0,0,0]);
    :ok = Rtu.wcoil(pid, 1, 3200, 1);
    {:ok, 1} = Rtu.rcoil(pid, 1, 3200);
    :ok = Rtu.wcoil(pid, 1, 3203, 1);
    {:ok, [1, 0, 0, 1]} = Rtu.rcoils(pid, 1, 3200, 4);
    :ok = Rtu.discard(pid)
    :ok = Rtu.echo(pid)
    :ok = Rtu.close(pid)
    ```

## Releases

Version 0.1.0

- [x] Cross platform native serial port (mac, win, linux)
- [x] Modbus (tcu-rtu), raw and text loop mode (for sersock)

Version 0.2.0

- [x] Interactive RTU: read/write up to 8 coils at once

## TODO

- [ ] Implement RTU read input(s), read/write register(s)
- [ ] Implement DTR/RTS control and CTS/DSR monitoring
- [ ] Implement separate discard for input and output buffers
- [ ] Unit test 8N1 7E1 7O1 and baud rate setup against a confirmed gauge
- [ ] Get port names required for unit testing from environment variables
- [ ] Implement a clean exit to loop mode for a timely port close and to ensure test isolation
- [ ] Improve debugging: stderr messages are interlaced in mix test output
- [ ] Improve debugging: dev/test/prod conditional output
- [ ] Move from polling to overlapped on Windows
- [ ] Research why interchar timeout is applied when reading a single byte even
      having many already in the input buffer. Happens on MAC.
- [ ] Research how to bypass the 0.1s minimum granularity on posix systems
- [ ] Research Mix unit test isolation (OS resources cleanup)
- [ ] Research printf to embed variable sized arrays as hex strings
