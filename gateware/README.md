# Gateware quirks

This document contains some notes on the peculiarities of the gateware
that may be good to know if reusing these modules.

## TMS9900

### Memory bus timing

In order to simplify the interaction between the TMS9900 and perpherals
when implementing in an FPGA, some changes have been made to the bus
protocol.

- MEMEN_out is asserted until the first clk cycle (regardles of clk_en)
  where READY_in is also asserted.  This is counted as completion of the
  bus cycle.  MEMEN_out is guaranteed to be deasserted during the next
  clk cycle.

- For a read cycle, D_in is expected to hold the resulting data the
  clk cycle (again disregarding clk_en) _after_ the completion of the
  bus cycle, i.e. the first cycle in whch READY_in is deasserted.  There
  is no additional hold requirement, the data needs to be valid for this
  clk cycle only.

- A, IAQ, WE and DBIN are guaranteed to remain valid at least for the
  first clk cycle after completion, i.e. the cycle in which D_in is
  expected to be valid.


## TMS9918

Unlike a real TMS9918, memory accesses do not need any delay.  A new
memory access can be started every second clk, and the TMS9900 can't
make them faster than that anyway, even in turbo mode.

### Video timing

The native video timing of a TMS9918 with a 10.738635 MHz oscillator
is as follows:

- Pixel clock: 5.3693175 MHz
- Horizontal:  284 active pixels, 342 total pixels, 15.699759 kHz sweep
- Vertical:    243 active lines,  262 total lines,  59.922743 Hz sweep

If this is scan doubled, and the pixels repeated twice, it becomes

- Pixel clock: 21.47727 MHz
- Horizontal:  568 active pixels, 684 total pixels, 31.399518 kHz sweep
- Vertical:    486 active lines,  524 total lines,  59.922743 Hz sweep

This is close enough to a normal 640x480@60 signal that VGA displays
are likely to accept it.  However, it is not good enough for HDMI.
If each pixel is repeated 2.5 times instead, the timing becomes:

- Pixel clock: 26.8465875 MHz
- Horizontal:  710 active pixels, 855 total pixels, 31.399518 kHz sweep
- Vertical:    486 active lines,  524 total lines,  59.922743 Hz sweep

This is quite close to a standard 480p60 HDMI signal, but notably the
number of active horizontal pixels are 10 too few (should be 720).
There are also 6 too many active lines, but this is less likely to
cause an issue as the display can just treat the extra lines as
overscan.  Finally the pixel clock, while not technically illegal
(pixel clocks down to 25 MHz are allowed by HDMI), falls slightly
short of the nominal 27 MHz pixel clock used for SD resolutions.

By setting the parameter ENABLE_HDMI_TIMING_TWEAKS to 1, the TMS9918
video timing is tweaked slightly to help with this situation.  What
it does is to add 2 more pixels of horizontal border on each side,
and remove 2 pixels of blanking on the right side, making each line
2 pixels longer in total.  It also reduces the size of the top border
by 3 lines (adding 3 more lines of bottom blanking instead), making
it the same size as the bottom border.  Combined with increasing the
oscillator frequency to 10.8 MHz, the native timing becomes:

- Pixel clock: 5.4 MHz
- Horizontal:  288 active pixels, 344 total pixels, 15.697674 kHz sweep
- Vertical:    240 active lines,  262 total lines,  59.914788 Hz sweep

While the pixel clock rate has been increased by 0.6%, the sweep rates
have been decreased by only 0.013% (130 ppm), so software is unlikely
to notice any difference (there are about 7 more CPU clocks per frame
/ VDP interrupt, in non-turbo mode).  The TMS9918 datasheet specifies
a tolerance of +-50 ppm for the oscillator, which is in the same order
of magnitude.

The HDMI timing with scan doubling and 2.5 times pixel repetition then
becomes:

- Pixel Clock:  27.0 MHz
- Horizontal:   720 active pixels, 860 total pixels, 31.395348 kHz sweep
- Verical:      480 active lines,  524 total lines,  59.914788 Hz sweep

This is good enough that most HDMI displays will accept it.


## TMS5200

The speech synthesis chip is implemented very closely based on the
schematics in the patent (US4335277A).  Only one clock phase is used
however, which is rougly equivalent to phi4 in the schematics.  In
some cases a signal is given a name ending with `_pre` to signify that
it corresponds to a signal latched on phi3 in the schematics instead.

There are a few places where there is a functional difference between
this implementation and the patent:

- In the patent, `LDP` is asserted on `T1` for `PC=1`.  This causes 6
  bits of data to be loaded, which matches the length of the pitch
  parameter.  However, during `T16` of `PC=1` the `RPT` parameter
  should also be latched, so the total number of bits to load needs to
  be 7.  The timing of `LDP` has been adjusted accordingly.

- In the patent, the `TALKST` signal depends only on `TALKD` and `SPEN`.
  This caused a race condition during talk start, so this implementation
  asserts `TALKST` also when `TCON` is asserted.  Also, `TCON` is used in
  place of `TALK` when computing the `EN` signal.

- This implementation sets the `CMD` register to 0 (NOP) whenever a
  command completes.  This prevents talk commands from automatically
  reactivating once the talk operation has been completed.

- The FIFO described in the patent refills by moving bytes downwards
  one by one in a "bubble sort" fashion.  This means it takes 15 `T`
  cycles for the data to propagate when a byte is removed from a full
  FIFO.  This is not a problem, since there are at least 20 `T` cycles
  before a new byte will be requested again (there is no data fetched
  during "A" cycles, and each "B" cycle consumes less than one byte).
  But the design does cause the `BL` signal to glitch when the FIFO is
  initially filled, and the data entries "fall" past the halfway
  point.  By adding another mux per slot, the entries are able to
  immediately move to their correct position in a single cycle in this
  implementation, removing any glitches in the status signals.

