# Mega99

The Mega99 is a TI-99/4A core for the MEGA65 computer.  Currently only
r6 boards are supported.

The core is written from scratch specifically with the MEGA65 as its
target.  It tries to match the timing of the original TI-99/4A as
closely as possible, but also features a 36x turbo mode, where the
TMS9900 runs at 108 MHz.


## ROMs

In order for the Mega99 to work, the ROM chips inside must be loaded with
content from a real TI-99/4A.  These are not included with Mega99, but can
be found for example in distributions of MAME.  The ROM images must be placed
on a SD card inserted into the MEGA65 when the Mega99 core is started.
The ROM images can be loaded either from separate files, or from the same zip
archives that MAME uses.  Please consult the following table for the
correct file names of the ROM images and the respective zip files.

| ROM file         | Zip file        | Use          |
| ---------------- | --------------- | ------------ |
| 994a_rom_hb.u610 | ti99_4a.zip     | Console ROM  |
| 994a_rom_lb.u611 | ti99_4a.zip     | Console ROM  |
| 994a_grom0.u500  | ti99_4a.zip     | Console GROM |
| 994a_grom1.u501  | ti99_4a.zip     | Console GROM |
| 994a_grom2.u502  | ti99_4a.zip     | Console GROM |
| cd2325a.vsm      | ti99_speech.zip | Speech ROM   |
| cd2326a.vsm      | ti99_speech.zip | Speech ROM   |
| fdc_dsr.u26      | ti99_fdc.zip    | FDC DSR ROM  |
| fdc_dsr.u27      | ti99_fdc.zip    | FDC DSR ROM  |

In addition to these ROM images, the file `mega99sp.bin` should
also be placed on the SD card.  This is the main program for the service
processor, which handles ROM loading and the OSD menu.  It is possible to
run Mega99 without `mega99sp.bin`, but then many features become unavailable,
including all OSD functionality and the ability to load ROMs from zip files.


## Peripherals

### Keyboard

Alphanumeric keys and the space bar map directly from the MEGA65 keyboard
to their corresponding TI-99/4A key.  Other keys are mapped as indicated
by the following table:

| MEGA65 key  | TI-99/4A key | Service processor key    |
| ----------- | ------------ | ------------------------ |
| +           | = +          |                          |
| @           | / -          |                          |
| CTRL        | CTRL         |                          |
| CAPS LOCK   | ALPHA LOCK   |                          |
| : [         | ; :          |                          |
| RETURN      | ENTER        |                          |
| MEGA        | FCTN         |                          |
| SHIFT       | SHIFT        |                          |
| , <         | , <          |                          |
| . >         | . >          |                          |
| ←           |              | Enter top level menu     |
| RUN / STOP  |              | Leave menu               |
| HELP        |              | Toggle console messages  |
| NO SCROLL   |              | Toggle turbo on/off      |
| CAPS LOCK   |              | Hold for temporary turbo |

The OSD menus can be navigated with the arrow keys and RETURN.


### Joysticks

Atari style joysticks can be connected to the joystick ports of the
MEGA65.  There is currently no support for TI style double joystick
connectors.


### Cartridges

Cartridges are loaded from RPK files as used by MAME.  To insert a
cartridge, open the main menu and select "Load RPK", then choose the
RPK file to load.  Supported cartridge layouts are "standard", "paged"
and "minimem".


### Disk drive

The Mega99 includes a TI FDC card with three emulated drives.
To attach a disk image on SD card, open the main menu and select
"Mount DSK1 disk image" for DSK1, etc.  Then select the image file
to use.  The image file must either contain a valid Volume Information
Block (VIB), or have one of the following sizes:

| Image file size | Disk type       |
| --------------- | --------------- |
| 92160 bytes     | 40 tracks SS/SD |
| 184320 bytes    | 40 tracks SS/DD |
| 368640 bytes    | 40 tracks DS/DD |

Enabling the CPU turbo function also speeds up the disk drives by the
same amount.


### Cassette Tape

The Mega99 supports loading and saving to an emulated tape deck.
To load data from tape, use the following procedure:

 1. Start the tape load function in the relevant software (e.g.
    "OLD CS1" in TI BASIC).
 2. When the prompt "PRESS CASETTE PLAY THEN PRESS ENTER" appears,
    don't press ENTER yet but instead open the main menu.
 3. Select the "Open CS1 input file" option, and pick a file in
    the file selector.
 4. Exit the menu, and then press ENTER to proceed with the tape
    dialogue.
 5. The file should now be heard loading.
 6. When the prompt to "PRESS CASETTE STOP" appears, there is no
    need to do anything special, just press ENTER.

Either WAV files or raw tape data files can be used.  The latter
should contain the actual bytes written to tape starting with the
`>FF` data mark (the initial file sync of 768 `>00` bytes should
not be included, this is added automatically).

It is also possible to save to tape.  Just proceed through the complete
tape save process and the resulting data will be available in the
service processor's memory afterwards, from whence it can be saved
to SD card using the main menu.  Tape saves are always created as
raw tape data files.


### Mini memory

The 4K battery back-upped RAM of the Mini memory cartridge can be loaded
from, or stored to, SD card using the main memory.  Load the RPK first,
then the RAM memory file.


### Speech synthesizer

The speech synthesizer is included and functional.


# Running on Nexys A7

The core can also be used on a Nexys A7 or Nexys 4 DDR board.
Use the `mega99_nexys_a7_50t.bit` bitstream for Nexys A7 50T and
`mega99_nexys_a7_100t.bit` for Nexys A7 100T or Nexys 4 DDR.


### Keyboard

The following mappings are specific to the USB keyboard:

| USB key   | TI-99/4A key | Service processor key   |
| --------- | ------------ | ----------------------- |
| Left Ctrl | CTRL         |                         |
| Left Alt  | FCTN         |                         |
| Caps Lock | ALPHA LOCK   |                         |
| ` / §     |              | Enter top level menu    |
| ESC       |              | Leave menu              |
| SysRq     |              | Toggle console messages |
| Num Lock  |              | Toggle turbo on/off     |


### Joysticks

Atari style joysticks can be connected to PMOD connectors JA (joystick
1) and JB (joystick 2).  Like on the MEGA65, TI style dual joystick
connectors are currently not supported.

Pin mappings for the joystick connections:

| PMOD | DE9 | Joystick |
| ---- | --- | -------- |
| 1    | 1   | Up       |
| 2    | 2   | Down     |
| 3    | 3   | Left     |
| 4    | 4   | Right    |
| 8    | 6   | Fire     |
| 11   | 8   | Ground   |


# Ideas for future enhancements

* Load and save to real tapes might be possible using a 1531 datasette
  connected to the Expansion Board

* Reading and writing 3.5" floppies using the MEGA65 builtin floppy drive
  should be possible, but maybe not so useful considering TI-99/4A floppies
  are 5.25"?

* There could be a DSR to access the contents of the SD card directly
  (using [TIFILES](https://www.ninerpedia.org/wiki/TIFILES_format))


# Acknowledgments

* The VGA to HDMI IP was written by Adam Barnes

* Thierry Nouspikel's [TI-99/4A Tech Pages](http://www.unige.ch/medecine/nouspikel/ti99/titechpages.htm)
  has served as an invaluable resource in making this core

* Also instrumental was the Internet Archive for providing the full
  schematics of the TI-99/4A motherboard