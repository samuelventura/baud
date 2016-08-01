
defmodule Baud.TestHelper do

  #Use dual FTDI USB-Serial adapter ICUSB2322F with 3 wire null modem between them.
  #Shorter is #1. Larger is #2.
  def tty0() do
    case :os.type() do
      {:unix, :darwin} -> "cu.usbserial-FTYHQD9MA"
      {:unix, :linux} -> "ttyUSB0"
      {:win32, :nt} -> "COM5"
    end
  end

  def tty1() do
    case :os.type() do
      {:unix, :darwin} -> "cu.usbserial-FTYHQD9MB"
      {:unix, :linux} -> "ttyUSB1"
      {:win32, :nt} -> "COM6"
    end
  end

  def full(tty) do
    case :os.type() do
      {:unix, :darwin} -> "/dev/" <> tty
      {:unix, :linux} -> "/dev/" <> tty
      {:win32, :nt} -> tty
    end
  end
end

ExUnit.start()
