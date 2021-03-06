# rpgxp

rpgxp is a project that seeks to be able to create games compatible with
[mkxp](https://github.com/Ancurio/mkxp).  
It's under development and many features are missing.
Code is written to work, so sometimes it's a mess.
Contributions and bug reports are welcome.  
It's written in Ruby on GTK+3.  

It is licensed under the GNU General Public License v3.

## Dependencies
Ruby, rake and the following gems (including their dependencies):
- gtk3
- ruby-filemagic
- launchy
- os
- gettext
- open5  
They be can downloaded running `$ rake deps`

## Install

### On GNU systems
First download a mkxp executable (licensed under GPLv2) from
[here](https://github.com/Ancurio/mkxp/#prebuilt-binaries) or an
amd64 Ubuntu-compatible statically linked binary from
[here](https://www.dropbox.com/s/x0pwgn2fw72t27k/mkxp_linux?dl=0).
Once extracted, get the binary and rename it "mkxp_linux" in the data/system/
directory.  

Download the public domain soundfont:
[GMGSx.sf2](https://www.dropbox.com/s/qxdvoxxcexsvn43/GMGSx.sf2?dl=0) and place
it in the data/system/ directory.  

To install run the following commands:  
`$ rake`  
`$ sudo rake install`  
You can change installation directory using the PREFIX environment variable,
e.g.:  
`$ PREFIX=/usr sudo rake install`

To run just execute:
`$ rpgxp`

### Other platforms
GNU instructions should work on Darwin. Win32 is not supported (yet?).

