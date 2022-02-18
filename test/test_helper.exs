defmodule Baud.TTY do
  def tty0(), do: System.get_env("TTY0")
  def tty1(), do: System.get_env("TTY1")
end

ExUnit.start()
