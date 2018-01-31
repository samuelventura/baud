defmodule Baud do
  @moduledoc """
    Serial port module.

    ```elixir
    tty = case :os.type() do
      {:unix, :darwin} -> "cu.usbserial-FTYHQD9MA"
      {:unix, :linux} -> "ttyUSB0"
      {:win32, :nt} -> "COM5"
    end

    #Try this with a loopback
    {:ok, pid} = Baud.start_link([device: tty])

    Baud.write pid, "01234\\n56789\\n98765\\n43210"
    {:ok, "01234\\n"} = Baud.readln pid
    {:ok, "56789\\n"} = Baud.readln pid
    {:ok, "98765\\n"} = Baud.readln pid
    {:to, "43210"} = Baud.readln pid

    Baud.write pid, "01234\\r56789\\r98765\\r43210"
    {:ok, "01234\\r"} = Baud.readch pid, 0x0d
    {:ok, "56789\\r"} = Baud.readch pid, 0x0d
    {:ok, "98765\\r"} = Baud.readch pid, 0x0d
    {:to, "43210"} = Baud.readch pid, 0x0d

    Baud.write pid, "01234\\n56789\\n98765\\n43210"
    {:ok, "01234\\n"} = Baud.readn pid, 6
    {:ok, "56789\\n"} = Baud.readn pid, 6
    {:ok, "98765\\n"} = Baud.readn pid, 6
    {:to, "43210"} = Baud.readn pid, 6

    Baud.write pid, "01234\\n"
    Baud.write pid, "56789\\n"
    Baud.write pid, "98765\\n"
    Baud.write pid, "43210"
    :timer.sleep 100
    {:ok, "01234\\n56789\\n98765\\n43210"} = Baud.readall pid
    ```
  """

  @doc """
  Starts the serial server.

  `params` *must* contain a keyword list to be merged with the following defaults:
  ```elixir
  [
    device: nil,         #serial port name: "COM1", "ttyUSB0", "cu.usbserial-FTYHQD9MA"
    speed: 9600,       #either 1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200
                         #win32 adds 14400, 128000, 256000
    config: "8N1",       #either "8N1", "7E1", "7O1"
  ]
  ```
  `opts` is optional and is passed verbatim to GenServer.

  Returns `{:ok, pid}`.
  ## Example
    ```
    Baud.start_link([device: "COM8"])
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
    Agent.get(pid, fn {nid, _} ->
      :ok = Sniff.close nid
    end, @to)
    Agent.stop(pid)
  end

  @doc """
  Writes `data` to the serial port.

  Returns `:ok`.
  """
  def write(pid, data, timeout \\ @to) do
    Agent.get(pid, fn {nid, _} ->
      :ok = Sniff.write nid, data
    end, timeout)
  end

  @doc """
  Reads all available data.

  Returns `{:ok, data}`.
  """
  def readall(pid, timeout \\ @to) do
    Agent.get_and_update(pid, fn {nid, buf} ->
      {:ok, data} = Sniff.read nid
      all = buf <> data
      {{:ok, all}, {nid, <<>>}}
    end, timeout)
  end

  @doc """
  Reads `count` bytes.

  Returns `{:ok, data} | {:to, partial}`.
  """
  def readn(pid, count, timeout \\ @to) do
    Agent.get_and_update(pid, fn {nid, buf} ->
      now = now()
      size = byte_size(buf)
      dl = now + timeout
      {res, head, tail} = read_n(nid, [buf], size, count, dl)
      {{res, head}, {nid, tail}}
    end, 2*timeout)
  end

  @doc """
  Reads until 'nl' is received.

  Returns `{:ok, line} | {:to, partial}`.
  """
  def readln(pid, timeout \\ @to) do
    Agent.get_and_update(pid, fn {nid, buf} ->
      now = now()
      ch = 10;
      index = index(buf, ch)
      size = byte_size(buf)
      dl =  now + timeout
      {res, head, tail} = read_ch(nid, [buf], index, size, ch, dl)
      {{res, head}, {nid, tail}}
    end, 2*timeout)
  end

  @doc """
  Reads until 'ch' is received.

  Returns `{:ok, data} | {:to, partial}`.
  """
  def readch(pid, ch, timeout \\ @to) do
    Agent.get_and_update(pid, fn {nid, buf} ->
      now = now()
      index = index(buf, ch)
      size = byte_size(buf)
      dl =  now + timeout
      {res, head, tail} = read_ch(nid, [buf], index, size, ch, dl)
      {{res, head}, {nid, tail}}
    end, 2*timeout)
  end

  defp init(params) do
    device = Keyword.fetch!(params, :device)
    speed = Keyword.get(params, :speed, 9600)
    config = Keyword.get(params, :config, "8N1")
    {:ok, nid} = Sniff.open device, speed, config
    {nid, <<>>}
  end

  defp read_ch(nid, iol, index, size, ch, dl) do
    case index >= 0 do
      true -> split_i iol, index
      false ->
        {:ok, data} = Sniff.read nid
        case data do
          <<>> ->
            :timer.sleep @sleep
            now = now()
            case now > dl do
              true -> {:to, all(iol), <<>>}
              false -> read_ch(nid, iol, -1, size, ch, dl)
            end
          _ ->
            case index(data, ch) do
              -1 -> read_ch(nid, [data | iol], -1,
                size + byte_size(data), ch, dl)
              index -> read_ch(nid, [data | iol], size + index,
                size + byte_size(data), ch, dl)
            end
        end
    end
  end

  defp read_n(nid, iol, size, count, dl) do
    case size >= count do
      true -> split_c iol, count
      false ->
        {:ok, data} = Sniff.read nid
        case data do
          <<>> ->
            :timer.sleep @sleep
            now = now()
            case now > dl do
              true -> {:to, all(iol), <<>>}
              false -> read_n(nid, iol, size, count, dl)
            end
          _ -> read_n(nid, [data | iol], size + byte_size(data),
            count, dl)
        end
    end
  end

  defp now(), do: :os.system_time :milli_seconds
  #defp now(), do: :erlang.monotonic_time :milli_seconds

  defp index(bin, ch) do
    case :binary.match(bin, <<ch>>) do
      :nomatch -> -1
      {index, _} -> index
    end
  end

  defp all(bin) when is_binary(bin) do
    bin
  end
  defp all(list) when is_list(list) do
    reversed = Enum.reverse list
    :erlang.iolist_to_binary(reversed)
  end

  defp split_i(bin, index) when is_binary(bin) do
    head = :binary.part(bin, {0, index + 1})
    tail = :binary.part(bin, {index + 1, byte_size(bin) - index - 1})
    {:ok, head, tail}
  end
  defp split_i(list, index) when is_list(list) do
    reversed = Enum.reverse list
    bin = :erlang.iolist_to_binary(reversed)
    split_i(bin, index)
  end

  defp split_c(bin, count) when is_binary(bin) do
    <<head::bytes-size(count), tail::binary>> = bin
    {:ok, head, tail}
  end
  defp split_c(list, count) when is_list(list) do
    reversed = Enum.reverse list
    bin = :erlang.iolist_to_binary(reversed)
    split_c(bin, count)
  end

end
