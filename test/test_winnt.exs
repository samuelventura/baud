defmodule Baud.TTY do

  #Startech ICUSB2322F
  def name(id) do
    case id do
      0 -> "COM4"
      1 -> "COM5"
    end
  end

end
