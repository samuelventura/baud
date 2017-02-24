defmodule Baud do
  @moduledoc """
    Serial port module.

    ```elixir
    alias Baud.Enum
    ["COM1", "ttyUSB0", "cu.usbserial-FTVFV143"] = Enum.list()
    #Do not prepend /dev/ to the port name
    #Try this with a loopback
    {:ok, pid} = Baud.start_link([portname: "cu.usbserial-FTYHQD9MA"])
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
    {:ok, "o"} = Baud.read pid
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
    ```
  """
  use GenServer

  @doc """
  Starts the GenServer.

  `state` *must* contain a keyword list to be merged with the following defaults:

  ```elixir
  %{
    portname: "TTY",        #the port name: "COM1", "ttyUSB0", "cu.usbserial-FTYHQD9MA"
    baudrate: "115200",     #either 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200
    bitconfig: "8N1",       #either 8N1, 7E1, 7O1
    bufsize: 255,           #the buffer size. 255 is the POSIX maximum.
    packto: 0               #the packetization timeout in millis. 100 in the POSIX minimum.
                            #use 0 for non-blocking reads
  }
  ```

  `opts` is optional and is passed verbatim to GenServer.

  Returns `{:ok, pid}`.

  ## Example

    ```
    Baud.start_link([portname: "COM8"])
    ```
  """
  def start_link(params, opts \\ []) do
      GenServer.start_link(__MODULE__, params, opts)
  end

  @to 400

  @doc """
    Stops the GenServer.

    Returns `:ok`.
  """
  def stop(pid) do
    #don't use :normal or the port won't be stop
    Process.exit(pid, :stop)
  end

  @doc """
  Tests if the native port has compleated all previous commands.

  Returns `:ok`.
  """
  def echo(pid) do
    GenServer.call(pid, :echo)
  end

  @doc """
  Enables or disables native port debug output to stderr.

  Returns `:ok`.
  """
  def debug(pid, debug) do
    GenServer.call(pid, {:debug, debug})
  end

  @doc """
  Writes `data` to the serial port.

  Returns `:ok`.
  """
  def write(pid, data) do
    GenServer.call(pid, {:write, data})
  end

  @doc """
  Changes the packetization timeout.

  Returns `:ok`.
  """
  def packto(pid, packto) do
    GenServer.call(pid, {:packto, packto})
  end

  @doc """
  Reads all available `data` from the serial port up to the buffer size.

  Returns `{:ok, data}`.
  """
  def read(pid) do
    GenServer.call(pid, {:read, 0, @to})
  end

  @doc """
  Reads `count` bytes.

  Returns `{:ok, data}`.
  """
  def read(pid, count, timeout \\ 400) do
    GenServer.call(pid, {:read, count, timeout})
  end

  @doc """
  Reads a line including its trailing `\\n`.

  Returns `{:ok, line}`.
  """
  def readln(pid, timeout \\ 400) do
    GenServer.call(pid, {:readln, timeout})
  end

  @doc """
  Discards all data in the input and output buffers of the serial port.

  Returns `:ok`.
  """
  def discard(pid) do
    GenServer.call(pid, :discard)
  end

  @doc """
  Returns the number of bytes available in the serial port input buffer.

  Returns `{:ok, number_of_bytes}`.
  """
  def available(pid) do
    GenServer.call(pid, :available)
  end

  @doc """
  Waits for at least `count` bytes to be available.

  Returns `:ok`.
  """
  def wait4rx(pid, count, timeout \\ 400) do
    GenServer.call(pid, {:wait4rx, count, timeout})
  end

  @doc """
  Waits for all data to be transmitted.

  Returns `:ok`.
  """
  def wait4tx(pid, timeout \\ 400) do
    GenServer.call(pid, {:wait4tx, timeout})
  end

  @doc """
  Sends an RTU command where `cmd` is formatted according to `modbus` package.

  `cmd` is one of:

  - `{:rc, slave, address, count}` read count coils.
  - `{:ri, slave, address, count}` read count inputs.
  - `{:rhr, slave, address, count}` read count holding registers.
  - `{:rir, slave, address, count}` read count input registers.
  - `{:fc, slave, address, value}` force single coil.
  - `{:phr, slave, address, value}` preset single holding register.
  - `{:fc, slave, address, values}` force multiple coils.
  - `{:phr, slave, address, values}` preset multiple holding registers.

  Returns `:ok | {:ok, [values]}`.

  ## Example:
  ```
  {:ok, pid} = Baud.start_link([portname: "cu.usbserial-FTVFV143", baudrate: 57600])
  #force 0 to coil at slave 1 address 3000
  :ok = Baud.rtu(pid, {:fc, 1, 3000, 0}, 400)
  #read 0 from coil at slave 1 address 3000
  {:ok, [0]} = Baud.rtu(pid, {:rc, 1, 3000, 1}, 400)
  #force 10 to coils at slave 1 address 3000 to 3001
  :ok = Baud.rtu(pid, {:fc, 1, 3000, [1, 0]}, 400)
  #read 10 from coils at slave 1 address 3000 to 3001
  {:ok, [1, 0]} = Baud.rtu(pid, {:rc, 1, 3000, 2}, 400)
  #preset 55AA to holding register at slave 1 address 3300
  :ok = Baud.rtu(pid, {:phr, 1, 3300, 0x55AA}, 400)
  #read 55AA from holding register at slave 1 address 3300 to 3301
  {:ok, [0x55AA]} = Baud.rtu(pid, {:rhr, 1, 3300, 1}, 400)
  ```
  """
  def rtu(pid, cmd, timeout \\ 400) do
    GenServer.call(pid, {:rtu, cmd, timeout})
  end

  @doc """
    Closes the serial port and waits for confirmation.

    Stopping the GenServer will close the port stdio pipes
    the native port will exit upon detection of a closed stdio
    and the OS will release the serial port. All this happens
    automatically but also within an undefined time frame.

    There are times when releasing the OS resources in a
    timely manner is required. In unit testing for example,
    you want the previous test to release the serial port before
    attemping to open it again in the next test (and fail).

    Returns `:ok`.
  """
  def close(pid) do
    GenServer.call(pid, :close)
  end

  ##########################################
  # GenServer Implementation
  ##########################################

  def init(params) do
    portname = Keyword.fetch!(params, :portname)
    baudrate = Keyword.get(params, :baudrate, "115200")
    bitconfig = Keyword.get(params, :bitconfig, "8N1")
    bufsize = Keyword.get(params, :bufsize, 255)
    packto = Keyword.get(params, :packto, 0)
    name = Keyword.get(params, :name, "")
    exec = :code.priv_dir(:baud) ++ '/native/baud'
    args = ["o#{portname},#{baudrate},#{bitconfig}b#{bufsize}i#{packto}", name]
    port = Port.open({:spawn_executable, exec}, [:binary, :exit_status, packet: 2, args: args])
    {:ok, port}
  end

  def terminate(_reason, _state) do
    #:io.format "terminate ~p ~p ~p ~n", [__MODULE__, reason, state]
  end

  def handle_call(:echo, _from, port) do
    true = Port.command(port, "e+")
    receive do
      {^port, {:data, "+"}} -> {:reply, :ok, port}
    after
      @to -> {:stop, {:echo, :timeout}, port}
    end
  end

  def handle_call({:debug, debug}, _from, port) do
    true = Port.command(port, "d#{debug}e+")
    receive do
      {^port, {:data, "+"}} -> {:reply, :ok, port}
    after
      @to -> {:stop, {:debug, :timeout}, port}
    end
  end

  def handle_call({:packto, packto}, _from, port) do
    true = Port.command(port, "i#{packto}e+")
    receive do
      {^port, {:data, "+"}} -> {:reply, :ok, port}
    after
      @to -> {:stop, {:packto, :timeout}, port}
    end
  end

  def handle_call({:write, data}, _from, port) do
    true = Port.command(port, "we+")
    true = Port.command(port, data)
    receive do
      {^port, {:data, "+"}} -> {:reply, :ok, port}
    after
      @to -> {:stop, {:write, :timeout}, port}
    end
  end

  def handle_call({:read, count, timeout}, _from, port) do
    true = Port.command(port, "r#{count}+#{timeout}")
    receive do
      {^port, {:data, packet}} -> {:reply, {:ok, packet}, port}
    after
      timeout -> {:stop, {:read, :timeout}, port}
    end
  end

  def handle_call({:readln, timeout}, _from, port) do
    true = Port.command(port, "n#{timeout}")
    receive do
      {^port, {:data, packet}} -> {:reply, {:ok, packet}, port}
    after
      timeout -> {:stop, {:readln, :timeout}, port}
    end
  end

  def handle_call({:wait4rx, count, timeout}, _from, port) do
    true = Port.command(port, "s#{count}+#{timeout}e+")
    receive do
      {^port, {:data, "+"}} -> {:reply, :ok, port}
    after
      timeout -> {:stop, {:wait4rx, :timeout}, port}
    end
  end

  def handle_call({:wait4tx, timeout}, _from, port) do
    true = Port.command(port, "fte+")
    receive do
      {^port, {:data, "+"}} -> {:reply, :ok, port}
    after
      timeout -> {:stop, {:wait4tx, :timeout}, port}
    end
  end

  def handle_call(:available, _from, port) do
    true = Port.command(port, "a")
    receive do
      {^port, {:data, "a" <> size}} -> {:reply, {:ok, int(size)}, port}
    after
      @to -> {:stop, {:available, :timeout}, port}
    end
  end

  def handle_call(:discard, _from, port) do
    true = Port.command(port, "fde+")
    receive do
      {^port, {:data, "+"}} -> {:reply, :ok, port}
    after
      @to -> {:stop, {:discard, :timeout}, port}
    end
  end

  def handle_call({:rtu, cmd, timeout}, _from, port) do
    true = Port.command(port, "m#{timeout}")
    true = Port.command(port, Modbus.Request.pack(cmd))
    receive do
      {^port, {:data, response}} -> {:reply, parse_res(cmd, response), port}
    after
      timeout -> {:stop, {:rtu, :timeout}, port}
    end
  end

  def handle_call(:close, _from, port) do
    true = Port.command(port, "ce+")
    receive do
      {^port, {:data, "+"}} -> {:reply, :ok, port}
    after
      @to -> {:stop, {:close, :timeout}, port}
    end
  end

  def handle_info({port, {:data, packet}}, port) do
    {:stop, {:port_data, packet}, port}
  end

  def handle_info({port, {:exit_status, exit_status}}, port) do
    {:stop, {:port_died, exit_status}, port}
  end

  ##########################################
  # Internal Implementation
  ##########################################

  defp int(str) do
    {val, _} = Integer.parse(str)
    val
  end

  defp parse_res(cmd, response) do
    values = Modbus.Response.parse(cmd, response)
    case values do
      nil -> :ok
      _ -> {:ok, values}
    end
  end

end
