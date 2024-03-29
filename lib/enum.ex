defmodule Baud.Enum do
  @moduledoc """
  Serial port enumeration module.
  """

  @dev "/dev"

  # https://regex101.com/
  # FTDI /dev/tty.usbserial-FTYHQD9MA | /dev/tty.usbserial-FTYHQD9MB | ...
  # Prolific /dev/tty.usbserial | /dev/tty.usbserial2 | ...
  # http://stackoverflow.com/questions/8632586/macos-whats-the-difference-between-dev-baud-and-dev-cu
  @darwinre ~r/(cu|tty)\.usbserial.*/
  @linuxre ~r/ttyS[0-9]*|ttyUSB[0-9]*/

  @doc """
  Lists the names of the available serial ports.

  Returns: `["COM1", "/dev/ttyUSB0", "/dev/tty.usbserial-FTYHQD9MA"]`
  """
  def list() do
    # uname -s
    # {:unix, :darwin} MacPro OS X El Capitan
    # {:unix, :linux} Ubuntu 16.04 64x
    # {:unix, :linux} Ubuntu 16.04 32x
    # {:win32, :nt} Windows 7 32x con OTP 32x
    # {:win32, :nt} Windows 7 64x con OTP 64x
    list(:os.type())
  end

  defp list({:unix, :darwin}) do
    for file <- File.ls!(@dev),
        Regex.match?(@darwinre, file) do
      Path.join(@dev, file)
    end
  end

  defp list({:unix, :linux}) do
    for file <- File.ls!(@dev),
        Regex.match?(@linuxre, file) do
      Path.join(@dev, file)
    end
  end

  # http://stackoverflow.com/questions/1388871/how-do-i-get-a-list-of-available-serial-ports-in-win32
  # UNC Paths \\\\.\\COM11
  defp list({:win32, :nt}) do
    {:ok, handle} = :win32reg.open([:read])
    # key may not exists until one port is added
    case :win32reg.change_key(handle, '\\local_machine\\hardware\\devicemap\\serialcomm') do
      :ok ->
        # {:ok,  [{'\\Device\\ProlificSerial2', 'COM4'}, {'\\Device\\ProlificSerial3', 'COM3'}]}
        {:ok, values} = :win32reg.values(handle)
        :ok = :win32reg.close(handle)

        for {_, comm} <- values do
          # returned as char lists
          to_string(comm)
        end

      _ ->
        []
    end
  end
end
