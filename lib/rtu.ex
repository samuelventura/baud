defmodule Baud.Rtu do
  @moduledoc """
    Rtu module.

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
  """
  use GenServer
  use Bitwise

  @doc """
  Starts the GenServer.

  `state` *must* contain a keyword list to be merged with the following defaults:

  ```elixir
  %{
    portname: "TTY",        #the port name: "COM1", "ttyUSB0", "cu.usbserial-FTYHQD9MA"
    baudrate: "115200",     #either 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200
    bitconfig: "8N1",       #either 8N1, 7E1, 7O1
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
    GenServer.cast(pid, :stop)
  end

  @doc """
  Tests if the native port has compleated all previous commands.

  Returns `:ok`.
  """
  def echo(pid) do
    GenServer.call(pid, :echo)
  end

  @doc """
  Discards all data in the input and output buffers of the serial port.

  Returns `:ok`.
  """
  def discard(pid) do
    GenServer.call(pid, :discard)
  end

  @doc """
  Turns on a coil.

  Returns `:ok` | `:error`.
  """
  def on(pid, slave, address) do
    GenServer.call(pid, {:wcoil, slave, address, 1})
  end

  @doc """
  Turns off a coil.

  Returns `:ok` | `:error`.
  """
  def off(pid, slave, address) do
    GenServer.call(pid, {:wcoil, slave, address, 0})
  end

  @doc """
  Turns on or off a coil depending on provided value.

  Returns `:ok` | `:error`.
  """
  def wcoil(pid, slave, address, value) do
    GenServer.call(pid, {:wcoil, slave, address, value})
  end

  @doc """
  Gets the value (0 | 1) of a coil.

  Returns `{:ok, value}` | `:error`.
  """
  def rcoil(pid, slave, address) do
    GenServer.call(pid, {:rcoil, slave, address})
  end

  @doc """
  Turns on or off a coil depending on provided value list.

  Returns `:ok` | `:error`.
  """
  def wcoils(pid, slave, address, values) do
    GenServer.call(pid, {:wcoils, slave, address, values})
  end

  @doc """
  Gets the values (0 | 1) for the required coils.

  Returns a list of values for the number of requested coils.
  """
  def rcoils(pid, slave, address, count) do
    GenServer.call(pid, {:rcoils, slave, address, count})
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
    config = Enum.into(state, %{portname: "TTY", baudrate: "115200", bitconfig: "8N1", bufsize: 255})
    exec = :code.priv_dir(:baud) ++ '/native/baud'
    args = ["o#{config.portname},#{config.baudrate},#{config.bitconfig}b#{config.bufsize}"]
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

  def handle_call(:discard, _from, port) do
    true = Port.command(port, "fd")
    {:reply, :ok, port}
  end

  def handle_call({:wcoil, slave, address, value}, _from, port) do
    a0 = band(address, 0xff)
    a1 = band(address >>> 8, 0xff)
    request = <<slave, 05, a1, a0, ff(value), 00>>
    true = Port.command(port, "m")
    true = Port.command(port, request)
    receive do
      {^port, {:data, "me"}} -> {:reply, :error, port}
      {^port, {:data, ^request}} -> {:reply, :ok, port}
    after
      @to -> {:stop, {:wcoil, :timeout}, port}
    end
  end

  def handle_call({:rcoil, slave, address}, _from, port) do
    a0 = band(address, 0xff)
    a1 = band(address >>> 8, 0xff)
    request = <<slave, 01, a1, a0, 00, 01>>
    true = Port.command(port, "m")
    true = Port.command(port, request)
    receive do
      {^port, {:data, "me"}} -> {:reply, :error, port}
      {^port, {:data, <<^slave, 01, 01, value>>}} -> {:reply, {:ok, value}, port}
    after
      @to -> {:stop, {:rcoil, :timeout}, port}
    end
  end

  def handle_call({:wcoils, slave, address, values}, _from, port) do
    a0 = band(address, 0xff)
    a1 = band(address >>> 8, 0xff)
    count = Enum.count(values)
    c0 = band(count, 0xff)
    c1 = band(count >>> 8, 0xff)
    bytes = div(count - 1, 8) + 1
    request = <<slave, 15, a1, a0, c1, c0, bytes, ffs(values, bytes*8)::bitstring >>
    response = <<slave, 15, a1, a0, c1, c0>>
    true = Port.command(port, "m")
    true = Port.command(port, request)
    receive do
      {^port, {:data, "me"}} -> {:reply, :error, port}
      {^port, {:data, ^response}} -> {:reply, :ok, port}
    after
      @to -> {:stop, {:wcoils, :timeout}, port}
    end
  end

  def handle_call({:rcoils, slave, address, count}, _from, port) do
    a0 = band(address, 0xff)
    a1 = band(address >>> 8, 0xff)
    c0 = band(count, 0xff)
    c1 = band(count >>> 8, 0xff)
    bytes = div(count - 1, 8) + 1
    request = <<slave, 01, a1, a0, c1, c0>>
    true = Port.command(port, "m")
    true = Port.command(port, request)
    receive do
      {^port, {:data, "me"}} -> {:reply, :error, port}
      {^port, {:data, <<^slave, 01, ^bytes, value>>}} -> {:reply, {:ok, f2l(count, value)}, port}
    after
      @to -> {:stop, {:rcoil, :timeout}, port}
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

  def handle_cast(:stop, port) do
    {:stop, :normal, port}
  end

  ##########################################
  # Internal Implementation
  ##########################################

  defp ff(value) do
    case value do
      0 -> 0x00
      _ -> 0xff
    end
  end

  defp f2l(count, value) do
    list = for << <<bit::1>> <- << value >> >>, do: bit
    Enum.take(:lists.reverse(list), count)
  end

  defp f(value) do
    case value do
      0 -> << <<0::1>>::bitstring >>
      _ -> << <<1::1>>::bitstring >>
    end
  end

  defp ffs(_, 0) do
    << <<0::0>>::bitstring >>
  end

  defp ffs([], count) do
    << ffs([], count - 1)::bitstring, <<0::1>>::bitstring >>
  end

  defp ffs([value | tail], count) do
    << ffs(tail, count - 1)::bitstring, f(value)::bitstring >>
  end

end
