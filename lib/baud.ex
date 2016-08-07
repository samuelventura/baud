defmodule Baud do
  @moduledoc """
    Standard serial port module.

    ```elixir
    ["COM1", "ttyUSB0", "cu.usbserial-FTYHQD9MA"] = Baud.Enum.list()
    #Do not prepend /dev/ to the port name
    {:ok, pid} = Baud.start_link([portname: "cu.usbserial-FTYHQD9MA"])
    :ok = Baud.write(pid, "Hello!\\n");
    {:ok, "Hi!\\n"} = Baud.read(pid);
    {:ok, "Hi!\\n"} = Baud.readln(pid, 400);
    {:ok, 24} = Baud.available(pid);
    :ok = Baud.wait4data(pid, 400)
    :ok = Baud.discard(pid)
    :ok = Baud.echo(pid)
    :ok = Baud.close(pid)
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
  }
  ```

  `opts` is optional and is passed verbatim to GenServer.

  Returns `{:ok, pid}`.

  ## Example

    ```
    Baud.Server.start_link([portname: "COM8"])
    ```
  """
  def start_link(state, opts \\ []) do
      GenServer.start_link(__MODULE__, state, opts)
  end

  @to 400

  @doc """
    Stops the GenServer with :normal.

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
  Writes `data` to the serial port.

  Returns `:ok`.
  """
  def write(pid, data) do
    GenServer.call(pid, {:write, data})
  end

  @doc """
  Reads all available `data` from the serial port up to the buffer size.

  Returns `:ok`.
  """
  def read(pid) do
    GenServer.call(pid, :read)
  end

  @doc """
  Reads available data returning when either `\\n` is received,
  the timeout has expired or the buffer is full. Partial lines may
  be returned without warning so check for trailing `\\n` on received data.

  Returns `{:ok, line}`.
  """
  def readln(pid, timeout) do
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
  Waits for the specified `timeout` and returns `:ok` as soon
  as there is data available or `:timeout` if not.

  Returns `:ok` | `:timeout`.
  """
  def wait4data(pid, timeout) do
    GenServer.call(pid, {:wait4data, timeout})
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

  def init(state) do
    config = Enum.into(state, %{portname: "TTY", baudrate: "115200", bitconfig: "8N1", bufsize: 255, packto: 0})
    exec = :code.priv_dir(:baud) ++ '/native/baud'
    args = ["o#{config.portname},#{config.baudrate},#{config.bitconfig}b#{config.bufsize}i#{config.packto}"]
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

  def handle_call({:write, data}, _from, port) do
    true = Port.command(port, "w")
    true = Port.command(port, data)
    {:reply, :ok, port}
  end

  def handle_call(:read, _from, port) do
    true = Port.command(port, "r")
    receive do
      {^port, {:data, packet}} -> {:reply, {:ok, packet}, port}
    after
      @to -> {:stop, {:read, :timeout}, port}
    end
  end

  def handle_call({:readln, timeout}, _from, port) do
    true = Port.command(port, "n#{timeout}")
    receive do
      {^port, {:data, packet}} -> {:reply, {:ok, packet}, port}
    after
      timeout+@to -> {:stop, {:readln, :timeout}, port}
    end
  end

  def handle_call({:wait4data, timeout}, _from, port) do
    true = Port.command(port, "s#{timeout}")
    receive do
      {^port, {:data, "so"}} -> {:reply, :ok, port}
      {^port, {:data, "st"}} -> {:reply, :timeout, port}
    after
      timeout+@to -> {:stop, {:wait4data, :timeout}, port}
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
    true = Port.command(port, "fd")
    {:reply, :ok, port}
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

end
