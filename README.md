Metal Lisp
==========

A lisp -> assembly compiler designed to run on bare metal.

* Author:  Simon David Pratt
* License: MIT

Resources:

* http://blog.ackx.net/asm-hello-world-bootloader.html

Required to build (listed versions are tested):

* make 3.81
* Racket 6.9
* nasm 0.98.40
* Bochs x86 Emulator 2.6.8

Build
-----

```
$ make
racket metal.rkt < boot-hello.mtl > boot-hello.asm
nasm -f bin boot-hello.asm -o boot-hello.bin
rm boot-hello.asm
```

Run on Bochs
------------

Note that you may have to edit the paths in `bochsrc.txt`.

```
$ make run-bochs
echo 6 | bochs
========================================================================
                       Bochs x86 Emulator 2.6.8
                Built from SVN snapshot on May 3, 2015
                  Compiled on Apr 23 2017 at 19:28:52
========================================================================
00000000000i[      ] LTDL_LIBRARY_PATH not set. using compile time default '/opt/local/lib/bochs/plugins'
00000000000i[      ] BXSHARE not set. using compile time default '/opt/local/share/bochs'
00000000000i[      ] lt_dlhandle is 0x7f9e11c36380
00000000000i[PLUGIN] loaded plugin libbx_unmapped.so
00000000000i[      ] lt_dlhandle is 0x7f9e11c366a0
00000000000i[PLUGIN] loaded plugin libbx_biosdev.so
00000000000i[      ] lt_dlhandle is 0x7f9e11c36aa0
00000000000i[PLUGIN] loaded plugin libbx_speaker.so
00000000000i[      ] lt_dlhandle is 0x7f9e11c37270
00000000000i[PLUGIN] loaded plugin libbx_extfpuirq.so
00000000000i[      ] lt_dlhandle is 0x7f9e11c37710
00000000000i[PLUGIN] loaded plugin libbx_parallel.so
00000000000i[      ] lt_dlhandle is 0x7f9e11c38bb0
00000000000i[PLUGIN] loaded plugin libbx_serial.so
00000000000i[      ] reading configuration from bochsrc.txt
------------------------------
Bochs Configuration: Main Menu
------------------------------

This is the Bochs Configuration Interface, where you can describe the
machine that you want to simulate.  Bochs has already searched for a
configuration file (typically called bochsrc.txt) and loaded it if it
could be found.  When you are satisfied with the configuration, go
ahead and start the simulation.

You can also start bochs with the -q option to skip these menus.

1. Restore factory default configuration
2. Read options from...
3. Edit options
4. Save options to...
5. Restore the Bochs state from...
6. Begin simulation
7. Quit now

Please choose one: [6] 00000000000i[      ] lt_dlhandle is 0x7f9e11d03020
00000000000i[PLUGIN] loaded plugin libbx_sdl2.so
00000000000i[      ] installing sdl2 module as the Bochs GUI
00000000000i[SDL2  ] maximum host resolution: x=2880 y=1800
00000000000i[      ] using log file bochsout.txt
========================================================================
Bochs is exiting with the following message:
[SDL2  ] POWER button turned off.
========================================================================
make: *** [run] Error 1
```
