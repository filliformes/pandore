# Pandore16 audio bringup

**Date:** November 6, 2026  
**Author:** Vincent  
**Board:** Pandore16, Rev A0, with the ISO7761 rework

This bring-up was done after the audio hardware correction with Laurence on
Nov. 5, 2026, which addresses [ERR-002](../../errata/rev-a0-errata.md).

## Status

**Audio works, but it is not usable yet.** The headphones play sound, but it is
heavily bitcrushed with a steady ringing tone, and the TRS jacks are silent.
The next step is to short C97. As of this writing, that has not been done.

## Hardware state

The ISO7762 (U23) was deliberately replaced by an ISO7761 (marking
`7761 59T A2ETG4`) on a small add-on PCB. Its codec-side row matches header
EXP9 pin for pin. CL and DA are not wired on the Teensy side, and I²C still uses
the main board's ISO1640.

| Teensy pin | Pad | Function | ISO7761 direction |
|---|---|---|---|
| IO23 | MK | MCLK, U11 pin 3 | Teensy → codec |
| IO22 | RS | codec ~RST | Teensy → codec |
| IO21 | CK | bit clock, U11 pin 5 | Teensy → codec |
| IO20 | FS | word clock, U11 pin 4 | Teensy → codec |
| IO7 | TX | SDIN, U11 pin 7 | Teensy → codec |
| IO8 | RX | SDOUT, U11 pin 6 | codec → Teensy (the only one) |

This table was traced from photos, so continuity has not been measured. The TX
and IO8 joints look rough.

## Likely cause

- **Clock conflict:** with this add-on, the Teensy has to generate the clocks,
  with the codec as slave. But crystal X5 is still fitted, so the codec's MCLK
  pin is still an output while the isolator drives MK into it.
- **Mismatched clocks:** the 48 kHz stopgap firmware lets the Teensy and X5 run
  independently, so it can never be clean.

## Confirmed

| Finding | Evidence |
|---|---|
| The daemon and RP2350s are not involved | No audio code beyond the flash target, and the RP2350s have no audio nets |
| Codec and X5 are alive | In master mode, IO8 toggles at about 290–350 kHz, and stops and resumes with power-down and reset |
| Reset path works | IO22 low gives an I²C NAK, stops data and wipes registers |
| BCLK and LRCK reach the codec | As slave with software clocks at 48 kHz, it outputs correctly framed data, and only with both clocks present |
| USB path is clean at 48 kHz | Loopback sine: 388,983 frames, 0 wrong, 0 slips (does not cover Teensy → DAC) |
| DAC path passes signal | Instrument is audible on headphones |
| Input path is live | Low-level noise instead of exact zeros, plus small peaks near 529, 1057 and 1586 Hz at about −91 dB, not yet linked to the tone |

## Not proven

- **Silent TRS jacks:** probably the codec's mute being active because the
  MCLK/LRCK ratio is wrong, but this has not been measured.
- **Bitcrushing:** probably the clock mismatch and/or MCLK conflict. USB and
  volume are ruled out, but the IO7/TX line is not, and its joint looks rough.
- **IO23 behaviour:** holding it low stops the codec, while holding it high does
  nothing. The difference is not explained yet.
- **Add-on board wiring:** traced from photos, as noted above.

## Next steps

1. **Hardware, with the power off:** short C97 (12 pF, 0402, between XTI and
   AVSS, right beside the add-on board's edge) and reflow the TX joint. X5 stays
   fitted for now, which goes against the datasheet's "no crystal" guidance. This
   is a judgment call: if the codec misbehaves, removing X5 means lifting the
   add-on board.
2. **Firmware:** have the Teensy drive MCLK, keep the codec as slave and in reset
   until the clocks are stable, and go back to 44.1 kHz.
3. **Check the result:** word clock on serial, signal on the input, meter moving,
   TRS playing, no bitcrushing.
4. **If problems remain:**
   - **Still bitcrushed:** test the IO7/TX line.
   - **Tone still there:** mute the DAC (PGM 122 on channel 16) while listening,
     to tell whether it comes from the DAC or from analog pickup.
5. **Docs:** update the firmware docs, which still describe the board before the
   rework, and record the rework in the errata.

## Until then

- **Firmware:** the 48 kHz stopgap is on branch `audio-48k-stopgap` of the
  firmware repo, with uncommitted changes. Flash it with
  `pio run -e teensy41_48k -t upload`. A plain `pio run -t upload` or
  `tools/flash-firmware.sh` flashes the old master-mode firmware, which fights
  the isolator.
- **Power:** keep the unit off when idle, because the isolator is still fighting
  the codec's MCLK pin.
- **Levels:** after the fix the codec is clocked differently, so turn the output
  down first and raise it gradually. Test tones bypass all volume, and Res listens
  to the live input, so feedback is possible.
