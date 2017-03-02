defmodule Baud do
  @moduledoc """
    RTU module.

    ```elixir

    ```
  """

  @doc """
  Starts the RTU server.

  `params` *must* contain a keyword list to be merged with the following defaults:
  ```elixir
  [
    device: nil,         #serial port name: "COM1", "ttyUSB0", "cu.usbserial-FTYHQD9MA"
    speed: 115200,       #either 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200
                         #win32 adds 14400, 128000, 256000
    config: "8N1",       #either "8N1", "7E1", "7O1"
  ]
  ```
  `opts` is optional and is passed verbatim to GenServer.

  Returns `{:ok, pid}`.
  ## Example
    ```
    Rtu.start_link([device: "COM8"])
    ```
  """
  def start_link(params, opts \\ []) do
      Agent.start_link(fn -> init(params) end, opts)
  end

  @sleep 1
  @to 400

  @doc """
    Stops the serial server.

    Returns `:ok`.
  """
  def stop(pid) do
    Agent.stop(pid)
  end

  def exec(pid, cmd, timeout \\ @to) do
    pack = Modbus.Request.pack(cmd)
    res = Modbus.Rtu.wrap(pack)
    count = Modbus.Response.length(cmd)
    Agent.get(pid, fn nid ->
      now = :erlang.monotonic_time :milli_seconds
      case read_n(nid, [], 0, count, dl) do
        {:ok, data} ->
          resp = Modbus.Rtu.unwrap(data)
          values = Modbus.Response.parse(cmd, resp)
          case values do
            nil -> :ok
            _ -> {:ok, values}
          end
        {:to, data} -> {:to, data}
        {:er, data} -> {:er, data}
      end
    end, 2*timeout)
  end

  defp init(params) do
    device = Keyword.fetch!(params, :device)
    speed = Keyword.get(params, :speed, 115200)
    config = Keyword.get(params, :config, "8N1")
    {:ok, nid} = Baud.Nif.open device, speed, config
    nid
  end

  defp read_n(nid, iol, size, count, dl) do
    case size >= count do
      true -> split_c iol, count
      false ->
        {:ok, data} = Baud.Nif.read nid
        case data do
          <<>> ->
            :timer.sleep @sleep
            now = :erlang.monotonic_time :milli_seconds
            case now > dl do
              true -> {:to, all(iol), <<>>}
              false -> read_n(nid, iol, size, count, dl)
            end
          _ -> read_n(nid, [data | iol], size + byte_size(data),
            count, dl)
        end
    end
  end

end
