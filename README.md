# Pandore

![Pandore A0](doc/img/pandore_A0_topiso.png)

**Open-source digital audio instrument prototyping platform.**

Pandore is a custom-designed PCB built around the [LattePanda Mu](https://www.lattepanda.com/lattepanda-mu) compute module, a [Teensy 4.1](https://www.pjrc.com/store/teensy41.html) audio bridge, dual [RP2350](https://www.raspberrypi.com/products/rp2350/) microcontrollers, and a professional audio I/O chain. It provides a complete hardware foundation for building digital audio instruments, effects processors, and experimental sound tools.

## Status

**Revision A0** — PCBA complete at PCBWay (3 units); hand-assembly of the through-hole/DNP parts and board bring-up in progress. Manufacturing files released 2026-03-19; DRC passing. See the [interactive BOM](hw/bom/ibom.html) and the [A0 bring-up / hand-assembly guide](doc/test/bringup/pandore_a0_bringup.md).

> **PCBWay substitution:** RP2350A was unavailable at assembly time; PCBWay substituted **RP2350B (QFN-80)** for both MCU positions. RP2350A and RP2350B are binary-compatible — same cores, same peripherals, same memory map — they differ only in package size and number of exposed GPIO pins (30 vs 48). Firmware developed on RP2350A Pico boards transfers without modification.

## Board Specifications

| Parameter | Value |
|---|---|
| **Dimensions** | 260 mm x 110 mm |
| **Layers** | 4 (F.Cu / In1 / In2 / B.Cu) |
| **Components** | 804 (141 unique part numbers) |
| **Vias** | 2,217 |
| **Design tool** | KiCad 10 |

## Architecture

```
                         +-----------------+
                         |  LattePanda Mu  |
                         |  (x86-64 SBC)   |
                         +--------+--------+
                                  |
          +----------+-----------+-----------+----------+
          |          |                       |          |
 +--------+-------+  |             +---------+--------+ |
 |  RTIO MCU      |  |             |  Management MCU  | |
 |  (RP2350)      |  |             |  (RP2350)        | |
 +--------+-------+  |             +---------+--------+ |
          |          |                       |          |
 +--------+-------+  |             +---------+--------+ |
 | UART, SPI, I2C |  |             | GPIO, Power Seq, | |
 | ADC, 8x PWM    |  |             | Fan, Display     | |
 +----------------+  |             +------------------+ |
                     |                                  |
            +--------+--------+                         |
            |   Teensy 4.1    |                         |
            | (I2S-to-USB     |                         |
            |  Audio Bridge)  |                         |
            +--------+--------+                         |
                     |                                  |
            +--------+--------+               +---------+--------+
            |   CS4272 Codec  |               |   Boot, BIOS,    |
            |   (24-bit I2S)  |               |   Ethernet, M.2  |
            +-----------------+               +------------------+
```

### Compute

- **LattePanda Mu** — x86-64 SBC (Intel N100 or N305), main application processor. Recommended: DFR1147 (N100, 16 GB LPDDR5) — the N305 gives only ~13% single-core gain at ~2× cost, with no meaningful benefit for real-time audio workloads where single-thread performance dominates.
- **RTIO MCU (RP2350)** — Real-time I/O: UART, SPI, I2C, USB, ADC, 8x PWM channels
- **Management MCU (RP2350)** — System control: power sequencing, GPIO, fan, display, boot

### Audio

- **Audio/MIDI bridge:** [Teensy 4.1](https://www.pjrc.com/store/teensy41.html) — I2S-to-USB audio bridge between the CS4272 codec and the LattePanda Mu, also handles MIDI data transfer to the host computer
- **Codec:** Cirrus Logic CS4272 — stereo 24-bit ADC/DAC, I2S interface
- **Preamp:** THS4521 fully-differential amplifier + OPA1656 op-amp signal conditioning
- **Phantom power:** 48V supply via TI LM5158 flyback controller + TPS7A4001 ultra-low-noise 40V LDO post-regulation (~10 mA) for condenser microphones
- **I2S isolation:** TI ISO7762FDBQR — 6-channel digital isolator (4 forward / 2 reverse), 100 Mbps, 5000 VRMS galvanic isolation between digital and audio domains
- **I2C isolation:** TI ISO1640BDR — isolated I2C for codec control path, 2500 VRMS isolation
- **Isolated power:** Murata NXE2S1212MC-R7 — 2W isolated 12V→12V DC/DC converter (167 mA) for the isolated audio domain
- **MIDI isolation:** Isocom H11L1SMT optoisolator with Schmitt-trigger output on MIDI IN
- **Monitor output:** Dedicated headphone/speaker amplifier with hardware volume knob (Bourns PTR902-2020K-A103 — 10 kΩ audio taper, 20 mm shaft)
- **Input buffering:** Balanced input stage with line/mic switching
- **Output buffering:** Line-level outputs

### Power

| Rail | Voltage | Current | Purpose |
|---|---|---|---|
| 12V | Main input | LattePanda Mu, OLED drive |
| 5V | 2A (10W) | Digital logic, USB peripherals |
| 3.3V | 3A (10W) | MCUs, codec digital, I/O |
| 48V | 10 mA | Condenser microphone phantom power |
| AV5 / AV3P3 | — | Analog audio supply (isolated domain) |
| VSTBY | ~3.3V | Standby (CR2032 backup) |

**Power ICs:**

| Part | Role |
|---|---|
| Diodes AP63356Q (×2) | Synchronous buck converters (3.5A), main DC-DC regulation |
| STM LDL212DR (×3) | Ultra-low-dropout LDOs, local clean rails |
| ETEK ET20162 (×5) | USB VBUS current-limit load switches, 1A fixed each (U29–U32 = 4 USB-A ports, U33 = Teensy USB host) |
| TI LM5158RTER | Flyback controller for 48V phantom supply |
| TI TPS7A4001DGNR | Ultra-low-noise 40V LDO, phantom post-regulation |
| Murata NXE2S1212MC-R7 | 2W isolated 12V DC/DC (167 mA) for audio analog domain |

- Reverse-polarity, overcurrent, and overvoltage protection
- USB VBUS overcurrent handled by the ET20162 load switches (1A fixed limit each)
- PTC fuses (Bel Fuse 0ZCM0010FF2G, 0.1A) protect the **Grove ports** (J17/J18) on the standby rail
- Managed power-on sequencing via Management MCU

### Connectivity

- **Ethernet** — 2× Gigabit Ethernet via Realtek RTL8111H-CG PCIe controllers (U7, U8), 2× shielded RJ45 with isolation transformers (Würth 749020111A)
- **USB** — 4× USB-A ports (2× USB 3.0 via J3 + 2× USB 2.0 via J2) broken out from the LattePanda Mu's 8 USB lanes (remaining lanes are internal — Teensy audio bridge, AX210 WiFi/BT); plus the Teensy 4.1's own USB-C jack exposed at the back panel
- **MIDI** — 5-pin DIN IN/OUT with H11L1 optoisolation
- **Display** — 24-pin 0.5mm FPC ZIF connector (GCT FFC2A32-24-T) for OLED status display (SSD1309, 128×64 px, 1.54") — see [Components Requiring Separate Assembly](#components-requiring-separate-assembly)
- **M.2 Key-M** — PCIe x4 (NVMe SSD)
- **M.2 Key-A+E** — WiFi/Bluetooth (tested: Intel AX210 — WiFi 6E tri-band + BT 5.3) or alternate storage
- **Expansion headers** — GPIO, analog, I/O breakouts; 2× **Grove I2C connectors (3.3V, use Qwiic / STEMMA QT sensors — see below)**; I2S header; UART debug

### User Interface

- **Encoder:** Bourns PEL12T-4225T-S1024 — 24 PPR optical rotary encoder with momentary push switch and RGB LED illumination
- **Tactile switches:** 4× C&K PTS810 momentary switches (B1–B4)
- **Volume knob:** Bourns PTR902-2020K-A103 potentiometer — 10 kΩ audio taper, 20 mm shaft (monitor output level; replaces BOM part 2015K-B103, linear, 15 mm)
- **RGBA LED:** AMS-OSRAM multi-colour LEDs — blue (×3), green (×4), orange (×7), red (×1) status/indicator outputs

### Sensors

- **BMI270** — 6-axis IMU (accelerometer + gyroscope) for motion-based control

#### External sensor expansion (Grove ports)

The two Grove connectors (J17/J18) are **I2C sensor ports running at 3.3V** — each on its own management-MCU I2C bus (J17 = I2C0, J18 = I2C1), powered from the standby rail through a 0.1A PTC fuse.

Because the ports are 3.3V, use the **Qwiic / STEMMA QT** sensor ecosystem (SparkFun, Adafruit, Arduino Modulino) — it is 3.3V-native, so modules plug in safely with no level shifting. A standard **Grove-to-Qwiic adapter cable** (Adafruit #4528 or SparkFun PRT-15109) connects them. *Note: M5Stack Units are powered at 5V and are not directly compatible.*

### Flash Storage

3× Winbond W25Q128JVSIM (128 Mbit / 16 MB, QSPI):
- U2 — BIOS flash (LattePanda Mu)
- U5 — RTIO MCU flash (RP2350, U3)
- U6 — Management MCU flash (RP2350, U4)

### Thermal

- 2× 4-pin PWM fan headers (J27 CPU, J38 system), Molex KK 254 47053-1000
- **Fan header pinout: 1=GND, 2=5V, 3=Tach, 4=PWM** (fed directly from the 5V rail — note: 5V, not the 12V of a standard PC fan header)
- PWM-controlled fan driver circuit
- Three heatsink options: active cooler (DFRobot FIT0981, 5V fan), thin passive, fanless

## Audio Performance

See **[Audio Performance](AUDIO_PERFORMANCE.md)** for the full signal chain, component specs, system-level estimates, physical I/O, and performance class.

**Highlights:** 24-bit / 192 kHz, 114 dB dynamic range, -100 dB THD+N, 5000 VRMS galvanic isolation, 2× Neutrik combo XLR+TRS inputs with 48V phantom power.

## Repository Structure

```
pandore/
  hw/               Schematics (.kicad_sch) and PCB layout (.kicad_pcb)
  doc/
    arch/           Architecture diagrams (draw.io)
    img/            Board renders
    reference/      Datasheets, app notes, design guides (PDF)
  lib/              3D models (.step), KiCad symbols and footprints
  release/          Manufacturing artifacts (Gerbers, BOM, placement, 3D)
```

### Schematic Hierarchy

The top-level schematic (`pandore.kicad_sch`) references 24 sub-sheets organized by subsystem:

**Audio** — `audio`, `audio-codec`, `audio-inputs`, `audio-inbuf`, `audio-outputs`, `audio-outbuf`, `audio-isolation`, `audio-monitor`, `audio-power`

**Compute** — `computer`, `cpumod`, `mcu`, `mgmtmcu`, `rtmcu`

**Power** — `power`, `audio-power`

**Interface** — `eth`, `usbport`, `midi`, `display`, `extraport`, `mdot2`

**System** — `bootctl`, `bios`, `fan`

## Components Requiring Separate Assembly

The PCBWay PCBA order covers all SMD components. The following through-hole and DNP parts must be sourced and hand-soldered separately. BOM part numbers are listed; substitutions are noted where a different part is recommended over the original BOM.

| BOM# | Per board | Ref | Description | Part (installed) | Notes |
|------|-----------|-----|-------------|-----------------|-------|
| 40 | 1 | E1 | Encoder + RGB LED + switch | Bourns **PEL12T-4225T-S1024** | 24 PPR, push switch, RGB illuminated |
| 47 | 2 | J4, J5 | Mic/Line input combo jack | Neutrik **NCJ9FI-H-0** | XLR + 6.35mm TRS + 3-way switch |
| 50 | 2 | J8, J9 | Ethernet RJ45 | Amphenol **RJE58-188-5441** | 8P8C shielded, dual LEDs, Cat5e (replaces BOM -5411, backordered; same footprint) |
| 51 | 2 | J10, J11 | MIDI DIN | Same Sky **SDS-50J** | 5-pin DIN 180° |
| 52 | 1 | J12 | Line output TRS | Neutrik **NSJ12HF-1** | 6.35mm stacking stereo |
| 55 | 2 | J15, J16 | GPIO expansion header | Samtec **MTSW-108-22-L-T-330-RA** | 3×8 right-angle, 2.54mm pitch |
| 56 | 2 | J17, J18 | Grove connectors | TE **440055-4** | HPI 2.0mm R/A THT (replaces BOM 2041145-4, same family) |
| 105 | 1 | R273 | Headphone volume pot | Bourns **PTR902-2020K-A103** | Audio taper, 20mm shaft (replaces BOM 2015K-B103, linear, 15mm) |
| — | 1 | J25 | OLED display panel | **Microtips REX012864AYAP3N00000** (primary) or Midas MCOT128064B1V-WM (alt) | SSD1309, 128×64, 24-pin 0.5mm FPC; J25 ZIF socket is PCBWay-assembled |
| — | 1 | U9 | Audio/MIDI bridge module | **PJRC Teensy 4.1** (SparkFun DEV-20359, headerless) | Mounted on Samtec TSW headers; its own USB-C jack is exposed at the panel |
| — | 2 | J28, J29 | Teensy USB-D± pogo pins | Same Sky **CPG-23-SMT-TR** | Spring contacts tapping the Teensy's underside USB-D+/D− pads — **not** USB-C receptacles; hand-soldered |
| — | 1 | J13 | NVMe SSD | User choice | M.2 2280 Key-M, PCIe x4 |
| — | 1 | J19 | WiFi/BT module | **Intel AX210** (WiFi 6E + BT 5.3) | M.2 2230 Key-E |

---

## Manufacturing

The `release/` directory contains two packages dated 2026-03-19 (revision A0):

- **`pandore_*_A0_pcba.zip`** — PCBA package: Gerbers, drill files, BOM (.csv), pick-and-place (.pos)
- **`pandore_*_A0_release.zip`** — Full release: PCBA files + 3D assembly model (.step), assembly drawings (PDF), rendered board images, ERC/DRC reports

4-layer stackup. 2,439 drill holes. All components have manufacturer part numbers assigned.

## Reference Documentation

The `doc/reference/` directory includes datasheets and design guides used during development:

- RP2350 datasheet and hardware design guide
- LattePanda Mu evaluation kit guide and carrier board reference
- CS4272 codec (via SuperAudioBoard design guide and schematic)
- THAT1512 microphone preamp gain configuration (reference design)
- 48V phantom power supply design (TI SBOA320A + ultra-low-noise RAQ approach)
- Analog circuit design references (Analog Secrets series, AES mic preamp paper)
- THAT Corporation mic preamp reference design (git submodule)

## Requirements

- [KiCad 10](https://www.kicad.org/) to open and edit schematics and PCB layout
- [draw.io](https://app.diagrams.net/) to view architecture diagrams

## Credits

Designed by **Vincent Fillion** at [Artificiel](https://artificiel.org), with the help of **Alexandre Burton**.

Hardware engineering and KiCad source files by **Laurence Deschênes Villeneuve** ([@laurencedv](https://github.com/laurencedv)).

## License

This project is licensed under the [CERN Open Hardware Licence Version 2 — Strongly Reciprocal (CERN-OHL-S-2.0)](https://ohwr.org/cern_ohl_s_v2.txt).

You are free to use, study, modify, and distribute this design, provided that:
- You credit the original authors
- You distribute any modified versions under the same licence
- You make the source files available
