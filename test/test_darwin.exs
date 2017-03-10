defmodule Baud.TTY do

  #Startech ICUSB2322F
  def name(id) do
    case id do
      0 -> "cu.usbserial-FTYHQD9MA"
      1 -> "cu.usbserial-FTYHQD9MB"
    end
  end

end
