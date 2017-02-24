defmodule Baud.Sock do
  @moduledoc """
  Server module to export individual serial ports thru a socket.

  A single remote socket connection is supported. Each new socket connection
  closes and replaces the previous one. Native port is open until a connection
  is made and will be closed when the connection closes. Serial port should
  be free while there is no connection.
  """
  use GenServer

  ##########################################
  # Public API
  ##########################################

  @doc """
  Starts the GenServer.

  `state` is  a keyword list to be merged with the following defaults:

  ```elixir
  %{
    mode: :text,
    ip: {127,0,0,1},
    port: 0,
    baudrate: "115200",
    bitconfig: "8N1",
    bufsize: 255,
    packto: 0,
  }
  ```

  `mode` can be `:text`, `:rtu_master`, `:rtu_slave`, `:rtu_tcpgw` or `:raw`.
  Text mode buffers data from the serial port and forwards complete lines
  terminated in `\\n`. RTU modes buffer data, adds or removes CRC, and
  forwards complete packets. TCP gateway translates bidirectionally from
  Modbus TCP to Modbus RTU. Raw mode forwards data received within the
  packetization timeout.

  `ip` can be any valid IP with `{0,0,0,0}` and `{127,0,0,1}` meaning `any interface` or
  `local loop interface` respectively.

  `port` is the tcp port number where the serial port will be served.

  `portname` is the name of the serial port to be exported.

  `baudrate` can be any of `1200`, `2400`, `4800`, `9600`, `19200`, `38400`, `57600`, `115200`.

  `bitconfig` can be any of `8N1`, `7E1`, `7O1`.

  `packto` is a packetization timeout in milliseconds mainly for the raw mode. Serial ports are slow
  and you will be forwarding lots of partial packets if no packetization strategy is used.
  Packets are `\\n` and `CRC` terminated in text and modbus mode respectively.
  Raw mode can use a timeout for that effect. Modbus and text modes may benefit as well
  on certain scenarios but should work ok without it (zero value).

  `bufsize` is the buffer size. Handling of packets larger that this will crash the native port.

  `opts` is optional and is passed verbatim to GenServer.

  Returns `{:ok, pid}`.

  ## Example

    ```elixir
    Baud.Sock.start_link([portname: "ttyUSB0", port: 5000], [name: Baud.Sock])
    ```

  """
  def start_link(params, opts \\ []) do
    GenServer.start_link(__MODULE__, params, opts)
  end

  @doc """
    Stops the GenServer.

    Returns `:ok`.
  """
  def stop(pid) do
    #don't use :normal or the listener won't be stop
    Process.exit(pid, :stop)
  end

  ##########################################
  # GenServer Implementation
  ##########################################

  def init(params) do
    self = self()
    portname = Keyword.fetch!(params, :portname)
    baudrate = Keyword.get(params, :baudrate, "115200")
    bitconfig = Keyword.get(params, :bitconfig, "8N1")
    bufsize = Keyword.get(params, :bufsize, 255)
    packto = Keyword.get(params, :packto, 0)
    mode = Keyword.get(params, :mode, :text)
    name = Keyword.get(params, :name, "")
    ip = Keyword.get(params, :ip, {127,0,0,1})
    port = Keyword.get(params, :port, 0)
    flags = flags(mode)
    args = ["o#{portname},#{baudrate},#{bitconfig}b#{bufsize}i#{packto}#{flags}", name]
    {:ok, listener} = :gen_tcp.listen(port, [:binary, ip: ip, packet: packtype(mode), active: false, reuseaddr: true])
    {:ok, {ip, port}} = :inet.sockname(listener)
    spawn_link(fn -> accept(listener, self) end)
    {:ok, %{port: nil, socket: nil, args: args, id: {ip, port}}}
  end

  def terminate(_reason, _state) do
    #:io.format "terminate ~p ~p ~p ~n", [__MODULE__, reason, state]
  end

  def handle_call({:accept, socket}, _from, state) do
    state = close(state)
    exec = :code.priv_dir(:baud) ++ '/native/baud'
    port = Port.open({:spawn_executable, exec},
      [:binary, :exit_status, packet: 2, args: state.args])
    :inet.setopts(socket, [active: :once])
    {:reply, :ok, %{state | socket: socket, port: port}}
  end

  def handle_info({port, {:data, packet}}, state) do
    if port == state.port do
      :ok = :gen_tcp.send(state.socket, packet)
    end
    {:noreply, state}
  end

  def handle_info({port, {:exit_status, _exit_status}}, state) do
    #:io.format "Port closed ~p ~n", [port]
    if port == state.port do
      state = %{state | port: nil}
      {:noreply, close(state)}
    else
      {:noreply, state}
    end
  end

  def handle_info({:tcp, socket, packet}, state) do
    if socket == state.socket do
      true = Port.command(state.port, packet)
      :inet.setopts(socket, [active: :once])
    end
    {:noreply, state}
  end

  def handle_info({:tcp_closed, socket}, state) do
    #:io.format "Socket closed ~p ~n", [socket]
    if socket == state.socket do
      state = %{state | socket: nil}
      {:noreply, close(state)}
    else
      {:noreply, state}
    end
  end

  ##########################################
  # Socket Server Implementation
  ##########################################

  defp accept(listener, pid) do
    {:ok, socket} = :gen_tcp.accept(listener)
    :ok = :gen_tcp.controlling_process(socket, pid)
    :ok = GenServer.call(pid, {:accept, socket})
    accept(listener, pid)
  end

  ##########################################
  # Internal Implementation
  ##########################################

  defp close(state) do
    if nil != state.socket do
      :ok = :gen_tcp.close(state.socket)
    end
    if nil != state.port do
      true = Port.close(state.port)
    end
    %{state | socket: nil, port: nil}
  end

  defp packtype(mode) do
    case mode do
        :raw -> :raw
        :text -> :line
        :rtu_tcpgw -> :raw
        :rtu_master -> :raw
        :rtu_slave -> :raw
    end
  end

  defp flags(mode) do
    case mode do
        :raw -> "lr"
        :text -> "lt"
        :rtu_tcpgw -> "lg"
        :rtu_master -> "lm"
        :rtu_slave -> "ls"
    end
  end
end
