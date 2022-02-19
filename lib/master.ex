defmodule Modbus.Rtu.Master do
  @moduledoc """
  RTU Master server.

  ```elixir
  # run with: mix slave
  alias Modbus.Rtu.Slave
  alias Modbus.Rtu.Master

  tty0 =
    case :os.type() do
      {:unix, :darwin} -> "/dev/tty.usbserial-FTYHQD9MA"
      {:unix, :linux} -> "/dev/ttyUSB0"
      {:win32, :nt} -> "COM5"
    end

  tty1 =
    case :os.type() do
      {:unix, :darwin} -> "/dev/tty.usbserial-FTYHQD9MB"
      {:unix, :linux} -> "/dev/ttyUSB1"
      {:win32, :nt} -> "COM6"
    end

  # start your slave with a shared model
  model = %{
    0x50 => %{
      {:c, 0x5152} => 0,
      {:i, 0x5354} => 0,
      {:i, 0x5355} => 1,
      {:hr, 0x5657} => 0x6162,
      {:ir, 0x5859} => 0x6364,
      {:ir, 0x585A} => 0x6566
    }
  }

  {:ok, _} = Slave.start_link(model: model, device: tty0)
  {:ok, mpid} = Master.start_link(device: tty1)

  # read input
  {:ok, [0, 1]} = Master.exec(mpid, {:ri, 0x50, 0x5354, 2})
  # read input registers
  {:ok, [0x6364, 0x6566]} = Master.exec(mpid, {:rir, 0x50, 0x5859, 2})

  # toggle coil and read it back
  :ok = Master.exec(mpid, {:fc, 0x50, 0x5152, 0})
  {:ok, [0]} = Master.exec(mpid, {:rc, 0x50, 0x5152, 1})
  :ok = Master.exec(mpid, {:fc, 0x50, 0x5152, 1})
  {:ok, [1]} = Master.exec(mpid, {:rc, 0x50, 0x5152, 1})

  # increment holding register and read it back
  {:ok, [0x6162]} = Master.exec(mpid, {:rhr, 0x50, 0x5657, 1})
  :ok = Master.exec(mpid, {:phr, 0x50, 0x5657, 0x6163})
  {:ok, [0x6163]} = Master.exec(mpid, {:rhr, 0x50, 0x5657, 1})
  ```

  Uses:

  - https://github.com/samuelventura/sniff
  - https://github.com/samuelventura/modbus
  """
  alias Modbus.Rtu
  @sleep 10
  @to 400

  @doc """
  Opens the connection.

  `params` *must* contain a keyword list to be merged with the following defaults:
  ```elixir
  [
    device: nil,        #serial port name: "COM1", "/dev/ttyUSB0", "/dev/tty.usbserial-FTYHQD9MA"
    speed: 9600,        #either 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200
                        #win32 adds 14400, 128000, 256000
    config: "8N1",      #either "8N1", "7E1", "7O1"
  ]
  ```

  Returns `{:ok, pid}` | `{:error, reason}`.
  ## Example
    ```
    Modbus.Rtu.Master.start_link(device: "/dev/ttyUSB0")
    ```
  """
  def start_link(opts) do
    device = Keyword.fetch!(opts, :device)
    speed = Keyword.get(opts, :speed, 9600)
    config = Keyword.get(opts, :config, "8N1")
    sleep = Keyword.get(opts, :sleep, @sleep)
    init = [device: device, speed: speed, config: config, sleep: sleep]
    GenServer.start_link(__MODULE__.Server, init)
  end

  @doc """
    Closes the connection.

    Returns `:ok`.
  """
  def stop(pid) do
    GenServer.stop(pid)
  end

  @doc """
  Executes a Modbus command.

  `cmd` is one of:
  - `{:rc, slave, address, count}` read `count` coils.
  - `{:ri, slave, address, count}` read `count` inputs.
  - `{:rhr, slave, address, count}` read `count` holding registers.
  - `{:rir, slave, address, count}` read `count` input registers.
  - `{:fc, slave, address, value}` force single coil.
  - `{:phr, slave, address, value}` preset single holding register.
  - `{:fc, slave, address, values}` force multiple coils.
  - `{:phr, slave, address, values}` preset multiple holding registers.
  Returns `:ok` | `{:ok, [values]}` | `{:error, reason}`.
  """
  def exec(pid, cmd, timeout \\ @to) when is_tuple(cmd) and is_integer(timeout) do
    GenServer.call(pid, {:exec, cmd, timeout})
  end

  defmodule Server do
    @moduledoc false
    use GenServer

    def init(init) do
      case Baud.start_link(init) do
        {:ok, bid} ->
          {:ok, bid}

        {:error, reason} ->
          {:stop, reason}
      end
    end

    def handle_call({:exec, cmd, timeout}, _from, baud) do
      resp = exec(baud, cmd, timeout)
      {:reply, resp, baud}
    end

    defp exec(baud, cmd, timeout) do
      case request(cmd) do
        {:ok, request, length} ->
          # clear input buffer
          Baud.readall(baud)

          case Baud.write(baud, request) do
            :ok ->
              case Baud.readn(baud, length, timeout) do
                {:ok, response} ->
                  values = Rtu.parse_res(cmd, response)

                  case values do
                    nil -> :ok
                    _ -> {:ok, values}
                  end

                {:to, partial} ->
                  {:error, {:to, partial}}

                error ->
                  error
              end

            error ->
              error
          end

        error ->
          error
      end
    end

    defp request(cmd) do
      try do
        request = Rtu.pack_req(cmd)
        length = Rtu.res_len(cmd)
        {:ok, request, length}
      rescue
        _ ->
          {:error, {:invalid, cmd}}
      end
    end
  end
end
