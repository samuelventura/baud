defmodule Baud.TTY do

  #Startech ICUSB2322F
  def name(id) do
    case id do
      0 -> "COM12"
      1 -> "COM13"
    end
  end

end
