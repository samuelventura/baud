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
    {:ok, "o"} = Baud.readall pid
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

  @doc """
  Starts the serial server.

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
      Agent.start_link(fn -> init(params) end, opts)
  end

  @to 400

  @doc """
    Stops the serial server.

    Returns `:ok`.
  """
  def stop(pid) do
    Agent.stop(pid)
  end

  @doc """
  Tests if the native port has completed all previous commands.

  Returns `:ok`.
  """
  def echo(pid, timeout \\ @to) do
    Agent.get(pid, fn proxy ->
      true = command(proxy, "e+")
      receive do
        {^proxy, {:data, "+"}} -> :ok
      end
    end, timeout)
  end

  @doc """
  Enables or disables native port debug output to stderr.

  Returns `:ok`.
  """
  def debug(pid, debug, timeout \\ @to) do
    Agent.get(pid, fn proxy ->
      true = command(proxy, "d#{debug}e+")
      receive do
        {^proxy, {:data, "+"}} -> :ok
      end
    end, timeout)
  end

  @doc """
  Writes `data` to the serial port.

  Returns `:ok`.
  """
  def write(pid, data, timeout \\ @to) do
    Agent.get(pid, fn proxy ->
      true = command(proxy, "we+")
      true = command(proxy, data)
      receive do
        {^proxy, {:data, "+"}} -> :ok
      end
    end, timeout)
  end

  @doc """
  Changes the packetization timeout.

  Returns `:ok`.
  """
  def packto(pid, packto, timeout \\ @to) do
    Agent.get(pid, fn proxy ->
      true = command(proxy, "i#{packto}e+")
      receive do
        {^proxy, {:data, "+"}} -> :ok
      end
    end, timeout)
  end

  @doc """
  Reads all available `data` from the serial port up to the buffer size.

  Returns `{:ok, data}`.
  """
  def readall(pid, timeout \\ @to) do
    Agent.get(pid, fn proxy ->
      true = command(proxy, "r0+#{timeout}")
      receive do
        {^proxy, {:data, packet}} -> {:ok, packet}
      end
    end, 2*timeout)
  end

  @doc """
  Reads `count` bytes.

  Returns `{:ok, data}`.
  """
  def read(pid, count, timeout \\ @to) do
    Agent.get(pid, fn proxy ->
      true = command(proxy, "r#{count}+#{timeout}")
      receive do
        {^proxy, {:data, packet}} -> {:ok, packet}
      end
    end, 2*timeout)
  end

  @doc """
  Reads a line including its trailing `\\n`.

  Returns `{:ok, line}`.
  """
  def readln(pid, timeout \\ @to) do
    Agent.get(pid, fn proxy ->
      true = command(proxy, "n#{timeout}")
      receive do
        {^proxy, {:data, packet}} -> {:ok, packet}
      end
    end, 2*timeout)
  end

  @doc """
  Reads until a char and including it.

  Returns `{:ok, data}`.
  """
  def wait4ch(pid, bin=<<_ch>>, timeout \\ @to) do
    Agent.get(pid, fn proxy ->
      true = command(proxy, "k" <> bin  <> "#{timeout}")
      receive do
        {^proxy, {:data, packet}} -> {:ok, packet}
      end
    end, 2*timeout)
  end

  @doc """
  Discards all data in the input and output buffers of the serial port.

  Returns `:ok`.
  """
  def discard(pid, timeout \\ @to) do
    Agent.get(pid, fn proxy ->
      true = command(proxy, "fde+")
      receive do
        {^proxy, {:data, "+"}} -> :ok
      end
    end, timeout)
  end

  @doc """
  Returns the number of bytes available in the serial port input buffer.

  Returns `{:ok, number_of_bytes}`.
  """
  def available(pid, timeout \\ @to) do
    Agent.get(pid, fn proxy ->
      true = command(proxy, "a")
      receive do
        {^proxy, {:data, "a" <> size}} -> {:ok, int(size)}
      end
    end, timeout)
  end

  @doc """
  Waits for at least `count` bytes to be available.

  Returns `:ok`.
  """
  def wait4rx(pid, count, timeout \\ @to) do
    Agent.get(pid, fn proxy ->
      true = command(proxy, "s#{count}+#{timeout}e+")
      receive do
        {^proxy, {:data, "+"}} -> :ok
      end
    end, 2*timeout)
  end

  @doc """
  Waits for all data to be transmitted.

  Returns `:ok`.
  """
  def wait4tx(pid, timeout \\ @to) do
    Agent.get(pid, fn proxy ->
      true = command(proxy, "fte+")
      receive do
        {^proxy, {:data, "+"}} -> :ok
      end
    end, timeout)
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
  #rs485 usb adapter to modport
  {:ok, pid} = Baud.start_link([portname: "cu.usbserial-FTVFV143", baudrate: 57600])
  #force 0 to coil at slave 1 address 3000
  :ok = Baud.rtu pid, {:fc, 1, 3000, 0}
  #read 0 from coil at slave 1 address 3000
  {:ok, [0]} = Baud.rtu pid, {:rc, 1, 3000, 1}
  #force 10 to coils at slave 1 address 3000 to 3001
  :ok = Baud.rtu pid, {:fc, 1, 3000, [1, 0]}
  #read 10 from coils at slave 1 address 3000 to 3001
  {:ok, [1, 0]} = Baud.rtu pid, {:rc, 1, 3000, 2}
  #preset 55AA to holding register at slave 1 address 3300
  :ok = Baud.rtu pid, {:phr, 1, 3300, 0x55AA}
  #read 55AA from holding register at slave 1 address 3300 to 3301
  {:ok, [0x55AA]} = Baud.rtu pid, {:rhr, 1, 3300, 1}
  ```
  """
  def rtu(pid, cmd, timeout \\ @to) do
    Agent.get(pid, fn proxy ->
      true = command(proxy, "m#{timeout}")
      true = command(proxy, Modbus.Request.pack(cmd))
      receive do
        {^proxy, {:data, response}} -> parse_res(cmd, response)
      end
    end, 2*timeout)
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
  def close(pid, timeout \\ @to) do
    Agent.get(pid, fn proxy ->
      true = command(proxy, "ce+")
      receive do
        {^proxy, {:data, "+"}} -> :ok
      end
    end, timeout)
  end

  defp init(params) do
    portname = Keyword.fetch!(params, :portname)
    baudrate = Keyword.get(params, :baudrate, "115200")
    bitconfig = Keyword.get(params, :bitconfig, "8N1")
    bufsize = Keyword.get(params, :bufsize, 255)
    packto = Keyword.get(params, :packto, 0)
    name = Keyword.get(params, :name, "")
    args = ["o#{portname},#{baudrate},#{bitconfig}b#{bufsize}i#{packto}", name]
    start_proxy(self(), args)
  end

  defp start_proxy(agent, args) do
    spawn_link(fn ->
      exec = :code.priv_dir(:baud) ++ '/native/baud'
      port = Port.open({:spawn_executable, exec}, [:binary, :exit_status, packet: 2, args: args])
      loop_proxy(agent, port)
    end)
  end
  defp loop_proxy(agent, port) do
    true = receive do
      {:cmd, cmd} ->
        true = Port.command(port, cmd)
      {^port, {:data, data}} ->
        send agent, {self(), {:data, data}}
        true
      #port exit notification
      unexpected -> {:unexpected, unexpected}
    end
    loop_proxy(agent, port)
  end

  defp command(pid, cmd) do
    send pid, {:cmd, cmd}
    true
  end

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
