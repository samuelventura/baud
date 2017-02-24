defmodule Baud.Sock do
  import Supervisor.Spec
  @moduledoc """
  Server module to export individual serial ports thru a socket.

  A single remote socket connection is supported. Each new socket connection
  closes and replaces the previous one. Native port is open until a connection
  is made and will be closed when the connection closes. Serial port should
  be free while there is no connection.
  """

  ##########################################
  # Public API
  ##########################################

  @doc """
  Starts the listening socket server.

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
    Agent.start_link(fn -> init(params) end, opts)
  end

  def stop(pid) do
    Agent.stop(pid)
  end

  def id(pid) do
    Agent.get(pid, fn %{ip: ip, port: port, name: name} -> {:ok, %{ip: ip, port: port, name: name}} end)
  end

  def state(pid) do
    Agent.get(pid, fn state -> state end)
  end

  defp init(params) do
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
    {:ok, listener} = :gen_tcp.listen(port, [:binary, ip: ip, packet: packtype(mode), active: false])
    {:ok, {ip, port}} = :inet.sockname(listener)
    spec = worker(__MODULE__, [], restart: :temporary, function: :start_child)
    {:ok, sup} = Supervisor.start_link([spec], strategy: :simple_one_for_one)
    accept = spawn_link(fn -> accept(listener, args, sup, nil) end)
    %{ip: ip, port: port, name: name, sup: sup, accept: accept, listener: listener}
  end

  defp accept(listener, args, sup, handler) do
    {:ok, socket} = :gen_tcp.accept(listener)
    if is_pid(handler) do
      Process.exit(handler, :kill)
      #:timer.sleep(100)
    end
    {:ok, handler} = Supervisor.start_child(sup, [socket, args])
    :ok = :gen_tcp.controlling_process(socket, handler)
    :go = send handler, :go
    accept(listener, args, sup, handler)
  end

  def start_child(socket, args) do
    {:ok, spawn_link(fn ->
      receive do
        :go ->
          exec = :code.priv_dir(:baud) ++ '/native/baud'
          port = Port.open({:spawn_executable, exec},
            [:binary, :exit_status, packet: 2, args: args])
          :ok = :inet.setopts(socket, active: :once)
          loop(socket, port)
      end
    end)}
  end

  defp loop(socket, port) do
    :ok = receive do
      {:tcp, ^socket, data} ->
        true = Port.command(port, data)
        :ok = :inet.setopts(socket, active: :once)
      {^port, {:data, data}} ->
        :ok = :gen_tcp.send(socket, data)
      #port exit notification
      unexpected -> {:unexpected, unexpected}
    end
    loop(socket, port)
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
