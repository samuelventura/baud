defmodule Baud.NifErrorTest do
  use ExUnit.Case
  alias Baud.TestHelper

  test "error test" do
    tty0 = TestHelper.tty0
    {:er, 'Argument 0 is not a binary'} = Baud.Nif.open nil, nil, nil
    {:er, 'Invalid device'} = Baud.Nif.open bin(256), nil, nil
    {:er, 'Argument 1 is not an integer'} = Baud.Nif.open "", nil, nil
    {:er, 'Invalid speed'} = Baud.Nif.open bin(250), 0, nil
    {:er, 'Argument 2 is not a binary'} = Baud.Nif.open "", 9600, nil
    {:er, 'Invalid config'} = Baud.Nif.open bin(250), 9600, "22"
    {:er, 'Invalid config'} = Baud.Nif.open bin(250), 9600, "4444"
    case :os.type() do
      {:win32, :nt} ->
        {:er, 'CreateFile failed'} = Baud.Nif.open bin(250), 9600, "8N1"
      {:unix, :darwin} ->
        {:er, 'open failed'} = Baud.Nif.open bin(250), 9600, "8N1"
      {:unix, :linux} ->
        {:er, 'open failed'} = Baud.Nif.open bin(250), 9600, "8N1"
    end
    {:er, 'Invalid speed'} = Baud.Nif.open tty0, 9601, "8N1"
    {:er, 'Invalid config'} = Baud.Nif.open tty0, 9600, "8NX"
    {:ok, nid0} = Baud.Nif.open tty0, 115200, "8N1"
    {:er, 'Argument 0 is not a resource'} = Baud.Nif.read nil
    {:er, 'Argument 0 is not a resource'} = Baud.Nif.write nil, nil
    {:er, 'Argument 1 is not a binary'} = Baud.Nif.write nid0, nil
    {:er, 'Argument 0 is not a resource'} = Baud.Nif.close nil
    :ok = Baud.Nif.close nid0
  end

  defp bin(size) do
    for _i<-0..size-1, into: "" do
      "*"
    end
  end

end
