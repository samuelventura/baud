defmodule Modbus.Rtu.MasterTest do
  use ExUnit.Case
  alias Baud.TTY
  alias Modbus.Model
  alias Modbus.Rtu.Master
  alias Modbus.Rtu

  test "master test" do
    tty0 = TTY.tty0()
    tty1 = TTY.tty1()
    {:ok, pid0} = Master.start_link(device: tty0)
    {:ok, pid1} = Baud.start_link(device: tty1)

    state = %{0x50 => %{{:c, 0x5152} => 0}}
    cmd = {:rc, 0x50, 0x5152, 1}
    req = <<0x50, 1, 0x51, 0x52, 0, 1>>
    res = <<0x50, 1, 1, 0x00>>
    val = [0]
    pp1(pid0, pid1, cmd, req, res, val, state)

    state = %{0x50 => %{{:c, 0x5152} => 1}}
    cmd = {:rc, 0x50, 0x5152, 1}
    req = <<0x50, 1, 0x51, 0x52, 0, 1>>
    res = <<0x50, 1, 1, 0x01>>
    val = [1]
    pp1(pid0, pid1, cmd, req, res, val, state)

    state = %{
      0x50 => %{
        {:c, 0x5152} => 0,
        {:c, 0x5153} => 1,
        {:c, 0x5154} => 1
      }
    }

    cmd = {:rc, 0x50, 0x5152, 3}
    req = <<0x50, 1, 0x51, 0x52, 0, 3>>
    res = <<0x50, 1, 1, 0x06>>
    val = [0, 1, 1]
    pp1(pid0, pid1, cmd, req, res, val, state)

    state = %{
      0x50 => %{
        {:c, 0x5152} => 0,
        {:c, 0x5153} => 0,
        {:c, 0x5154} => 1,
        {:c, 0x5155} => 1,
        {:c, 0x5156} => 1,
        {:c, 0x5157} => 1,
        {:c, 0x5158} => 0,
        {:c, 0x5159} => 0,
        {:c, 0x515A} => 0,
        {:c, 0x515B} => 1,
        {:c, 0x515C} => 0,
        {:c, 0x515D} => 1
      }
    }

    cmd = {:rc, 0x50, 0x5152, 12}
    req = <<0x50, 1, 0x51, 0x52, 0, 12>>
    res = <<0x50, 1, 2, 0x3C, 0x0A>>
    val = [0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 0, 1]
    pp1(pid0, pid1, cmd, req, res, val, state)

    state = %{0x50 => %{{:i, 0x5152} => 0}}
    cmd = {:ri, 0x50, 0x5152, 1}
    req = <<0x50, 2, 0x51, 0x52, 0, 1>>
    res = <<0x50, 2, 1, 0x00>>
    val = [0]
    pp1(pid0, pid1, cmd, req, res, val, state)

    state = %{0x50 => %{{:i, 0x5152} => 1}}
    cmd = {:ri, 0x50, 0x5152, 1}
    req = <<0x50, 2, 0x51, 0x52, 0, 1>>
    res = <<0x50, 2, 1, 0x01>>
    val = [1]
    pp1(pid0, pid1, cmd, req, res, val, state)

    state = %{
      0x50 => %{
        {:i, 0x5152} => 0,
        {:i, 0x5153} => 1,
        {:i, 0x5154} => 1
      }
    }

    cmd = {:ri, 0x50, 0x5152, 3}
    req = <<0x50, 2, 0x51, 0x52, 0, 3>>
    res = <<0x50, 2, 1, 0x06>>
    val = [0, 1, 1]
    pp1(pid0, pid1, cmd, req, res, val, state)

    state = %{
      0x50 => %{
        {:i, 0x5152} => 0,
        {:i, 0x5153} => 0,
        {:i, 0x5154} => 1,
        {:i, 0x5155} => 1,
        {:i, 0x5156} => 1,
        {:i, 0x5157} => 1,
        {:i, 0x5158} => 0,
        {:i, 0x5159} => 0,
        {:i, 0x515A} => 0,
        {:i, 0x515B} => 1,
        {:i, 0x515C} => 0,
        {:i, 0x515D} => 1
      }
    }

    cmd = {:ri, 0x50, 0x5152, 12}
    req = <<0x50, 2, 0x51, 0x52, 0, 12>>
    res = <<0x50, 2, 2, 0x3C, 0x0A>>
    val = [0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 0, 1]
    pp1(pid0, pid1, cmd, req, res, val, state)

    state = %{0x50 => %{{:hr, 0x5152} => 0x6162}}
    cmd = {:rhr, 0x50, 0x5152, 1}
    req = <<0x50, 3, 0x51, 0x52, 0, 1>>
    res = <<0x50, 3, 2, 0x61, 0x62>>
    val = [0x6162]
    pp1(pid0, pid1, cmd, req, res, val, state)

    state = %{
      0x50 => %{
        {:hr, 0x5152} => 0x6162,
        {:hr, 0x5153} => 0x6364,
        {:hr, 0x5154} => 0x6566
      }
    }

    cmd = {:rhr, 0x50, 0x5152, 3}
    req = <<0x50, 3, 0x51, 0x52, 0, 3>>
    res = <<0x50, 3, 6, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66>>
    val = [0x6162, 0x6364, 0x6566]
    pp1(pid0, pid1, cmd, req, res, val, state)

    state = %{0x50 => %{{:ir, 0x5152} => 0x6162}}
    cmd = {:rir, 0x50, 0x5152, 1}
    req = <<0x50, 4, 0x51, 0x52, 0, 1>>
    res = <<0x50, 4, 2, 0x61, 0x62>>
    val = [0x6162]
    pp1(pid0, pid1, cmd, req, res, val, state)

    state = %{
      0x50 => %{
        {:ir, 0x5152} => 0x6162,
        {:ir, 0x5153} => 0x6364,
        {:ir, 0x5154} => 0x6566
      }
    }

    cmd = {:rir, 0x50, 0x5152, 3}
    req = <<0x50, 4, 0x51, 0x52, 0, 3>>
    res = <<0x50, 4, 6, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66>>
    val = [0x6162, 0x6364, 0x6566]
    pp1(pid0, pid1, cmd, req, res, val, state)

    state = %{0x50 => %{{:c, 0x5152} => 1}}
    state2 = %{0x50 => %{{:c, 0x5152} => 0}}
    val = 0
    cmd = {:fc, 0x50, 0x5152, val}
    req = <<0x50, 5, 0x51, 0x52, 0, 0>>
    res = <<0x50, 5, 0x51, 0x52, 0, 0>>
    pp2(pid0, pid1, cmd, req, res, state, state2)

    state = %{0x50 => %{{:c, 0x5152} => 0}}
    state2 = %{0x50 => %{{:c, 0x5152} => 1}}
    val = 1
    cmd = {:fc, 0x50, 0x5152, val}
    req = <<0x50, 5, 0x51, 0x52, 0xFF, 0>>
    res = <<0x50, 5, 0x51, 0x52, 0xFF, 0>>
    pp2(pid0, pid1, cmd, req, res, state, state2)

    state = %{0x50 => %{{:hr, 0x5152} => 0}}
    state2 = %{0x50 => %{{:hr, 0x5152} => 0x6162}}
    val = 0x6162
    cmd = {:phr, 0x50, 0x5152, val}
    req = <<0x50, 6, 0x51, 0x52, 0x61, 0x62>>
    res = <<0x50, 6, 0x51, 0x52, 0x61, 0x62>>
    pp2(pid0, pid1, cmd, req, res, state, state2)

    state = %{
      0x50 => %{
        {:c, 0x5152} => 1,
        {:c, 0x5153} => 0,
        {:c, 0x5154} => 0
      }
    }

    state2 = %{
      0x50 => %{
        {:c, 0x5152} => 0,
        {:c, 0x5153} => 1,
        {:c, 0x5154} => 1
      }
    }

    val = [0, 1, 1]
    cmd = {:fc, 0x50, 0x5152, val}
    req = <<0x50, 15, 0x51, 0x52, 0, 3, 1, 0x06>>
    res = <<0x50, 15, 0x51, 0x52, 0, 3>>
    pp2(pid0, pid1, cmd, req, res, state, state2)

    state = %{
      0x50 => %{
        {:c, 0x5152} => 1,
        {:c, 0x5153} => 1,
        {:c, 0x5154} => 0,
        {:c, 0x5155} => 0,
        {:c, 0x5156} => 0,
        {:c, 0x5157} => 0,
        {:c, 0x5158} => 1,
        {:c, 0x5159} => 1,
        {:c, 0x515A} => 1,
        {:c, 0x515B} => 0,
        {:c, 0x515C} => 1,
        {:c, 0x515D} => 0
      }
    }

    state2 = %{
      0x50 => %{
        {:c, 0x5152} => 0,
        {:c, 0x5153} => 0,
        {:c, 0x5154} => 1,
        {:c, 0x5155} => 1,
        {:c, 0x5156} => 1,
        {:c, 0x5157} => 1,
        {:c, 0x5158} => 0,
        {:c, 0x5159} => 0,
        {:c, 0x515A} => 0,
        {:c, 0x515B} => 1,
        {:c, 0x515C} => 0,
        {:c, 0x515D} => 1
      }
    }

    val = [0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 0, 1]
    cmd = {:fc, 0x50, 0x5152, val}
    req = <<0x50, 15, 0x51, 0x52, 0, 12, 2, 0x3C, 0x0A>>
    res = <<0x50, 15, 0x51, 0x52, 0, 12>>
    pp2(pid0, pid1, cmd, req, res, state, state2)

    state = %{
      0x50 => %{
        {:hr, 0x5152} => 0,
        {:hr, 0x5153} => 0,
        {:hr, 0x5154} => 0
      }
    }

    state2 = %{
      0x50 => %{
        {:hr, 0x5152} => 0x6162,
        {:hr, 0x5153} => 0x6364,
        {:hr, 0x5154} => 0x6566
      }
    }

    val = [0x6162, 0x6364, 0x6566]
    cmd = {:phr, 0x50, 0x5152, val}
    req = <<0x50, 16, 0x51, 0x52, 0, 3, 6, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66>>
    res = <<0x50, 16, 0x51, 0x52, 0, 3>>
    pp2(pid0, pid1, cmd, req, res, state, state2)

    :ok = Master.stop(pid0)
    :ok = Baud.stop(pid1)
  end

  defp pp1(pid0, pid1, cmd, req, res, val, state) do
    spawn(fn ->
      length = Rtu.req_len(cmd)
      {:ok, rtu_req} = Baud.readn(pid1, length)
      ^req = Rtu.unwrap(rtu_req)
      ^rtu_req = Rtu.wrap(req)
      ^cmd = Rtu.parse_req(rtu_req)

      case val do
        nil -> {:ok, ^state} = Model.apply(state, cmd)
        _ -> {:ok, ^state, ^val} = Model.apply(state, cmd)
      end

      rtu_res = Rtu.pack_res(cmd, val)
      ^res = Rtu.unwrap(rtu_res)
      ^rtu_res = Rtu.wrap(res)
      Baud.write(pid1, rtu_res)
    end)

    case val do
      nil -> :ok = Modbus.Rtu.Master.exec(pid0, cmd)
      _ -> {:ok, ^val} = Modbus.Rtu.Master.exec(pid0, cmd)
    end
  end

  defp pp2(pid0, pid1, cmd, req, res, state, state2) do
    spawn(fn ->
      length = Rtu.req_len(cmd)
      result = Baud.readn(pid1, length, 800)
      {:ok, rtu_req} = result
      ^req = Rtu.unwrap(rtu_req)
      ^rtu_req = Rtu.wrap(req)
      ^cmd = Rtu.parse_req(rtu_req)
      {:ok, ^state2} = Model.apply(state, cmd)
      rtu_res = Rtu.pack_res(cmd, nil)
      ^res = Rtu.unwrap(rtu_res)
      ^rtu_res = Rtu.wrap(res)
      Baud.write(pid1, rtu_res)
    end)

    :ok = Modbus.Rtu.Master.exec(pid0, cmd)
  end
end
