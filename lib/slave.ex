defmodule Modbus.Rtu.Slave do
  use GenServer
  @moduledoc false
  alias Modbus.Model.Shared
  alias Modbus.Rtu
  @silent 10

  def start_link(opts) do
    device = Keyword.fetch!(opts, :device)
    speed = Keyword.get(opts, :speed, 9600)
    config = Keyword.get(opts, :config, "8N1")
    sleep = Keyword.get(opts, :sleep, nil)
    model = Keyword.fetch!(opts, :model)

    opts =
      case sleep do
        nil -> [device: device, speed: speed, config: config]
        _ -> [device: device, speed: speed, config: config, sleep: sleep]
      end

    GenServer.start_link(__MODULE__, {opts, model})
  end

  def init({opts, model}) do
    {:ok, shared} = Shared.start_link(model)

    case Baud.start_link(opts) do
      {:ok, pid} ->
        spawn_link(fn -> client(pid, shared) end)

        {:ok,
         %{
           shared: shared,
           baud: pid
         }}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  def terminate(reason, %{shared: shared}) do
    Agent.stop(shared, reason)
  end

  def stop(pid) do
    # sniff automatic close should
    # close the client process
    GenServer.stop(pid)
  end

  defp client(pid, shared) do
    case read(pid, @silent) do
      {:ok, data} ->
        cmd = Rtu.parse_req(data)
        result = Shared.apply(shared, cmd)

        case result do
          :ok ->
            resp = Rtu.pack_res(cmd, nil)
            Baud.write(pid, resp)

          {:ok, values} ->
            resp = Rtu.pack_res(cmd, values)
            Baud.write(pid, resp)

          _ ->
            :ignore
        end

        client(pid, shared)

      {:error, reason} ->
        Process.exit(self(), reason)
    end
  end

  defp read(pid, silent) do
    Stream.iterate(0, &(&1 + 1))
    |> Enum.reduce_while({0, <<>>}, fn i, {count, buf} ->
      if i > 0, do: :timer.sleep(1)

      case Baud.readall(pid) do
        {:ok, data} ->
          case {buf, data} do
            {<<>>, <<>>} ->
              {:cont, {0, <<>>}}

            {<<>>, _} ->
              {:cont, {count + 1, data}}

            {_, <<>>} ->
              cond do
                count > silent -> {:halt, {:ok, buf}}
                true -> {:cont, {count + 1, buf}}
              end

            {_, _} ->
              {:cont, {count + 1, buf <> data}}
          end

        {:error, reason} ->
          {:halt, {{:error, {reason, buf}}}}
      end
    end)
  end
end
