# baud

Serial port with RTU and TCP-to-RTU support.

## Installation and Usage

  1. Add `baud` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:baud, "~> 0.2.0"}]
    end
    ```

  2. Build & test it:

  See [NOTES](NOTES.md) for platform specific instructions on setting up you development environment.

  ```shell
  #Serial port names are hard coded in test_helper.exs
  #A couple of null modem serial ports are required
  #com0com may work on Windows but not tested yet
  ./test.sh
  ```

  3. Use it:

    ```elixir
    alias Baud.Enum
    ["COM1", "ttyUSB0", "cu.usbserial-FTYHQD9MA"] = Enum.list()
    ```

    ```elixir
    #Do not prepend /dev/ to the port name
    {:ok, pid} = Baud.start_link([portname: "cu.usbserial-FTYHQD9MA"])
    :ok = Baud.write(pid, "Hello!\n");
    {:ok, "Hi!\n"} = Baud.read(pid, 4, 400);
    {:ok, "Hi!\n"} = Baud.readln(pid, 400);
    {:ok, 24} = Baud.available(pid);
    :ok = Baud.wait4rx(pid, 400)
    :ok = Baud.discard(pid)
    :ok = Baud.echo(pid)
    :ok = Baud.close(pid)
    ```

    ```elixir
    alias Baud.Sock
    #Do not prepend /dev/ to the port name. Mode defaults to :raw
    {:ok, pid} = Sock.start_link([portname: "ttyUSB0", port: 5000])
    #use netcat to talk to the serial port
    #nc 127.0.0.1 5000
    :ok = Sock.stop(pid)    
    ```

    ```elixir
    alias Baud.Sock
    #Do not prepend /dev/ to the port name.
    {:ok, pid} = Sock.start_link([portname: "ttyUSB0", port: 5000, mode: :rtu_tcpgw])
    #modbus TCP commands sent to 127.0.0.1:5000 will be forwarded as RTU to serial port
    :ok = Sock.stop(pid)    
    ```

    ```elixir    
    {:ok, pid} = Baud.start_link([portname: "cu.usbserial-FTVFV143", baudrate: 57600])
    #write 1 to coil at slave 2 address 3200
    :ok = Baud.rtu(pid, {:wdo, 2, 3200, 1}, 400)
    #write 0 to coil at slave 2 address 3200
    :ok = Baud.rtu(pid, {:wdo, 2, 3200, 0}, 400)
    #read 1 coil at slave 2 address 3200
    {:ok, [1]} = Baud.rtu(pid, {:rdo, 2, 3200, 1}, 400)
    ```

## Releases

Version 0.3.0

- [ ] Integration test script and panel
- [x] Added test.sh to isolate tests run
- [x] RTU master, slave, and tcpgw loop modes
- [x] Serial port export to socket in raw, text, and modbus mode
- [x] RTU API matched to `modbus` package (1,2,3,4,5,6,15,16)
- [x] Improved timeout handling for shorter test times

Version 0.2.0

- [x] Interactive RTU: read/write up to 8 coils at once

Version 0.1.0

- [x] Cross platform native serial port (mac, win, linux)
- [x] Modbus (tcu-rtu), raw and text loop mode

## TODO

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
- [ ] Research Mix unit test isolation (OS resources cleanup)
- [ ] Research printf to embed variable sized arrays as hex strings
