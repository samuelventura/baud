defmodule Baud.RtuTest do
  use ExUnit.Case
  alias Baud.TestHelper
  alias Modbus.Request
  alias Modbus.Response
  alias Modbus.Model
  alias Modbus.Rtu

  test "Read 0 from Single Coil" do
    tty0 = TestHelper.tty0
    tty1 = TestHelper.tty1
    {:ok, pid0} = Baud.Rtu.start_link [device: tty0]
    {:ok, pid1} = Baud.start_link [device: tty1]

    state0 = %{ 0x50=>%{ {:c, 0x5152}=>0 } }
    cmd0 = {:rc, 0x50, 0x5152, 1}
    req0 = <<0x50, 1, 0x51, 0x52, 0, 1>>
    res0 = <<0x50, 1, 1, 0x00>>
    val0 = [0]
    pp1 pid0, pid1, cmd0, req0, res0, val0, state0

    state0 = %{ 0x50=>%{ {:c, 0x5152}=>1 } }
    cmd0 = {:rc, 0x50, 0x5152, 1}
    req0 = <<0x50, 1, 0x51, 0x52, 0, 1>>
    res0 = <<0x50, 1, 1, 0x01>>
    val0 = [1]
    pp1 pid0, pid1, cmd0, req0, res0, val0, state0

    state0 = %{ 0x50=>%{
      {:c, 0x5152}=>0, {:c, 0x5153}=>1, {:c, 0x5154}=>1,
    } }
    cmd0 = {:rc, 0x50, 0x5152, 3}
    req0 = <<0x50, 1, 0x51, 0x52, 0, 3>>
    res0 = <<0x50, 1, 1, 0x06>>
    val0 = [0,1,1]
    pp1 pid0, pid1, cmd0, req0, res0, val0, state0

    state0 = %{ 0x50=>%{
      {:c, 0x5152}=>0, {:c, 0x5153}=>0, {:c, 0x5154}=>1, {:c, 0x5155}=>1,
      {:c, 0x5156}=>1, {:c, 0x5157}=>1, {:c, 0x5158}=>0, {:c, 0x5159}=>0,
      {:c, 0x515A}=>0, {:c, 0x515B}=>1, {:c, 0x515C}=>0, {:c, 0x515D}=>1,
    } }
    cmd0 = {:rc, 0x50, 0x5152, 12}
    req0 = <<0x50, 1, 0x51, 0x52, 0, 12>>
    res0 = <<0x50, 1, 2, 0x3C, 0x0A>>
    val0 = [0,0,1,1, 1,1,0,0, 0,1,0,1]
    pp1 pid0, pid1, cmd0, req0, res0, val0, state0

    state0 = %{ 0x50=>%{ {:i, 0x5152}=>0 } }
    cmd0 = {:ri, 0x50, 0x5152, 1}
    req0 = <<0x50, 2, 0x51, 0x52, 0, 1>>
    res0 = <<0x50, 2, 1, 0x00>>
    val0 = [0]
    pp1 pid0, pid1, cmd0, req0, res0, val0, state0

    state0 = %{ 0x50=>%{ {:i, 0x5152}=>1 } }
    cmd0 = {:ri, 0x50, 0x5152, 1}
    req0 = <<0x50, 2, 0x51, 0x52, 0, 1>>
    res0 = <<0x50, 2, 1, 0x01>>
    val0 = [1]
    pp1 pid0, pid1, cmd0, req0, res0, val0, state0

    state0 = %{ 0x50=>%{
      {:i, 0x5152}=>0, {:i, 0x5153}=>1, {:i, 0x5154}=>1,
    } }
    cmd0 = {:ri, 0x50, 0x5152, 3}
    req0 = <<0x50, 2, 0x51, 0x52, 0, 3>>
    res0 = <<0x50, 2, 1, 0x06>>
    val0 = [0,1,1]
    pp1 pid0, pid1, cmd0, req0, res0, val0, state0

    state0 = %{ 0x50=>%{
      {:i, 0x5152}=>0, {:i, 0x5153}=>0, {:i, 0x5154}=>1, {:i, 0x5155}=>1,
      {:i, 0x5156}=>1, {:i, 0x5157}=>1, {:i, 0x5158}=>0, {:i, 0x5159}=>0,
      {:i, 0x515A}=>0, {:i, 0x515B}=>1, {:i, 0x515C}=>0, {:i, 0x515D}=>1,
    } }
    cmd0 = {:ri, 0x50, 0x5152, 12}
    req0 = <<0x50, 2, 0x51, 0x52, 0, 12>>
    res0 = <<0x50, 2, 2, 0x3C, 0x0A>>
    val0 = [0,0,1,1, 1,1,0,0, 0,1,0,1]
    pp1 pid0, pid1, cmd0, req0, res0, val0, state0

    state0 = %{ 0x50=>%{ {:hr, 0x5152}=>0x6162 } }
    cmd0 = {:rhr, 0x50, 0x5152, 1}
    req0 = <<0x50, 3, 0x51, 0x52, 0, 1>>
    res0 = <<0x50, 3, 2, 0x61, 0x62>>
    val0 = [0x6162]
    pp1 pid0, pid1, cmd0, req0, res0, val0, state0

    state0 = %{ 0x50=>%{
      {:hr, 0x5152}=>0x6162, {:hr, 0x5153}=>0x6364, {:hr, 0x5154}=>0x6566,
    } }
    cmd0 = {:rhr, 0x50, 0x5152, 3}
    req0 = <<0x50, 3, 0x51, 0x52, 0, 3>>
    res0 = <<0x50, 3, 6, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66>>
    val0 = [0x6162,0x6364,0x6566]
    pp1 pid0, pid1, cmd0, req0, res0, val0, state0

    state0 = %{ 0x50=>%{ {:ir, 0x5152}=>0x6162 } }
    cmd0 = {:rir, 0x50, 0x5152, 1}
    req0 = <<0x50, 4, 0x51, 0x52, 0, 1>>
    res0 = <<0x50, 4, 2, 0x61, 0x62>>
    val0 = [0x6162]
    pp1 pid0, pid1, cmd0, req0, res0, val0, state0

    state0 = %{ 0x50=>%{
      {:ir, 0x5152}=>0x6162, {:ir, 0x5153}=>0x6364, {:ir, 0x5154}=>0x6566,
    } }
    cmd0 = {:rir, 0x50, 0x5152, 3}
    req0 = <<0x50, 4, 0x51, 0x52, 0, 3>>
    res0 = <<0x50, 4, 6, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66>>
    val0 = [0x6162,0x6364,0x6566]
    pp1 pid0, pid1, cmd0, req0, res0, val0, state0

    state0 = %{ 0x50=>%{ {:c, 0x5152}=>1 } }
    state1 = %{ 0x50=>%{ {:c, 0x5152}=>0 } }
    val0 = 0
    cmd0 = {:fc, 0x50, 0x5152, val0}
    req0 = <<0x50, 5, 0x51, 0x52, 0, 0>>
    res0 = <<0x50, 5, 0x51, 0x52, 0, 0>>
    pp2 pid0, pid1, cmd0, req0, res0, state0, state1

    state0 = %{ 0x50=>%{ {:c, 0x5152}=>0 } }
    state1 = %{ 0x50=>%{ {:c, 0x5152}=>1 } }
    val0 = 1
    cmd0 = {:fc, 0x50, 0x5152, val0}
    req0 = <<0x50, 5, 0x51, 0x52, 0xFF, 0>>
    res0 = <<0x50, 5, 0x51, 0x52, 0xFF, 0>>
    pp2 pid0, pid1, cmd0, req0, res0, state0, state1

    state0 = %{ 0x50=>%{ {:hr, 0x5152}=>0 } }
    state1 = %{ 0x50=>%{ {:hr, 0x5152}=>0x6162 } }
    val0 = 0x6162
    cmd0 = {:phr, 0x50, 0x5152, val0}
    req0 = <<0x50, 6, 0x51, 0x52, 0x61, 0x62>>
    res0 = <<0x50, 6, 0x51, 0x52, 0x61, 0x62>>
    pp2 pid0, pid1, cmd0, req0, res0, state0, state1

    state0 = %{ 0x50=>%{
      {:c, 0x5152}=>1, {:c, 0x5153}=>0, {:c, 0x5154}=>0,
    } }
    state1 = %{ 0x50=>%{
      {:c, 0x5152}=>0, {:c, 0x5153}=>1, {:c, 0x5154}=>1,
    } }
    val0 = [0,1,1]
    cmd0 = {:fc, 0x50, 0x5152, val0}
    req0 = <<0x50, 15, 0x51, 0x52, 0, 3, 1, 0x06>>
    res0 = <<0x50, 15, 0x51, 0x52, 0, 3>>
    pp2 pid0, pid1, cmd0, req0, res0, state0, state1

    state0 = %{ 0x50=>%{
      {:c, 0x5152}=>1, {:c, 0x5153}=>1, {:c, 0x5154}=>0, {:c, 0x5155}=>0,
      {:c, 0x5156}=>0, {:c, 0x5157}=>0, {:c, 0x5158}=>1, {:c, 0x5159}=>1,
      {:c, 0x515A}=>1, {:c, 0x515B}=>0, {:c, 0x515C}=>1, {:c, 0x515D}=>0,
    } }
    state1 = %{ 0x50=>%{
      {:c, 0x5152}=>0, {:c, 0x5153}=>0, {:c, 0x5154}=>1, {:c, 0x5155}=>1,
      {:c, 0x5156}=>1, {:c, 0x5157}=>1, {:c, 0x5158}=>0, {:c, 0x5159}=>0,
      {:c, 0x515A}=>0, {:c, 0x515B}=>1, {:c, 0x515C}=>0, {:c, 0x515D}=>1,
    } }
    val0 = [0,0,1,1, 1,1,0,0, 0,1,0,1]
    cmd0 = {:fc, 0x50, 0x5152, val0}
    req0 = <<0x50, 15, 0x51, 0x52, 0, 12, 2, 0x3C, 0x0A>>
    res0 = <<0x50, 15, 0x51, 0x52, 0, 12>>
    pp2 pid0, pid1, cmd0, req0, res0, state0, state1

    state0 = %{ 0x50=>%{
      {:hr, 0x5152}=>0, {:hr, 0x5153}=>0, {:hr, 0x5154}=>0,
    } }
    state1 = %{ 0x50=>%{
      {:hr, 0x5152}=>0x6162, {:hr, 0x5153}=>0x6364, {:hr, 0x5154}=>0x6566,
    } }
    val0 = [0x6162,0x6364,0x6566]
    cmd0 = {:phr, 0x50, 0x5152, val0}
    req0 = <<0x50, 16, 0x51, 0x52, 0, 3, 6, 0x61,0x62, 0x63,0x64, 0x65,0x66>>
    res0 = <<0x50, 16, 0x51, 0x52, 0, 3>>
    pp2 pid0, pid1, cmd0, req0, res0, state0, state1
  end

  def pp1 (pid0, pid1, cmd, req, res, val, state) do
    spawn(fn ->
      {:ok, req} = Baud.read pid1, Rtu.res_len(cmd)
      ^cmd = Rtu.parse_req(req)
      {^state, ^val} =  Model.apply(state, cmd)
      res = Rtu.pack_res(cmd, val)
      Baud.write pid1, res
    end)
    {:ok, val} = Baud.Rtu.exec(cmd)
  end

  def pp2 (pid0, pid1, cmd, req, res, state0, state1) do
    #req = Rtu.pack_req(cmd)
    #assert cmd == Rtu.parse_req(req)
    #res = Rtu.pack_res(cmd, nil)
    #assert nil == Rtu.parse_res(cmd, res)
    #assert byte_size(res) == Rtu.res_len(cmd)
  end

end
