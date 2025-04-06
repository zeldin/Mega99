v1.0 (2024-10-18)
=================

Initial release


v1.1 (2024-10-20)
=================

* Bootloader errors are shown as text instead of hexadecimal numbers

* Drive LED is functional

* Allows internal SDcard to be used in addition to external SDcard

* Looks for ROMs and mega99sp.bin in a MEGA99 directory if it exists


v1.2 (2024-10-27)
=================

* Supports RPKs with the "mbx" pcb type

* Last visited directory in each file selector is remembered



v1.3 (2024-11-05)
=================

* Supports MEGA65 R3(A)

* Embeds mega99sp.bin in the core file

* TAB on the keyboard enables pseudkeys mode, which remaps
  keys according to the symbols on the keycaps



v1.4 (2024-12-01)
=================

* New updated pseudo-key mapping for non-printing keys

* Console hotkey moved from HELP to ALT, to allow HELP to work
  as AID (FCTN-7)

* It is now possible to retain last visited directory for different
  fileselectors on different SDcards (internal or external)

* HDMI timing tweaked to have 480 active lines instead of 486

* Peripherals can now be disabled from the new Settings menu

* Joystick 1 and 2 can be swapped from the Settings menu



v1.5 (2025-01-19)
=================

* RPK formats "paged377", "paged378" and "paged379i" now supported

* Fixed a bug where loaded GROMs from RPKs could become garbled if
  inter-GROM "garbage" was not canonically encoded in the dumps

* Physical reset button now supported also on MEGA65 R3

* Turbo mode is now indicated by a blue power LED

* Fixed an SDcard detection bug

* Adjusted the buffer low level of the Speech synthesizer to fix
  garbled speech in Don't mess with Texas


v1.6 (2025-04-06)
=================

* Add support for TIPI, either with RaspberryPi hardware or
  builtin emulation (restricted to simple program loading for now)

* Fixed non-working joystick port 2 on MEGA65 R6
