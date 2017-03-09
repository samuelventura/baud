ExUnit.start()

defmodule Baud.TestHelper do

  #USB-RS485-WE USB to RS485 Adapter
  def tty() do
    case :os.type() do
      {:unix, :darwin} -> "cu.usbserial-FTVFV143"
      {:unix, :linux} -> "ttyS0"
      {:win32, :nt} -> "COM10"
    end
  end

  #ICUSB2322F FTDI USB to dual RS232 adapter
  #with 3 wire null modem between them
  #Shorter is #1. Larger is #2.
  def tty0() do
    case :os.type() do
      {:unix, :darwin} -> "cu.usbserial-FTYHQD9MA"
      {:unix, :linux} -> "ttyS5"
      {:win32, :nt} -> "COM12"
    end
  end

  def tty1() do
    case :os.type() do
      {:unix, :darwin} -> "cu.usbserial-FTYHQD9MB"
      {:unix, :linux} -> "ttyS6"
      {:win32, :nt} -> "COM13"
    end
  end

end
