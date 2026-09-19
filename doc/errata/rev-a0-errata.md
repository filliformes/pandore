# Pandore Rev A0 — Errata

Known hardware issues in revision A0. Each entry records the symptom, the
evidence it was confirmed from, any workaround, and the fix for the next
revision.

| ID | Subsystem | Severity | Status |
|----|-----------|----------|--------|
| [ERR-001](#err-001--cs4272-i²c-sdascl-crossed-between-isolator-and-codec) | Audio / codec control | **Blocking** — codec unreachable over I²C | Open, software workaround available |
| [ERR-002](#err-002--teensycodec-i²s-signals-rotated-across-the-isolator) | Audio / I²S data path | **Blocking** — no audio in either direction | Open, hardware rework required |

---

## ERR-001 — CS4272 I²C SDA/SCL crossed between isolator and codec

**Subsystem:** Audio — codec control port
**Severity:** Blocking. The CS4272 cannot be configured over I²C at all.
**Affects:** Revision A0, all three boards.
**Status:** Open, root cause **confirmed by the designer** (Laurence, 2026-09-02).
Software workaround available for the Teensy; no rework required for it.
**The host path is not equally recoverable** - see "Effect on the LattePanda Mu" below.

### Symptom

The Teensy 4.1 never detects the CS4272. Any I²C transaction to address
`0x10` fails to receive an ACK — `Wire.endTransmission()` returns non-zero,
an address scan finds nothing at `0x10`, and firmware that gates on codec
presence takes its "codec absent" path.

Because the codec is never taken out of power-down and never configured,
there is no I²S audio in either direction, even though the I²S clock and
data lines themselves are wired correctly.

### Root cause

`SDA` and `SCL` are transposed on the isolated (codec) side of the
`ISO1640BDR` I²C isolator (`U24`). The isolator's `SDA2` output lands on
the codec's `SCL` pin, and `SCL2` lands on the codec's `SDA` pin:

```
Teensy IO18 (SDA) ─ AUDMST.SDA ─ U24.2 SDA1 ─[ISO1640]─ U24.7 SDA2 ─ CTL.SDA ─ U11 pin 11 = SCL   <-- wrong
Teensy IO19 (SCL) ─ AUDMST.SCL ─ U24.3 SCL1 ─[ISO1640]─ U24.6 SCL2 ─ CTL.SCL ─ U11 pin 12 = SDA   <-- wrong
```

The net *names* (`CTL.SDA`, `CTL.SCL`) are correct with respect to the
isolator, which is why the error is easy to miss reading the schematic —
the mistake is in which codec pin each net attaches to.

The host side of the isolator is correct: `AUDMST.SDA` → `SDA1`,
`AUDMST.SCL` → `SCL1`. The LattePanda Mu's `I2C2` (`U1.156` / `U1.154`)
shares this bus and is likewise correct up to the isolator. Only the
codec-side attachment is transposed.

### Evidence

Confirmed from the Rev A0 netlist, cross-checked against an independent
CS4272 reference design.

Net membership, from `hw/pandore.kicad_pcb` per-pad net assignments:

| Net | Nodes |
|---|---|
| `/Audio/CODEC/CTL.SDA` | `U24.7 (SDA2)`, **`U11.11 (SCL)`**, `EXP8.2`, `R166` (2.2 kΩ pull-up) |
| `/Audio/CODEC/CTL.SCL` | `U24.6 (SCL2)`, **`U11.12 (SDA)`**, `EXP8.1`, `R167` (2.2 kΩ pull-up) |
| `/Audio/AUDMST.SDA` | `U9.40 (Teensy I2C0.SDA = IO18)`, `U24.2 (SDA1)`, `U1.156`, `R164` |
| `/Audio/AUDMST.SCL` | `U9.41 (Teensy I2C0.SCL = IO19)`, `U24.3 (SCL1)`, `U1.154`, `R165` |

CS4272 pinout verified independently of the project's own symbol library,
from `doc/reference/SuperAudioBoard_Schematic.pdf` (RF William Hollender,
a separate CS4272 design):

```
SCL | 11        AD0   | 13
SDA | 12        RST_N | 14
```

This matches the `reekilib` symbol's pin functions, so both the CS4272 and
ISO1640 symbols are correct — the error is in the connections, not the
library.

> **Confirmed by the board's designer.** Laurence Deschênes Villeneuve
> confirmed on 2026-09-02 that the CS4272's SDA and SCL pins were
> transposed in the Rev A0 design. This entry is therefore no longer a
> netlist-derived hypothesis: the root cause is established.
>
> A bench check is still worth doing once before rework, to confirm the
> board matches the design: probe `EXP8` pins 1 and 2 while the Teensy runs
> an I²C scan. The pin carrying the clock square wave should be the one
> routed to codec pin 12.

### Effect on the LattePanda Mu (host) path

`AUDMST` is shared: the Mu's `I2C2` (`U1.154` / `U1.156`) sits on the same
segment as the Teensy, and both cross `U24` to reach the codec. So the
transposition affects the host exactly as it affects the Teensy.

The difference is what each can do about it:

- **Teensy:** bit-bangs the bus, so it can simply swap the pin roles in
  software (Workaround A). No rework.
- **LattePanda Mu:** if it drives the codec through the **SerialIO I2C2
  hardware controller**, the roles cannot be swapped. A hardware I²C master
  will not work with SCL and SDA exchanged. The host would need either the
  hardware bodge (Workaround B), or to drive those two pins as GPIO and
  bit-bang (`i2c-gpio` on Linux), which depends on the pins being exposed
  as GPIO rather than owned by the I2C2 controller.

**Consequence for the BIOS request:** item 3.1.5 (release `I2C2` from its
PD-controller reservation) is still worth asking for, and remains a
one-shot opportunity, but on Rev A0 it will not by itself give the host a
working codec link. Do not report a failed host-to-codec I²C test to
LattePanda as a BIOS fault; it is this errata. (The BIOS customization
request itself lives in the private software repo, not here.)

### Workaround A — software, no rework (recommended)

`U24` is an **ISO1640BDR**, which is bidirectional on *both* channels
(unlike the ISO1641, whose SCL is unidirectional). It passes logic levels
without interpreting the protocol, so it does not care which line carries
clock and which carries data.

On this board, physically:

- **Teensy `IO18` reaches the codec's SCL**
- **Teensy `IO19` reaches the codec's SDA**

A bit-banged I²C master with the pin roles reversed (`SCL = 18`,
`SDA = 19`) therefore talks to the codec correctly with no hardware
change. The Teensy 4.1's LPI2C pin mux fixes `Wire` to `18 = SDA` /
`19 = SCL`, so the stock `Wire` library cannot express the swap; a
software I²C implementation that takes explicit pins can.

Pull-ups are already present on both sides of the isolator (`R164`/`R165`
host side, `R166`/`R167` codec side, 2.2 kΩ), so no additional components
are needed. Drive the lines open-drain only — pull low, release high,
never drive high — as the isolator requires.

### Workaround B — hardware bodge

`EXP8` is a populated 2-pin header (`PH1-02-UA`, labelled `I2C`) sitting
directly on `CTL.SDA` (pin 2) and `CTL.SCL` (pin 1) — the codec side of
the isolator. It is the most accessible point on the two affected nets, so
cutting the two traces and cross-strapping at `EXP8` is preferable to
scraping traces at the codec's fine-pitch package.

Only do this if the software workaround is unsuitable; it permanently
diverges the board from the schematic.

### Fix for Rev B

In `hw/pandore-audio-isolation.kicad_sch` / `hw/pandore-audio-codec.kicad_sch`,
swap the codec-side attachment so that:

- `CTL.SCL` (isolator `SCL2`) connects to `U11` pin **11** (SCL)
- `CTL.SDA` (isolator `SDA2`) connects to `U11` pin **12** (SDA)

Add an ERC/review check that each I²C net terminates on a pin of matching
function at both ends. The net names were correct throughout, so a
name-based review would not have caught this — the check has to compare
against pin function.

---

## ERR-002 — Teensy↔codec I²S signals rotated across the isolator

**Subsystem:** Audio — I²S data path (MCU ↔ codec)
**Severity:** Blocking. No audio can pass in either direction — playback *or* capture.
**Affects:** Revision A0 (schematic-level — every board).
**Status:** Open. No software workaround; hardware rework required.

### Symptom

The line-out is silent and capture returns garbage, while the codec itself
measures completely healthy: it is detected and configured over I²C, runs as
I²S/clock master off its 24.576 MHz crystal at exactly 48 kHz, its references
are correct, and its output amplifiers are enabled.

### Root cause

The I²S signals between the Teensy (`U9`) and the CS4272 (`U11`) cross the
`ISO7762` isolator (`U23`, hex unidirectional 4:2) through four 0 Ω quad arrays
(`R168`, `R169`, `R170`, `R171` — Yageo `YC124-JR-070RL`). The YC124 pairs its
elements **1↔8, 2↔7, 3↔6, 4↔5**, and the connections were made as though the
ordering were different, so the signal assignment comes out rotated:

| Teensy pin | Actually connected to | Should be | |
|---|---|---|---|
| IO21 (BCLK in)    | codec **MCLK** (24.576 MHz)     | codec SCLK    | ✗ |
| IO20 (LRCK in)    | codec **LRCK**                  | codec LRCK    | ✓ |
| IO8 (RX data in)  | codec **SCLK**                  | codec SDOUT   | ✗ |
| IO7 (TX data out) | codec **SDOUT** (output↔output) | → codec SDIN  | ✗ |
| IO23 (MCLK)       | drives codec **SDIN**           | codec MCLK in | ✗ |
| IO22 (~RST)       | codec ~RST                      | codec ~RST    | ✓ |

Only **LRCK** and **~RST** land correctly. Two consequences are independently
fatal: the Teensy's audio output (`IO7`) is tied to the codec's `SDOUT` — an
output driving an output, with no path to `SDIN` — and the codec's `SDIN` is
instead driven from the Teensy's `MCLK` pin, which the audio library never even
configures in slave mode, so it sits high-impedance and `SDIN` is static.

The isolator channel *directions* are right for a codec-master board: `ISO7762`
provides four channels codec→MCU (`A`–`D`: SDOUT, SCLK, LRCK, MCLK) plus two
MCU→codec (`E`, `F`). `F` correctly carries `~RST`. `E` is the one channel that
should carry playback data to `SDIN`, and it is fed from the wrong Teensy pin.

### Evidence

- **The codec reports it is receiving nothing.** With Auto-Mute enabled
  (`reg 02h` bit 7) the CS4272 drives MUTEC active after 8192 consecutive zero
  samples and releases it on a single non-zero sample (datasheet §5.5). MUTEC
  gates the THS4521 output amplifiers, so the amps audibly drop in and out with
  real data. They never changed state regardless of signal — `SDIN` is
  permanently static.
- **Capture proves which signal is on the data pin.** A recording contains only
  the constant value `0x1E1E` — a repeating 4-high/4-low bit pattern. That is a
  square wave sampled at an exact **8:1** ratio, i.e. a **3.072 MHz SCLK**
  latched by a **24.576 MHz** bit clock (24.576 / 3.072 = 8). The Teensy's bit
  clock is the codec's MCLK and its data pin carries the codec's SCLK.
- **The frame rate is nevertheless correct** — firmware block-rate measurement
  reads exactly **48000 Hz**, because LRCK is the one clock wired correctly.
  This also confirms the YC124 1↔8/2↔7/3↔6/4↔5 pairing: the alternative pairing
  cannot produce either the 48 kHz frame rate or the 8:1 pattern.
- **Direct measurement of each pin, independent of all of the above.** The
  `audio/bringup/i2s_pinprobe` sketch (software repo) uses no Audio library and
  makes no assumption about the codec beyond putting it in master mode; it just
  counts GPIO edges. Measured with the codec free-running:

  | Teensy pin | measured | correct wiring would give |
  |------------|----------|---------------------------|
  | IO21 (BCLK in)    | ~24.576 MHz (at sampler limit) | 3.072 MHz |
  | IO20 (LRCK in)    | 48.0 kHz exactly               | 48 kHz ✓ |
  | IO8 (RX data in)  | 3072.2 kHz — a clean clock     | aperiodic data |
  | IO7 (TX data out) | 200-330 kHz, varying           | idle |
  | IO23 (MCLK in)    | 0 Hz — dead                    | 24.576 MHz |

  `3072.2 kHz` is 64 x 48000 to four digits and IO20 is exact, so the
  measurement is sound. IO7 varying run to run is data, not a clock.

Healthy and ruled out along the way: I²C configuration and register readback;
codec master-mode clocking from crystal `X5`; `FILT+` = 4.9 V (≈VA) and `VQ` =
2.5 V (≈VA/2); `VCMMON` = 2.5 V; MUTEC polarity and the THS4521 `PD` wiring,
which are **correct** (MUTEC is active-low per datasheet §5.5/§8.5.1). Note that
`chip ID` register `08h` reading `0x00` is normal for the CS4272.

### Workaround — none in software

The SAI peripheral's signals are fixed to specific pads, so the Teensy cannot be
told to take its bit clock or data from the pins the board actually delivers
them on.

### Hardware bodge

`R168` and `R169` are **0 Ω** arrays, so removing them cleanly breaks every
incorrect connection at once and leaves accessible pads to jumper from. Lift
both, then wire six links:

```
U23 OUTA (codec SDOUT) -> Teensy IO8    (RX data)
U23 OUTB (codec SCLK)  -> Teensy IO21   (BCLK)
U23 OUTC (codec LRCK)  -> Teensy IO20   (LRCK)
U23 OUTD (codec MCLK)  -> Teensy IO23   (MCLK, optional in slave mode)
Teensy IO7 (TX data)   -> U23 INE       (-> OUTE -> R163 -> codec SDIN)
Teensy IO22 (~RST)     -> U23 INF       (already correct — keep)
```

This is preferable to cutting traces or lifting the codec's 0.65 mm pins: the
array pads are larger and every wrong net is removed in one step.

### Fix for Rev B

Re-map the isolator connections against the **YC124 1↔8 / 2↔7 / 3↔6 / 4↔5**
element pairing, and route the Teensy's I²S **TX data** (not its MCLK) into the
MCU→codec channel that feeds `SDIN`.

As with ERR-001 the net names all read plausibly, so a name-based review does not
catch this. The check has to verify, per net, that the *pin function* at each end
matches **and** that signal direction is consistent with the isolator channel
direction — here an output (`IO7`) was connected to a channel output, which an
ERC configured for pin-type conflicts across the array would have flagged.
