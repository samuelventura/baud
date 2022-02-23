defmodule Baud.Slave do
  @moduledoc false
  alias Modbus.Shared
  alias Modbus.Transport
  alias Modbus.Protocol

  def start_link(opts) do
    model = Keyword.fetch!(opts, :model)
    proto = Keyword.get(opts, :proto, :rtu)
    transm = Baud.Transport
    protom = Protocol.module(proto)
    init = %{trans: transm, proto: protom, model: model, opts: opts}
    GenServer.start_link(__MODULE__.Server, init)
  end

  def stop(pid) do
    # sniff automatic close should
    # close the client process
    GenServer.stop(pid)
  end

  defmodule Server do
    @moduledoc false
    use GenServer

    def init(init) do
      %{trans: transm, proto: proto, model: model, opts: opts} = init
      {:ok, shared} = Shared.start_link(model)

      case Transport.open(transm, opts) do
        {:ok, transi} ->
          trans = {transm, transi}
          client = spawn_link(fn -> Modbus.Slave.client(shared, trans, proto) end)
          state = %{client: client, shared: shared}
          {:ok, state}

        {:error, reason} ->
          {:stop, reason}
      end
    end

    def terminate(reason, %{shared: shared}) do
      Agent.stop(shared, reason)
    end
  end
end
