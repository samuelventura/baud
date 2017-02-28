defmodule Baud.Nif do

  @on_load :init

  def init() do
    nif = :code.priv_dir(:baud) ++ '/baud_nif'
    :erlang.load_nif(nif, 0)
  end

  def open(device, speed, config)
    when is_binary(device) and
    byte_size(device) < 256 and
    is_integer(speed) and
    speed > 0 and
    speed < 0x7FFFFFFF and
    is_binary(config) and
    byte_size(config) == 3
  do
    "NIF library not loaded"
  end

  def read(fd)
    when is_integer(fd)
  do
    "NIF library not loaded"
  end

  def write(fd, data)
    when is_integer(fd) and
    is_binary(data)
  do
    "NIF library not loaded"
  end

  def close(fd)
    when is_integer(fd)
  do
    "NIF library not loaded"
  end

end
