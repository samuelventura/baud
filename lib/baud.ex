defmodule Baud do
  @sleep 10
  @to 400

  @moduledoc """
  Serial port module.

  ```elixir
  #this echo sample requires a loopback plug
  tty = case :os.type() do
    {:unix, :darwin} -> "/dev/tty.usbserial-FTYHQD9MA"
    {:unix, :linux} -> "/dev/ttyUSB0"
    {:win32, :nt} -> "COM5"
  end

  {:ok, pid} = Baud.start_link(device: tty)

  Baud.write pid, "01234\\n56789\\n98765\\n43210"
  {:ok, "01234\\n"} = Baud.readln pid
  {:ok, "56789\\n"} = Baud.readln pid
  {:ok, "98765\\n"} = Baud.readln pid
  {:to, "43210"} = Baud.readln pid

  Baud.write pid, "01234\r56789\r98765\r43210"
  {:ok, "01234\r"} = Baud.readcr pid
  {:ok, "56789\r"} = Baud.readcr pid
  {:ok, "98765\r"} = Baud.readcr pid
  {:to, "43210"} = Baud.readcr pid

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

  Uses:

  - https://github.com/samuelventura/sniff
  """

  @doc """
  Starts the serial server.

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
    Baud.start_link(device: "/dev/ttyUSB0")
    ```
  """
  def start_link(opts) do
    device = Keyword.fetch!(opts, :device)
    speed = Keyword.get(opts, :speed, 9600)
    config = Keyword.get(opts, :config, "8N1")
    sleep = Keyword.get(opts, :sleep, @sleep)
    init = %{device: device, speed: speed, config: config, sleep: sleep}
    GenServer.start_link(__MODULE__.Server, init)
  end

  @doc """
    Stops the serial server.

    Returns `:ok`.
  """
  def stop(pid) do
    GenServer.stop(pid)
  end

  @doc """
  Writes `data` to the serial port.

  Returns `:ok` | `{:error, reason}`.
  """
  def write(pid, data) do
    GenServer.call(pid, {:write, data})
  end

  @doc """
  Reads all available data.

  Returns `{:ok, data}` | `{:error, reason}`.
  """
  def readall(pid) do
    GenServer.call(pid, {:readall})
  end

  @doc """
  Reads `count` bytes.

  Returns `{:ok, data} | {:to, partial}` | `{:error, reason}`.
  """
  def readn(pid, count, timeout \\ @to) when count >= 0 do
    GenServer.call(pid, {:readn, count, timeout})
  end

  @doc """
  Reads until 'nl' (0x0A) is received.

  Returns `{:ok, line} | {:to, partial}` | `{:error, reason}`.
  """
  def readln(pid, timeout \\ @to) do
    GenServer.call(pid, {:readch, 0x0A, timeout})
  end

  @doc """
  Reads until 'cr' (0x0D) is received.

  Returns `{:ok, line} | {:to, partial}` | `{:error, reason}`.
  """
  def readcr(pid, timeout \\ @to) do
    GenServer.call(pid, {:readch, 0x0D, timeout})
  end

  @doc """
  Reads until 'ch' is received.

  Returns `{:ok, data} | {:to, partial}` | `{:error, reason}`.
  """
  def readch(pid, ch, timeout \\ @to) when ch >= 0 and ch <= 256 do
    GenServer.call(pid, {:readch, ch, timeout})
  end

  defmodule Server do
    use GenServer

    def init(init) do
      %{device: device, speed: speed, config: config, sleep: sleep} = init

      case Sniff.open(device, speed, config) do
        {:ok, nid} -> {:ok, {nid, <<>>, sleep}}
        {:er, reason} -> {:stop, reason}
      end
    end

    def handle_call({:write, data}, _from, {nid, _, _} = state) do
      case Sniff.write(nid, data) do
        :ok -> {:reply, :ok, state}
        {:er, reason} -> {:reply, {:error, reason}, state}
      end
    end

    def handle_call({:readall}, _from, {nid, buf, sleep}) do
      case Sniff.read(nid) do
        {:ok, data} ->
          {:reply, {:ok, buf <> data}, {nid, <<>>, sleep}}

        {:er, reason} ->
          {:reply, {:error, {reason, buf}}, {nid, <<>>, sleep}}
      end
    end

    def handle_call({:readch, ch, timeout}, _from, {nid, buf, sleep}) do
      result = readch(nid, ch, buf, timeout, sleep)

      case result do
        {:ok, head, tail} -> {:reply, {:ok, head}, {nid, tail, sleep}}
        {:to, buf} -> {:reply, {:to, buf}, {nid, <<>>, sleep}}
        {:er, reason} -> {:reply, {:error, reason}, {nid, <<>>, sleep}}
      end
    end

    def handle_call({:readn, count, timeout}, _from, {nid, buf, sleep}) do
      result = readn(nid, count, buf, timeout, sleep)

      case result do
        {:ok, head, tail} -> {:reply, {:ok, head}, {nid, tail, sleep}}
        {:to, buf} -> {:reply, {:to, buf}, {nid, <<>>, sleep}}
        {:er, reason} -> {:reply, {:error, reason}, {nid, <<>>, sleep}}
      end
    end

    defp readch(nid, ch, buf, timeout, sleep) do
      dl = millis() + timeout

      Stream.iterate(0, &(&1 + 1))
      |> Enum.reduce_while({<<>>, buf}, fn i, {buf1, buf2} ->
        case index(buf2, ch) do
          -1 ->
            # i > 0  for one undelayed read at least
            if i > 0, do: :timer.sleep(sleep)

            case i > 0 && millis() >= dl do
              true ->
                {:halt, {:to, buf1 <> buf2}}

              false ->
                case Sniff.read(nid) do
                  {:ok, data} ->
                    {:cont, {buf1 <> buf2, data}}

                  {:er, reason} ->
                    {:halt, {:er, {reason, buf1 <> buf2}}}
                end
            end

          i ->
            {head, tail} = split(buf2, i + 1)
            {:halt, {:ok, buf1 <> head, tail}}
        end
      end)
    end

    defp readn(nid, count, buf, timeout, sleep) do
      dl = millis() + timeout

      Stream.iterate(0, &(&1 + 1))
      |> Enum.reduce_while({<<>>, buf}, fn i, {buf1, buf2} ->
        case byte_size(buf1) + byte_size(buf2) >= count do
          false ->
            # i > 0  for one undelayed read at least
            if i > 0, do: :timer.sleep(sleep)

            case i > 0 && millis() >= dl do
              true ->
                {:halt, {:to, buf1 <> buf2}}

              false ->
                case Sniff.read(nid) do
                  {:ok, data} ->
                    {:cont, {buf1 <> buf2, data}}

                  {:er, reason} ->
                    {:halt, {:er, {reason, buf1 <> buf2}}}
                end
            end

          true ->
            {head, tail} = split(buf2, count - byte_size(buf1))
            {:halt, {:ok, buf1 <> head, tail}}
        end
      end)
    end

    defp index(<<>>, _), do: -1

    defp index(bin, ch) do
      case :binary.match(bin, <<ch>>) do
        :nomatch -> -1
        {index, _} -> index
      end
    end

    defp split(bin, index) do
      head = :binary.part(bin, {0, index})
      tail = :binary.part(bin, {index, byte_size(bin) - index})
      {head, tail}
    end

    defp millis() do
      System.monotonic_time(:millisecond)
    end
  end
end
