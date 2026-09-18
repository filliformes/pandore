# Pandore Rev A0 — Errata

Known hardware issues in revision A0. Each entry records the symptom, the
evidence it was confirmed from, any workaround, and the fix for the next
revision.

| ID | Subsystem | Severity | Status |
|----|-----------|----------|--------|
| [ERR-001](#err-001--cs4272-i²c-sdascl-crossed-between-isolator-and-codec) | Audio / codec control | **Blocking** — codec unreachable over I²C | Open, software workaround available |

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
