# baud

Serial Port for Elixir.

## Installation and Usage

  1. Add `baud` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:baud, "~> 0.1.0"}]
    end
    ```

  2. Build & test it:

  See [NOTES](NOTES.md) for platform specific instructions on setting up you development environment.

  ```bash
  #Serial port names are hard coded in test_helper.exs
  #A couple of serial ports are required
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

## TODO

- [ ] Implement DTR/RTS control and CTS/DSR monitoring
- [ ] Implement separate discard for input and output buffers
- [ ] Unit test 8N1 7E1 7O1 and baud rate setup against a confirmed gauge
- [ ] Get port names required for unit testing from environment variables
- [ ] Implement a clean exit to loop mode for a timely port close and to ensure test isolation
- [ ] Improve debugging: stderr messages are interlaced in mix test output
- [ ] Move from polling to overlapped on Windows
- [ ] Research how to bypass the 0.1s minimum granularity on posix systems
- [ ] Research Mix unit test isolation (OS resources cleanup)
- [ ] Research printf to embed variable sized arrays as hex strings
