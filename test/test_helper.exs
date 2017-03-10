case :os.type() do
  {:unix, :darwin} -> Code.load_file("test/test_darwin.exs")
  {:unix, :linux} -> Code.load_file("test/test_linux.exs")
  {:win32, :nt} -> Code.load_file("test/test_winnt.exs")
end

ExUnit.start()
