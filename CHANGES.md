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
