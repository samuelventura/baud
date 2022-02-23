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

  def read(nid, count, timeout) do
    case {count, timeout} do
      {0, -1} ->
        scan_s(nid) |> trans()

      _ ->
        dl = millis() + timeout
        scan_m(nid, count, dl) |> trans()
    end
  end

  def write(nid, packet) do
    Sniff.read(nid)
    Sniff.write(nid, packet) |> trans()
  end

  def close(nid) do
    Sniff.close(nid) |> trans()
  end

  defp scan_m(nid, count, dl, buf \\ <<>>) do
    case Sniff.read(nid) do
      {:ok, ""} ->
        case millis() >= dl do
          true ->
            {:error, {:timeout, buf}}

          false ->
            :timer.sleep(1)
            scan_m(nid, count, dl, buf)
        end

      {:ok, data} ->
        buf = buf <> data

        case byte_size(buf) >= count do
          true -> {:ok, buf}
          false -> scan_m(nid, count, dl, buf)
        end

      other ->
        other
    end
  end

  defp scan_s(nid) do
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
          {:halt, {{:error, {reason, buf}}}}
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
