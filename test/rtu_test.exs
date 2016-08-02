defmodule Baud.RtuTest do
  use ExUnit.Case
  alias Baud.TestHelper
  alias Baud.Rtu

  test "rtu test" do
    tty0 = TestHelper.tty0()
    tty1 = TestHelper.tty1()
    {:ok, pid0} = Rtu.start_link([portname: tty0])
    {:ok, pid1} = Baud.start_link([portname: tty1, packto: 100])
    :ok = Rtu.echo(pid0)
    :ok = Baud.echo(pid1)

    #Write 1 to coil at 3200
    :ok = Baud.write(pid1, <<01, 05, 0x0C, 0x80, 0xFF, 00, 0x8E, 0x82>>)
    :ok = Rtu.wcoil(pid0, 1, 3200, 1)
    {:ok, <<01, 05, 0x0C, 0x80, 0xFF, 00, 0x8E, 0x82>>} = Baud.read(pid1)
    :ok = Baud.write(pid1, <<01, 05, 0x0C, 0x80, 0xFF, 00, 0x8E, 0x82>>)
    :ok = Rtu.on(pid0, 1, 3200)
    {:ok, <<01, 05, 0x0C, 0x80, 0xFF, 00, 0x8E, 0x82>>} = Baud.read(pid1)
    #Write 0 to coil at 3200
    :ok = Baud.write(pid1, <<01, 05, 0x0C, 0x80, 0x00, 0x00, 0xCF, 0x72>>)
    :ok = Rtu.wcoil(pid0, 1, 3200, 0)
    {:ok, <<01, 05, 0x0C, 0x80, 00, 00, 0xCF, 0x72>>} = Baud.read(pid1)
    :ok = Baud.write(pid1, <<01, 05, 0x0C, 0x80, 0x00, 0x00, 0xCF, 0x72>>)
    :ok = Rtu.off(pid0, 1, 3200)
    {:ok, <<01, 05, 0x0C, 0x80, 00, 00, 0xCF, 0x72>>} = Baud.read(pid1)
    #Write 1 to coil at 3201
    :ok = Baud.write(pid1, <<01, 05, 0x0C, 0x81, 0xFF, 00, 0xDF, 0x42>>)
    :ok = Rtu.wcoil(pid0, 1, 3201, 1)
    {:ok, <<01, 05, 0x0C, 0x81, 0xFF, 00, 0xDF, 0x42>>} = Baud.read(pid1)
    :ok = Baud.write(pid1, <<01, 05, 0x0C, 0x81, 0xFF, 00, 0xDF, 0x42>>)
    :ok = Rtu.on(pid0, 1, 3201)
    {:ok, <<01, 05, 0x0C, 0x81, 0xFF, 00, 0xDF, 0x42>>} = Baud.read(pid1)
    #Write 1 to coil at 3207
    :ok = Baud.write(pid1, <<01, 05, 0x0C, 0x87, 0xFF, 00, 0x3F, 0x43>>)
    :ok = Rtu.wcoil(pid0, 1, 3207, 1)
    {:ok, <<01, 05, 0x0C, 0x87, 0xFF, 00, 0x3F, 0x43>>} = Baud.read(pid1)
    :ok = Baud.write(pid1, <<01, 05, 0x0C, 0x87, 0xFF, 00, 0x3F, 0x43>>)
    :ok = Rtu.on(pid0, 1, 3207)
    {:ok, <<01, 05, 0x0C, 0x87, 0xFF, 00, 0x3F, 0x43>>} = Baud.read(pid1)
    #Read 0 from coil at 3200
    :ok = Baud.write(pid1, <<01, 01, 01, 00, 0x51, 0x88>>)
    {:ok, 0} = Rtu.rcoil(pid0, 1, 3200)
    {:ok, <<01, 01, 0x0C, 0x80, 00, 01, 0xFF, 0x72>>} = Baud.read(pid1)
    #Read 1 from coil at 3200
    :ok = Baud.write(pid1, <<01, 01, 01, 01, 0x90, 0x48>>)
    {:ok, 1} = Rtu.rcoil(pid0, 1, 3200)
    {:ok, <<01, 01, 0x0C, 0x80, 00, 01, 0xFF, 0x72>>} = Baud.read(pid1)
    #Read 1 from coil at 3201
    :ok = Baud.write(pid1, <<01, 01, 01, 01, 0x90, 0x48>>)
    {:ok, 1} = Rtu.rcoil(pid0, 1, 3201)
    {:ok, <<01, 01, 0x0C, 0x81, 00, 01, 0xAE, 0xB2>>} = Baud.read(pid1)
    #Read 1 from coil at 3207
    :ok = Baud.write(pid1, <<01, 01, 01, 01, 0x90, 0x48>>)
    {:ok, 1} = Rtu.rcoil(pid0, 1, 3207)
    {:ok, <<01, 01, 0x0C, 0x87, 00, 01, 0x4E, 0xB3>>} = Baud.read(pid1)

    #Write to coils at 3200+8
    :ok = Baud.write(pid1, <<01, 0x0F, 0x0C, 0x80, 00, 08, 0x56, 0xB5>>)
    :ok = Rtu.wcoils(pid0, 1, 3200, [1,0,1,1,1,0,0,1])
    {:ok, <<01, 0x0F, 0x0C, 0x80, 00, 08, 01, 0x9D, 0x3E, 0x2E>>} = Baud.read(pid1)
    #Read from coils at 3200+8
    :ok = Baud.write(pid1, <<01, 01, 01, 0x9D, 0x90, 0x21>>)
    {:ok, [1,0,1,1,1,0,0,1]} = Rtu.rcoils(pid0, 1, 3200, 8)
    {:ok, <<01, 01, 0x0C, 0x80, 00, 08, 0x3F, 0x74>>} = Baud.read(pid1)
    #Write coils at 3200+4
    :ok = Baud.write(pid1, <<01, 0x0F, 0x0C, 0x80, 00, 04, 0x56, 0xB0>>)
    :ok = Rtu.wcoils(pid0, 1, 3200, [1,0,1,1])
    {:ok, <<01, 0x0F, 0x0C, 0x80, 00, 04, 01, 0x0D, 0xFE, 0x41>>} = Baud.read(pid1)
    #Read from coils at 3200+4
    :ok = Baud.write(pid1, <<01, 01, 01, 0x0D, 0x90, 0x4D>>)
    {:ok, [1,0,1,1]} = Rtu.rcoils(pid0, 1, 3200, 4)
    {:ok, <<01, 01, 0x0C, 0x80, 00, 04, 0x3F, 0x71>>} = Baud.read(pid1)
    #Write coils at 3204+4
    :ok = Baud.write(pid1, <<01, 0x0F, 0x0C, 0x84, 00, 04, 0x17, 0x71>>)
    :ok = Rtu.wcoils(pid0, 1, 3204, [1,0,0,1])
    {:ok, <<01, 0x0F, 0x0C, 0x84, 00, 04, 01, 09, 0x0E, 0x42>>} = Baud.read(pid1)
    #Read from coils at 3204+4
    :ok = Baud.write(pid1, <<01, 01, 01, 0x09, 0x91, 0x8E>>)
    {:ok, [1,0,0,1]} = Rtu.rcoils(pid0, 1, 3204, 4)
    {:ok, <<01, 01, 0x0C, 0x84, 00, 04, 0x7E, 0xB0>>} = Baud.read(pid1)
    #Write coils at 3202+4
    :ok = Baud.write(pid1, <<01, 0x0F, 0x0C, 0x82, 00, 04, 0xF7, 0x70>>)
    :ok = Rtu.wcoils(pid0, 1, 3202, [1,1,1,0])
    {:ok, <<01, 0x0F, 0x0C, 0x82, 00, 04, 01, 07, 07, 0x86>>} = Baud.read(pid1)
    #Read from coils at 3202+4
    :ok = Baud.write(pid1, <<01, 01, 01, 0x07, 0x10, 0x4A>>)
    {:ok, [1,1,1,0]} = Rtu.rcoils(pid0, 1, 3202, 4)
    {:ok, <<01, 01, 0x0C, 0x82, 00, 04, 0x9E, 0xB1>>} = Baud.read(pid1)

    Rtu.close(pid0);
    Rtu.stop(pid0);
    Baud.close(pid1);
    Baud.stop(pid1);
  end

end
