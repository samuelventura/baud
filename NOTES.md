# Baud

Serial port with Modbus support.

## Platform detection

`uname` returns Linux, Darwin, and MSYS_NT-6.1
in Linux, Mac and Windows 7 (both 32 and 64 bits) respectively

`:os.type()` returns:

- `{:unix, :darwin}` in MacPro OS X El Capitan
- `{:unix, :linux}` in Ubuntu 16.04 64x (OTP from ubuntu repos)
- `{:unix, :linux}` in Ubuntu 16.04 32x (OTP from ubuntu repos)
- `{:win32, :nt}` in Windows 7 32x con OTP 32x
- `{:win32, :nt}` in Windows 7 64x con OTP 64x

## Windows 64 Development

- Install Elixir + Erlang
```shell
#Web installer asks to download and install the OTP if not found
https://repo.hex.pm/elixir-websetup.exe
```
- Install msys2-x86_64-20160205.exe from https://msys2.github.io/. Default installation folder is C:\msys64
- Using pacman install gcc, make, and git
```shell
pacman -S mingw-w64-x86_64-gcc
pacman -S make
pacman -S git
```
- Add C:\msys64\mingw64\bin to PATH (turn gcc visible)
- Add C:\msys64\usr\bin to PATH (turn make and other utils visible)
- Install node-v6.4.0-x64.msi
```shell
mix deps.get
npm install
npm install bower -g
bower install
#testing requires COM5 null modem to COM6
./test.sh
mix phoenix.server
#go to http://localhost:4000/
```

With the above *PATH* exports `mix` can run both form *cmd* and from *msys2 console*. Running from *cmd* triggers the **Windows application crash report dialog** when the native port crashes.

## OSX Development (El Capitan)

*Expect intermittent test failures because of data corruption and failure to recognize FTDI adapters if unplugged while open. OSX also allows opening multiple times the same port and that screws the tests if not properly isolated.*

- Install erlang, elixir, and node
```shell
brew install elixir erlang node
```
- Setup everything else
```shell
sudo dscl . append /Groups/wheel GroupMembership samuel
mix deps.get
#testing requires a couple of null modem serial ports
#serial port names are hardcoded in test/test_helper.exs
./test.sh
```

## Ubuntu 16.04 64 Development

*Strange launch errors were corrected by deleting node_modules and run npm install again.*

- Install elixir+erlang
```shell
wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && sudo dpkg -i erlang-solutions_1.0_all.deb
sudo apt-get update
sudo apt-get install elixir
```
- Install node
```shell
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
sudo apt-get install -y nodejs
```
- Setup everything else
```shell
sudo apt-get install build-essential checkinstall
sudo gpasswd -a samuel dialout
mix deps.get
#testing requires ttyUSB0 null modem to ttyUSB1
./test.sh
```

## Testing

- See `test/test_helper.exs` for requirements. Port names are hardcoded there.
- Use dual FTDI USB-Serial adapter ICUSB2322F with 3 wire null modem between them.
- Use USB-RS485-WE USB to RS485 Adapter to test modport RTU communications. Launch with `mix panel`.

## Miscellaneous

A pair of devices are created:
  - `tty` requires DCD line raised or open call blocks.
  Putting in the red null modem adapter makes baud work.
  - `cu` does not require DCD line raised
  - http://pbxbook.com/other/mac-tty.html

Port names:
- `FTDI` FT232R /dev/tty.usbserial-FTYHQD9MA | /dev/tty.usbserial-FTYHQD9MB | ...
  - Ports wont reappear if unplugged while open
- `Prolific` PL2303 /dev/tty.usbserial | /dev/tty.usbserial2 | ...
  - Ports detected only on first plug, reboot required to have them back if unplugged
  - Changes second port postfix number on replug
- `Silab` CP210x /dev/tty.SLAB_USBtoUART | ***????***

Latency and Packetization:
- Posix minimum kernel packetization is 100ms because VTIME is measured in 0.1s units.
- Win32 kernel packetizacion granularity is in millis but have not tested it yet
- The USB-Serial converters have their own packetization delays (see links below)
- https://projectgus.com/2011/10/notes-on-ftdi-latency-with-arduino/
- http://www.unixwiz.net/techtips/termios-vmin-vtime.html
- http://www.lookrs232.com/com_port_programming/api_timeout.htm

Flushing and O_SYNC:
- Not using O_SYNC flag neither explicitly flushing the handles
- http://dreamlayers.blogspot.mx/2011/10/unix-serial-port-output-buffer.html
