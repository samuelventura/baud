defmodule Baud.TTY do
  # couple of null modem serial ports needed
  def tty0() do
    case :os.type() do
      {:unix, :darwin} -> find("tty.usbserial-", 0)
      {:unix, :linux} -> find("ttyUSB", 0)
      {:win32, :nt} -> "COM10"
    end
  end

  def tty1() do
    case :os.type() do
      {:unix, :darwin} -> find("tty.usbserial-", 1)
      {:unix, :linux} -> find("ttyUSB", 1)
      {:win32, :nt} -> "COM11"
    end
  end

  defp find(prefix, index) do
    list = Path.wildcard("/dev/#{prefix}*")

    case index do
      0 ->
        [first | _] = list
        Path.basename(first)

      1 ->
        [_, second | _] = list
        Path.basename(second)
    end
  end
end

ExUnit.start()
