defmodule Baud.Transport do
  @behaviour Modbus.Transport
  @moduledoc false

  # silent period for slave reads is speed dependent
  # 9600 requires silent ~ 10
  # 115200 works with silent = 1
  # no calculation effort will solve the unreliability of the PC timing
  # will leave a working value for the minimal typical speed which is 9600
  @silent 10

  def open(opts) do
    device = Keyword.fetch!(opts, :device)
    speed = Keyword.get(opts, :speed, 9600)
    config = Keyword.get(opts, :config, "8N1")
    Sniff.open(device, speed, config) |> trans()
  end

  def readp(nid) do
    scanp(nid) |> trans()
  end

  def readn(nid, count, timeout) do
    dl = millis() + timeout
    scann(nid, count, dl) |> trans()
  end

  def write(nid, packet) do
    Sniff.read(nid)
    Sniff.write(nid, packet) |> trans()
  end

  def close(nid) do
    Sniff.close(nid) |> trans()
  end

  defp scann(nid, count, dl) do
    Stream.iterate(0, &(&1 + 1))
    |> Enum.reduce_while(<<>>, fn i, buf ->
      if i > 0, do: :timer.sleep(1)

      case Sniff.read(nid) do
        {:ok, data} ->
          buf = buf <> data

          case byte_size(buf) >= count do
            true ->
              {:halt, {:ok, buf}}

            false ->
              case millis() > dl do
                true -> {:halt, {:error, {:timeout, buf}}}
                false -> {:cont, buf}
              end
          end

        {:er, reason} ->
          {:halt, {:error, {reason, buf}}}
      end
    end)
  end

  defp scanp(nid) do
    Stream.iterate(0, &(&1 + 1))
    |> Enum.reduce_while({0, <<>>}, fn i, {count, buf} ->
      if i > 0, do: :timer.sleep(1)

      case Sniff.read(nid) do
        {:ok, data} ->
          case {buf, data} do
            {<<>>, <<>>} ->
              {:cont, {0, <<>>}}

            {<<>>, _} ->
              {:cont, {0, data}}

            {_, <<>>} ->
              cond do
                count > @silent -> {:halt, {:ok, buf}}
                true -> {:cont, {count + 1, buf}}
              end

            {_, _} ->
              {:cont, {count + 1, buf <> data}}
          end

        {:er, reason} ->
          {:halt, {:error, {reason, buf}}}
      end
    end)
  end

  defp trans(res) do
    case res do
      :ok -> :ok
      {:ok, value} -> {:ok, value}
      {:er, reason} -> {:error, reason}
      {:error, reason} -> {:error, reason}
    end
  end

  defp millis() do
    System.monotonic_time(:millisecond)
  end
end
