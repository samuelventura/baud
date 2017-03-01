defmodule Baud.Nif do

  @on_load :init

  def init() do
    nif = :code.priv_dir(:baud) ++ '/baud_nif'
    :erlang.load_nif(nif, 0)
  end

  def open(_device, _speed, _config) do
    "NIF library not loaded"
  end

  def read(_nid) do
    "NIF library not loaded"
  end

  def write(_nid, _data) do
    "NIF library not loaded"
  end

  def close(_nid) do
    "NIF library not loaded"
  end

end
