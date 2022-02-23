defmodule Baud.Master do
  @moduledoc """
  RTU Master server.

  ```elixir
  # run with: mix slave
  alias Baud.Slave
  alias Baud.Master

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

  {:ok, slave} = Slave.start_link(model: model, device: tty0, speed: 115_200)
  {:ok, master} = Master.start_link(device: tty1, speed: 115_200)

  # read input
  {:ok, [0, 1]} = Master.exec(master, {:ri, 0x50, 0x5354, 2})
  # read input registers
  {:ok, [0x6364, 0x6566]} = Master.exec(master, {:rir, 0x50, 0x5859, 2})

  # toggle coil and read it back
  :ok = Master.exec(master, {:fc, 0x50, 0x5152, 0})
  {:ok, [0]} = Master.exec(master, {:rc, 0x50, 0x5152, 1})
  :ok = Master.exec(master, {:fc, 0x50, 0x5152, 1})
  {:ok, [1]} = Master.exec(master, {:rc, 0x50, 0x5152, 1})

  # increment holding register and read it back
  {:ok, [0x6162]} = Master.exec(master, {:rhr, 0x50, 0x5657, 1})
  :ok = Master.exec(master, {:phr, 0x50, 0x5657, 0x6163})
  {:ok, [0x6163]} = Master.exec(master, {:rhr, 0x50, 0x5657, 1})

  :ok = Master.stop(master)
  :ok = Slave.stop(slave)
  ```

  Uses:
  - https://github.com/samuelventura/sniff
  - https://github.com/samuelventura/modbus
  """
  @to 2000

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
    Baud.Master.start_link(device: "/dev/ttyUSB0")
    ```
  """
  def start_link(opts) do
    trans = Keyword.get(opts, :trans, Baud.Transport)
    proto = Keyword.get(opts, :proto, :rtu)
    opts = Keyword.put(opts, :trans, trans)
    opts = Keyword.put(opts, :proto, proto)
    Modbus.Master.start_link(opts)
  end

  @doc """
    Closes the connection.

    Returns `:ok`.
  """
  def stop(master) do
    Modbus.Master.stop(master)
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
  def exec(master, cmd, timeout \\ @to)
      when is_tuple(cmd) and is_integer(timeout) do
    Modbus.Master.exec(master, cmd, timeout)
  end
end
