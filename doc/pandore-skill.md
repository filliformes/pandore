<!-- This document is the Pandore hardware technical reference, generated from the project's
     Claude Code skill. Personal paths, order numbers, and cost data have been removed. -->

# Pandore — Open-Source Digital Audio Instrument Prototyping Platform

Expert knowledge for developing firmware, drivers, and software for the Pandore hardware platform. Covers the complete system architecture, pin assignments, bus routing, audio signal chain, power rails, and peripheral interfaces.

**When to use:** Any work on Pandore firmware, drivers, DSP software, hardware bringup, peripheral integration, or system-level debugging.

---

## Project Location

- **Repo:** `<your local clone>/`
- **GitHub:** `filliformes/pandore`
- **Design tool:** KiCad 10
- **Status:** Revision A0 — PCBs **PCBA complete at PCBWay** (3 units), **hand-assembly + bringup in progress** (as of 2026-05-29). PCBWay received last components 2026-05-15. **iBOM and bringup doc published** by Laurence on 2026-05-19 (commit `4497a3b`): [hw/bom/ibom.html](hw/bom/ibom.html) (interactive BOM, open in browser) and [doc/test/bringup/pandore_a0_bringup.md](doc/test/bringup/pandore_a0_bringup.md) (manual-assembly checklist). Manufacturing files released 2026-03-19; PCBA payment to PCBWay 2026-03-24 (~2 446 CAD ≈ 1 310 CAD/unit all-inclusive of BOM). The complete Mouser order for the hand-assembly parts was placed 2026-05-19 — it also included the LattePanda Mu modules, Teensy boards, and active coolers, not just DNP connectors.
- **PCBWay substitution:** RP2350A unavailable; PCBWay substituted **RP2350B (QFN-80)** for both MCU positions (U3, U4). Binary-compatible — same cores, peripherals, memory map. Firmware developed on RP2350A Pico boards transfers without modification. Verify footprint accepts QFN-80 with Laurence.
- **Design by:** Vincent Fillion at [Artificiel](https://artificiel.org), with Alexandre Burton
- **Hardware engineering:** Laurence Deschênes Villeneuve ([@laurencedv](https://github.com/laurencedv))
- **Licence:** CERN-OHL-S-2.0 (strongly reciprocal — attribution + share-alike + source availability)

### Currently Available Hardware (pre-assembly dev kit)

| Item | Part | Notes |
|------|------|-------|
| Host CPU | LattePanda Mu + Lite Carrier | On hand |
| Management/RTIO dev MCU | Waveshare RP2350-Plus (WAVE-29371) | 40-pin Pico 2 form factor, soldered headers, USB-C, 4MB flash |
| Networking dev | Waveshare RP2350-ETH Mini (WAVE-29266) | RP2350 + CH9121 UART-to-Ethernet chip, compact castellated form |
| OLED display | Waveshare 1.54" OLED (WAVE-25512) | SSD1309, 128×64, 7-pin SPI breakout, **onboard boost converter** |

All Management MCU firmware (display, power sequencing, IMU, fan control) is prototyped on the **RP2350-Plus** before the Pandore PCB is assembled.

> **Important difference from final board:** The Waveshare OLED module (WAVE-25512) has an **onboard boost converter** — its VCC pin accepts 3.3–5V (self-contained). The bare Midas MCOT128064B1V-WM panel on the Pandore PCB needs an **external 12V** supply on pin 23. Do not confuse the two when porting firmware.

---

## Dev Kit — Firmware Prototyping

### RP2350-Plus (WAVE-29371) — Key Facts

- **Chip:** RP2350**A** (30 GPIO) — not the RP2350B (48 GPIO) used on Pandore's RTIO MCU
- **Form factor:** 40-pin Pico 2 compatible, soldered headers
- **Flash:** 4 MB (W25Q32JV QSPI)
- **Power:** VSYS 1.8–5.5V in; 3.3V output (500 mA); USB-C
- **GPIO logic:** 3.3V only — never apply 5V to GPIO pins

**Default SPI pin assignments (Pico SDK):**

| Bus | SCK | TX (MOSI) | RX (MISO) | CSn |
|-----|-----|-----------|-----------|-----|
| SPI0 | GP18 | GP19 | GP16 | GP17 |
| SPI1 | GP10 | GP11 | GP12 | GP13 |

**Other interfaces:**

| Interface | Pins |
|-----------|------|
| I2C0 | GP4 (SDA), GP5 (SCL) |
| I2C1 | GP2 (SDA), GP3 (SCL) |
| UART0 | GP0 (TX), GP1 (RX) |
| UART1 | GP4 (TX), GP5 (RX) |
| ADC | GP26–GP28 (ADC0–ADC2) |

### Waveshare 1.54" OLED (WAVE-25512) — Module Pinout

7-pin header on the breakout board:

| Pin | Label | Description |
|-----|-------|-------------|
| 1 | VCC | 3.3–5V power in (onboard boost handles OLED drive voltage) |
| 2 | GND | Ground |
| 3 | DIN | SPI MOSI (SDIN) |
| 4 | CLK | SPI SCLK |
| 5 | CS | Chip select (active low) |
| 6 | DC | Data/Command select |
| 7 | RST | Reset (active low) |

Factory default: **4-wire SPI**. I2C mode requires moving 0Ω resistors on the back of the module (not recommended — keep SPI).

### Wiring: WAVE-25512 OLED → RP2350-Plus

| OLED pin | RP2350-Plus pin | GPIO | Notes |
|----------|-----------------|------|-------|
| VCC | 3V3 (pin 36) | — | Module has internal boost; 3.3V is sufficient |
| GND | GND (pin 38) | — | |
| DIN | GP19 (pin 25) | GP19 | SPI0 TX |
| CLK | GP18 (pin 24) | GP18 | SPI0 SCK |
| CS | GP17 (pin 22) | GP17 | SPI0 CSn — or manual GPIO |
| DC | GP20 (pin 26) | GP20 | Manual GPIO |
| RST | GP21 (pin 27) | GP21 | Manual GPIO |

### Software Approach for OLED

**Option A — u8g2 library (recommended for dev)**
- Constructor: `U8G2_SSD1309_128X64_NONAME0_F_4W_HW_SPI`
- Works with Pico SDK via [u8g2 Arduino port](https://github.com/olikraus/u8g2) or the [Pico-specific u8g2 port](https://github.com/Harbys/pico-ssd1306) (for SSD1306 but same pattern)
- Handles init sequence, SSD1309 command set, display buffer

**Option B — Raw Pico SDK SPI**
```c
// Init SPI0 at 10 MHz
spi_init(spi0, 10 * 1000 * 1000);
gpio_set_function(18, GPIO_FUNC_SPI); // SCK
gpio_set_function(19, GPIO_FUNC_SPI); // MOSI
gpio_init(17); gpio_set_dir(17, GPIO_OUT); // CS
gpio_init(20); gpio_set_dir(20, GPIO_OUT); // DC
gpio_init(21); gpio_set_dir(21, GPIO_OUT); // RST
```
- SSD1309 init sequence: send `0xAE` (Display Off) → config commands → clear GRAM → `0xAF` (Display On)
- Write: pull CS low, set DC high (data) or low (command), `spi_write_blocking(spi0, buf, len)`, pull CS high

**Power-up sequence (same for module and bare panel):**
1. VCC on → RST low (1 ms) → RST high → send `0xAE` → init registers → clear screen → delay 100 ms → send `0xAF`

### Build Environment (Pico SDK on Windows)

> ⚠️ **The Docker path and the official Windows installer both fail for RP2350 on this Windows dev machine** — see [Software & Firmware Development](#software--firmware-development) for the *verified working* toolchain recipe (SDK 2.1.1 cloned manually + v1.5.1 toolchain binaries + prebuilt picotool 2.1.1). What does NOT work, and why:
> - **Docker Desktop:** its WSL2 backend is disabled here (`Wsl/0x80070422`) — the daemon returns HTTP 500 on every call.
> - **`pico-setup-windows` installer:** ships **SDK 1.5.1 only**, which is RP2040-era and **cannot build RP2350** (no `rp2350-arm-s` platform). Useful only for its bundled arm-gcc / ninja / cmake binaries.

**CMakeLists.txt minimum for SPI + OLED:**
```cmake
cmake_minimum_required(VERSION 3.13)
include($ENV{PICO_SDK_PATH}/external/pico_sdk_import.cmake)
project(pandore_oled C CXX ASM)
pico_sdk_init()

add_executable(pandore_oled main.c)
target_link_libraries(pandore_oled pico_stdlib hardware_spi hardware_gpio)
pico_add_extra_outputs(pandore_oled)  # generates .uf2
```

**Flash:** hold BOOTSEL on RP2350-Plus while plugging USB → appears as mass storage → drag `.uf2` file onto it.

### RP2350-ETH Mini (WAVE-29266) — Notes

- **Ethernet chip:** CH9121 (UART-to-Ethernet bridge, not native Ethernet MAC)
- **Interface:** RP2350 talks to CH9121 over UART at configurable baud rate
- **Only 14 GPIO exposed** (castellated half-holes) — compact for integration
- CH9121 config registers set: IP, gateway, subnet, port, mode (TCP/UDP server/client) via UART commands
- Example code: `CH9120.c` / `CH9120.cpp` config files from Waveshare
- **Use case on Pandore:** prototype network-based control / OSC / remote config before Pandore PCB arrives

---

## Software & Firmware Development

How Pandore software is actually built, where it lives, and the verified toolchain — as opposed to the aspirational advice elsewhere. Written from real bring-up (2026-05).

### Firmware repo

The firmware does **not** live in the `pandore` hardware repo (that's KiCad + CERN-OHL-S). It lives in the **`677_pandore` GitLab repo** (`gitlab.artificiel.org/projets/677_pandore`), MIT-licensed:

```
677_pandore/
  recherche/oled-usb-menu/        research sandbox — OLED menu prototype
    mgmtmcu_menu/                  RP2350 firmware (Pico SDK C)
      src/                         main.c, oled_ssd1309, gfx, font5x7,
                                   menu, menu_items, input, host_link, board_pins.h
      CMakeLists.txt  build.ps1  Dockerfile(dead)  README.md
    host_bridge/                   LattePanda-side Python (pyserial → Max/Pd/SC)
```

> **Status:** the menu firmware is a **throwaway prototype**. The production plan (see `677_pandore/CLAUDE.md`) is a single C++20 daemon that owns all hardware and speaks **binary USB framing** to the two RP2350s ("Slot 0" / "Slot 1"). The prototype's text protocol is for fast iteration; it will be re-homed onto the daemon's binary framing once the concept is proven. Do not expect it to plug into `firmware/slot0` as-is.

### Verified Windows toolchain (RP2350)

The **only** combination proven to build RP2350 firmware here. Docker and the official installer both fail (see the Build Environment warning above).

| Piece | Location | How it got there |
|---|---|---|
| Pico SDK **2.1.1** | `%USERPROFILE%\pico-sdk\sdk-2.1.1` | `git clone --branch 2.1.1` + `git submodule update --init` (pulls TinyUSB etc.) |
| arm-none-eabi-gcc 10.3, cmake, ninja, python | `C:\Program Files\Raspberry Pi\Pico SDK v1.5.1\` | reused from the `pico-setup-windows` v1.5.1 install (its binaries are fine; only its SDK is too old) |
| **picotool 2.1.1** (prebuilt) | `%USERPROFILE%\pico-sdk\picotool-2.1.1\picotool` | downloaded `picotool-2.1.1-x64-win.zip` from `pico-sdk-tools` releases — the from-source build fails (no host x86 compiler) |

Key CMake settings: `PICO_BOARD=pico2`, `PICO_PLATFORM=rp2350-arm-s`. Pass `-Dpicotool_DIR=<...>\picotool` so CMake doesn't try to build picotool from source. `build.ps1` wires all of this up and takes `-Target DEVKIT|PANDORE`.

```powershell
cd 677_pandore\recherche\oled-usb-menu\mgmtmcu_menu
.\build.ps1                    # DEVKIT  → build-devkit\mgmtmcu_menu.uf2
.\build.ps1 -Target PANDORE    # Pandore → build-pandore\mgmtmcu_menu.uf2
```

### Dual-target pin map (`board_pins.h`)

One source tree builds for both boards via a compile-time switch (`PANDORE_TARGET` → `PANDORE_BOARD_DEVKIT` / `PANDORE_BOARD_PANDORE`). Dev-kit pins are in [Wiring: WAVE-25512 OLED → RP2350-Plus](#wiring-wave-25512-oled--rp2350-plus). The **Pandore Management MCU** map, traced from `pandore-mgmtmcu.kicad_sch` through the reusable `pandore-mcu` sub-sheet:

| Function | RP2350B GPIO | Net | Note |
|---|---|---|---|
| OLED CS | 33 | SDISP.~{SS} | SPI0 CSn |
| OLED SCK | 34 | SDISP.SCK | SPI0 SCK |
| OLED MOSI | 35 | SDISP.MOSI | SPI0 TX |
| OLED RST | 36 | SDISP.~{RST} | GPIO |
| OLED DC | 37 | SDISP.~{LATCH} | GPIO (D/C#) |
| Encoder A | 31 | ENC.A | |
| Encoder B | 30 | ENC.B | |
| Encoder BTN | 32 | ENC.BTN | |
| Enc LED R / G / B | 43 / 46 / 47 | ENC.RED/GREEN/BLUE | PWM-capable |

GPIO33/34/35 are the RP2350B's **native SPI0 alt-function pins** (datasheet Table 645), so the OLED runs on hardware SPI with no PIO. Pandore has no discrete nav buttons — the encoder owns navigation, so `BTN_PIN_*` are `-1` and `input.c` skips them.

### USB-CDC wire protocol (prototype)

Text, line-based, `\n`-terminated. Trivial to debug in a serial monitor.

```
MCU  → host:  LOAD <max|pd|sc> <path>   |  STOP  |  ENC <delta>
host → MCU:   STATUS cpu=<int> name=<text>  |  OK  |  ERR <msg>  |  INPUT <u|d|s|b>
```

`host_bridge/bridge.py` (pyserial) launches Max/Pd/SC on `LOAD`, kills on `STOP`, pushes `STATUS` ~1 Hz, and lets you drive the menu from stdin (`u/d/s/b`) when no encoder is wired. A binary **`FRAME` opcode (1024-byte 128×64 mono buffer) is reserved** for the eventual Schwung-renderer port — the day the menu is rendered host-side and pushed to a dumb display MCU.

### Expansion-header firmware map

GPIO/PWM assignments needed to write code against the expansion headers (traced from schematic — see [Expansion](#expansion) for the hardware side). **All 16 AIO/DIO signals carry a 560 Ω series resistor + TVS clamp**, so they are protected but *not* low-impedance drivers.

- **J15 AIO** (RTIO MCU): GPIO40–47 = ADC0–7, also PWM 8A–11B. Column B = VRTIO (= V3P3, unswitched, unfused). Column C = GND.
- **J16 DIO** (RTIO MCU): GPIO12,13,14,15,20,21,22,23 = PWM 6A,6B,7A,7B,2A,2B,3A,3B.
- **J17/J18 Grove** (Mgmt MCU): I2C0 = GPIO41(SCL)/40(SDA), I2C1 = GPIO39(SCL)/38(SDA). V+ is **PTC-fused** (~100 mA).
- **J33–J36** (LattePanda Mu native): UART0/1 and I2C3/4 straight off the x86 host — bypass both MCUs. GND is the centre pin (anti-reverse); no power pin.
- **J26 "RGBA"** (Mgmt MCU): dedicated **WS2812/SK6812 addressable-LED port** — GPIO on the Mgmt MCU → 74LVC1G17 buffer (5 V level shift) → data. `JMP5` selects V5 onto the port. This — not the AIO/DIO headers — is the intended way to drive an RGB LED. Direct RGB drive off AIO/DIO is starved (3.3 V through 560 Ω ≈ 2 mA red, <0.5 mA green/blue).

### Firmware targets (recap)

1. **Teensy 4.1** — Arduino/PlatformIO, Teensy Audio Library: I2S ↔ USB Audio, USB MIDI, CS4272 I²C control.
2. **RP2350B RTIO MCU** — Pico SDK: real-time I/O, ADC, 8× PWM, sensors.
3. **RP2350 Management MCU** — Pico SDK: OLED menu, encoder, RGB, power sequencing, fan, IMU. ← the `mgmtmcu_menu` prototype targets this.
4. **LattePanda Mu** — x86-64 Linux/Windows: main app host, DSP (JACK/PipeWire/ASIO), and the production daemon.

---

## System Architecture

```
                    ┌─────────────────────┐
                    │   LattePanda Mu     │
                    │   (x86-64 SBC)      │
                    │                     │
                    │  UART0-2, I2C2-5    │
                    │  8× USB (3×USB3,    │
                    │         5×USB2)     │
                    │  4× PCIe lanes      │
                    │  HDMI (DDIB)        │
                    │  BIOS (QSPI)        │
                    │  GPP_A/B/D/E/F GPIO │
                    └──┬───┬───┬───┬──┬──┘
                       │   │   │   │  │
          ┌────────────┘   │   │   │  └────────────┐
          │                │   │   │               │
    ┌─────┴──────┐   ┌────┴───┴┐  │    ┌──────────┴──────┐
    │ Teensy 4.1 │   │ RP2350B │  │    │ Management MCU  │
    │ Audio/MIDI │   │ RTIO MCU│  │    │ (RP2350)        │
    │ Bridge     │   │         │  │    │                 │
    │            │   │ 48 GPIO │  │    │ BMI270 IMU      │
    │ I2S ↔ USB  │   │ UART×2  │  │    │ Fan PWM ×2      │
    │ MIDI ↔ USB │   │ SPI×2   │  │    │ Power Seq       │
    │            │   │ I2C     │  │    │ Boot/Reset      │
    │ CS4272     │   │ USB     │  │    │ Display Ctl     │
    │ codec ctl  │   │ ADC     │  │    │ RGBA LED        │
    └────────────┘   │ 8× PWM  │  │    └─────────────────┘
                     │ QSPI    │  │
                     └─────────┘  │
                                  │
                    ┌─────────────┘
                    │
            ┌───────┴───────┐
            │  Peripherals  │
            │               │
            │ Ethernet(PCIe)│
            │ M.2 Key-M     │
            │ M.2 Key-A+E   │
            │ HDMI display  │
            │ Expansion hdr │
            └───────────────┘
```

---

## Audio Subsystem

### Signal Chain

```
Mic/Line Input → THS4521 Diff Amp + OPA1656 → Input Buffer → CS4272 ADC
                                                       │
                                                   I2S bus
                                                       │
                                              ┌────────┴────────┐
                                              │   Teensy 4.1    │
                                              │  (I2S ↔ USB     │
                                              │   Audio Bridge) │
                                              └────────┬────────┘
                                                       │
                                                  USB Audio
                                                       │
                                                LattePanda Mu
                                                       │
                                                  USB Audio
                                                       │
                                              ┌────────┴────────┐
                                              │   Teensy 4.1    │
                                              └────────┬────────┘
                                                       │
                                                   I2S bus
                                                       │
                                              CS4272 DAC → Output Buffer → Line Out
                                                                        → Monitor Amp (volume knob) → Headphones
```

### CS4272 Codec (U11)

- **Part:** CS4272K-CZZR (Cirrus Logic)
- **Format:** I2S, 24-bit, up to 192 kHz
- **Datasheet:** https://statics.cirrus.com/pubs/proDatasheet/CS4272_F2.pdf

**I2S Signals:**
| Signal | Description |
|--------|-------------|
| `DATA.TXD0` | I2S transmit data (ADC → MCU) |
| `DATA.RXD0` | I2S receive data (MCU → DAC) |
| `DATA.TXFS` | I2S frame sync (LRCLK) |
| `DATA.TXCLK` | I2S bit clock (BCLK) |
| `DATA.MCLK` | Master clock |

**Control (I2C):**
| Signal | Description |
|--------|-------------|
| `CTL.SDA` | I2C data |
| `CTL.SCL` | I2C clock |

**Audio Signals:**
| Signal | Description |
|--------|-------------|
| `LEFT.SIG+`, `LEFT.SIG-` | Balanced line output L |
| `RIGHT.SIG+`, `RIGHT.SIG-` | Balanced line output R |
| `MICLINE1.SIG+`, `MICLINE1.SIG-` | Mic/line input 1 |
| `MICLINE2.SIG+`, `MICLINE2.SIG-` | Mic/line input 2 |
| `~{MUTE}.L`, `~{MUTE}.R` | Mute control (active low) |
| `VCM0`, `VCM1`, `VCM2` | Virtual ground references |

**Hierarchical I2S Bus Labels (inter-sheet routing):**
| Label | Description |
|-------|-------------|
| `CODEC{I2S1DPX}` | Codec-side I2S bus |
| `CPU{I2S1DPX ~{RST}}` | LattePanda Mu I2S bus |
| `MCU{I2S1DPX ~{RST}}` | RP2350 MCU I2S bus |
| `DATA{I2S1DPX}` | Data-side I2S bus |
| `AUDMST{I2C}` | Audio master I2C bus |
| `CODEC{I2C}` | Codec I2C bus |

**Audio Domain Isolation:**

| Part | Designator | Type | Role |
|------|-----------|------|------|
| TI ISO7762FDBQR | U23 | 6-ch digital isolator, 100 Mbps, 5000 VRMS | I2S bus isolation (4 fwd / 2 rev) |
| TI ISO1640BDR | U24 | Isolated I2C, 1 Mbps, 2500 VRMS | Codec I2C control isolation |
| Murata NXE2S1212MC-R7 | U12 | **2W** isolated DC/DC, 12V→12V (167 mA, ±1500 VDC isolation) | Isolated power for VSSISO domain — **PCBWay-assembled**, see schematic `pandore-audio-power` |
| Isocom H11L1SMT | U10 | Optoisolator with Schmitt trigger | MIDI IN isolation |

- Separate analog ground (AVSS, VSSISO) from digital ground (VSS)
- ±8 kV IEC 61000-4-2 contact discharge ESD protection on ISO7762

### Microphone Preamp

- **Differential amplifier:** TI THS4521IDGKR (U15, U16, U17, U18) — fully-differential, low-noise, wideband
- **Signal conditioning:** TI OPA1656IDR (U26, U34, U35, U36) — dual low-noise op-amp (SOIC8)
- **Reference docs:** THAT1512 DN138 and thatmicpre submodule (reference designs, not used in final BOM)

### 48V Phantom Power

- Ultra-low-noise step-up converter
- ~10 mA output (sufficient for condenser microphones)
- Passive output filtering
- Design references: TI SBOA320A, RAQ ultra-low-noise approach

### Monitor Output

- Dedicated headphone/speaker amplifier
- **Volume knob:** Bourns PTR902 dual-gang potentiometer with rotary switch (R273, DNP)
  - **BOM part:** PTR902-2015K-B103 (10 kΩ, linear taper, 15 mm shaft)
  - **Installed part:** PTR902-2020K-A103 (10 kΩ, **audio taper**, **20 mm shaft**) — longer shaft for panel clearance; audio taper gives more natural volume feel (Mouser: 652-PTR902-2020KA103)
  - Footprint: `reekilib_pot:bourns_PTR902` (same for both shaft lengths)
- Independent from line outputs

### Audio Power Rails

| Rail | Description |
|------|-------------|
| `AV3P3` | 3.3V analog supply |
| `AV5` | 5V analog supply |
| `AVSS` | Analog ground |
| `VSSISO` | Isolated analog ground |

### Physical Audio I/O

| Connector | Part | Type |
|-----------|------|------|
| Mic/Line In (×2) | Neutrik NCJ9FI-H-0 | Combo XLR + 6.35mm TRS + 3-way switch |
| Line Out (×1) | Neutrik NSJ12HF-1 | 6.35mm TRS |
| Monitor | Same Sky SJ3-35083B-TR | 3.5mm TRS |
| MIDI In/Out | Same Sky SDS-50J (×2) | 5-pin DIN |
| Teensy USB-D± tap (J28, J29) | Same Sky CPG-23-SMT-TR (×2) | **Pogo pin** (spring contact, NOT USB-C). Contacts Teensy's bottom-side USB-D+/D- pads. Teensy's own USB-C jack is what's exposed at Pandore's panel. |

### Audio Performance

**Component-level specs:**

| Component | Role | Key Specs |
|-----------|------|-----------|
| CS4272 (Cirrus Logic) | Stereo codec | 24-bit, 4–192 kHz, 114 dB DR (A-wtd), -100 dB THD+N |
| THS4521 (TI, ×4) | Fully-diff amp | 4.6 nV/√Hz, -112 dB THD+N @ 1 kHz, 145 MHz BW, 490 V/µs, 102 dB CMRR |
| OPA1656 (TI, ×4) | Dual op-amp | 2.9 nV/√Hz, -131 dB THD @ 1 kHz, 53 MHz GBW, 24 V/µs |
| ISO7762 (TI) | I2S isolator | 6-ch, 100 Mbps, 11 ns delay, 5000 VRMS |

**System-level estimates** (CS4272 codec is the limiting factor, not the analog front-end):

| Parameter | Expected Value |
|-----------|---------------|
| Dynamic range | 112–114 dB (A-weighted) |
| THD+N (system) | -98 to -100 dB (codec-limited) |
| Noise floor | ~-114 dBFS (A-weighted) |
| Max sample rate | 192 kHz / 24-bit |
| USB audio latency | ~5–10 ms round-trip (buffer-dependent) |
| Frequency response | 20 Hz – 90 kHz (at 192 kHz) |
| Phantom power | 48V / 10 mA |
| Channel separation | >100 dB |
| Galvanic isolation | 5000 VRMS (digital ↔ audio domain) |

**Performance class:** Comparable to prosumer interfaces (Focusrite Scarlett, MOTU M4). The analog front-end is essentially transparent — the OPA1656's -131 dB THD provides substantial headroom over the codec. The 114 dB dynamic range is well above the noise floor of any instrument prototyping scenario.

---

## Teensy 4.1 — Audio/MIDI Bridge

- **Part:** PJRC Teensy 4.1 (NXP i.MX RT1062, ARM Cortex-M7 @ 600 MHz)
- **Sourcing:** SparkFun **DEV-20359** (headerless Teensy 4.1) at Mouser is the version Vincent used
- **Footprint:** `reekilib_som:teensy_4.1` — 2.54 mm pitch THT, 24+24 long-row pins + 5-pin USB host row
- **Datasheet:** https://www.pjrc.com/store/teensy41.html
- **Role:** Bridges I2S audio and MIDI data between the CS4272 codec and the LattePanda Mu over USB

### Mounting — direct-solder header stack

The Teensy is held entirely by **soldered pin headers** (no separate mechanical screws). Both boards share a single set of male pin headers; the plastic insulator acts as a fixed mechanical spacer between the two PCBs.

```
       ┌─────────────────────┐  ← Teensy 4.1 PCB top  (solder pins here)
       │ Teensy 4.1 (1.6 mm) │
       ├─────────────────────┤  ← Teensy bottom (rests on plastic)
       │   plastic 2.54 mm   │  ← INSULATOR = board-to-board gap
       ├─────────────────────┤  ← Pandore PCB top (rests on plastic)
       │ Pandore PCB (1.6 mm)│
       └─────────────────────┘  ← Pandore PCB bottom (solder pins here)
```

| Qty per board | Part | Mouser # | Notes |
|---|---|---|---|
| 2 | Samtec **TSW-124-07-T-S** | 200-TSW12407TS | 24-pin male, 2.54 mm pitch, **2.54 mm plastic** (sets the gap), mating post 5.84 mm / termination post 2.54 mm, tin |
| 1 | Samtec **TSW-105-07-T-S** | 200-TSW10507TS | 5-pin male, same family, for USB host row |

> ⚠️ **The 2.54 mm gap puts the CPG-23 pogo pins (J28/J29) at near-maximum compression.** CPG-23 working height is 2.50–2.90 mm (normal 2.70). 2.54 mm is within spec but only 0.04 mm above the max-compression limit. Reliable for static mount but tight — if a future revision adjusts the gap target, switching to a header with a 2.70 mm insulator would be ideal.

### USB-D± routing (J28, J29 pogo pins)

Pandore taps the Teensy's bottom-side USB-D+/D- exposed pads via **2× spring-loaded pogo pins** at positions J28 and J29:

| Position | Signal | Part |
|---|---|---|
| J28 | `AUDIO.D-` | Same Sky CPG-23-SMT-TR (Ø1.80 mm pad / Ø1.35 mm hole) |
| J29 | `AUDIO.D+` | Same Sky CPG-23-SMT-TR (Ø1.80 mm pad / Ø1.35 mm hole) |

When the Teensy is socketed onto its TSW header stack, the pogo pins make spring contact with the Teensy's underside pads — wiring USB-D± from the Teensy into Pandore's audio USB lane (`AUDIO.USB{USB2}` → LattePanda Mu) without any wires. The Teensy's own USB-C jack remains accessible at Pandore's back panel for direct user connection.

**Soldering order matters when stacking:**
1. Hand-solder the **CPG-23 pogo pins** to J28, J29 first (Pandore PCB, fine SMT work)
2. Insert TSW pin headers into Pandore PCB through-holes, plastic insulators flush on top
3. Set the Teensy on top, pins through its through-holes
4. Solder the **Teensy side first** (top pins) — locks the geometry
5. Flip and solder the Pandore PCB side

**Teensy Connections:**

| Teensy Pin/Bus | Connected To | Description |
|----------------|--------------|-------------|
| `CODEC{I2S1DPX}` | CS4272 I2S bus | I2S audio data to/from codec |
| `CPU{I2S1DPX ~{RST}}` | LattePanda Mu | I2S passthrough / USB audio |
| `MCU{I2S1DPX ~{RST}}` | RP2350 MCU | I2S interface to RTIO MCU |
| `USBH.VUSB` | USB host power | USB host bus voltage |
| `USBH.D-`, `USBH.D+` | USB host data | USB host data lines |
| `USBD.VUSB` | USB device power | USB device bus voltage |
| `USB{USB2}` | LattePanda Mu | USB 2.0 connection to host CPU |

**Firmware responsibilities:**
1. Class-compliant USB Audio device (I2S ↔ USB bridge)
2. MIDI data transfer (MIDI DIN → USB MIDI → LattePanda Mu)
3. Codec I2C control (configuration, sample rate, gain)

---

## RP2350B — RTIO MCU (U3)

- **Part:** RP2350B-TR13 / RP2350B-TR7 (Raspberry Pi)
- **Core:** Dual ARM Cortex-M33 or dual RISC-V Hazard3 @ 150 MHz
- **Package:** QFN-80 (48 GPIO) — PCBWay substituted RP2350B for RP2350A; same binary interface, only differs in package footprint
- **Flash:** W25Q128JVSIM (128 Mbit = 16 MB, QSPI) — same part used for all 3 processors (U2/U5/U6)

### GPIO Map (48 lines: GPIO0–GPIO47)

All 48 GPIOs are exposed via hierarchical labels. Key alternate functions:

| Function | Pins |
|----------|------|
| UART0 TX/RX | Configurable (any GPIO via PIO) |
| UART1 TX/RX | Configurable (any GPIO via PIO) |
| SPI0 (MOSI/MISO/SCK/CS) | Configurable |
| SPI1 (MOSI/MISO/SCK/CS) | Configurable |
| I2C | Configurable |
| USB D+/D- | GPIO7 / GPIO6 |
| ADC | GPIO26-GPIO29 (ADC0-ADC3) |
| PWM | 8 channels on configurable pins |

**USB Signals:**
| Signal | GPIO | Description |
|--------|------|-------------|
| `_USB.D+` / `USB.D+` | GPIO7 | USB data positive |
| `_USB.D-` / `USB.D-` | GPIO6 | USB data negative |

**QSPI Flash Bus:**
| Signal | Description |
|--------|-------------|
| `QSPI.SCK` | SPI clock |
| `QSPI.D0`–`QSPI.D3` | Quad SPI data |
| `QSPI.~{CS}` | Chip select (active low) |

---

## Management MCU (RP2350)

Connected to the LattePanda Mu for system-level control.

### Responsibilities

- Power-on sequencing
- Fan control (dual PWM)
- Boot/reset control
- Display management
- RGBA LED output
- BMI270 IMU reading

### BMI270 IMU

- **Type:** 6-axis (accelerometer + gyroscope)
- **Interface:** I2C or SPI (connected to management MCU)
- **Use case:** Motion-based instrument control (tilt, shake, orientation)

### Fan Control

| Fan Header | Signals | Description |
|------------|---------|-------------|
| `FANCPU{TAC PWM}` | `FANCPU.TAC`, `FANCPU.PWM` | CPU fan (tachometer + PWM) |
| `SYSCPU{TAC PWM}` | `SYSCPU.TAC`, `SYSCPU.PWM` | System fan (tachometer + PWM) |

4-pin headers: VCC, GND, TAC (RPM feedback), PWM (speed control).

### OLED Status Display

#### Selected Part

- **Part:** Midas Displays MCOT128064B1V-WM
- **Source:** DigiKey.ca (PN: MCOT128064B1V-WM, DigiKey #21322651)
- **Datasheet:** https://www.farnell.com/datasheets/2830019.pdf
- **Alternate sources:** Farnell (PN 2817922), RS Components (PN 249-2717)

#### Display Specifications

| Parameter | Value |
|-----------|-------|
| Type | Graphic OLED, passive matrix, COG (chip-on-glass) |
| Resolution | 128 × 64 pixels |
| Diagonal | 1.54" |
| Driver IC | SSD1309ZC |
| Appearance | White on black |
| Module size | 42.04 × 27.22 × 1.45 mm |
| Active area | 35.05 × 17.51 mm |
| Pixel pitch | 0.274 × 0.274 mm |
| Contrast ratio | 2000:1 |
| Brightness | 100–120 cd/m² (50% checkerboard) |
| Viewing angle | 160° (H/V) |
| Operating temp | -40°C to +80°C |
| OLED lifetime | 20,000 hours (25°C, 50% checkerboard) |

#### Electrical Characteristics

| Parameter | Symbol | Min | Typ | Max | Unit |
|-----------|--------|-----|-----|-----|------|
| Logic supply | VDD | 2.80 | 3.00 | 3.30 | V |
| Display supply | VCC | 12.00 | 12.50 | 13.00 | V |
| Operating current (50% checker) | IDD | — | 16 | 45 | mA |

#### FPC Connector

- **FPC:** 24-pin, 0.5 mm pitch, top contact
- **Mating connector:** GCT FFC2A32-24-T (ZIF, slide lock, SMT)
- **FPC contact width:** P0.5 × 23 = 11.5 mm

#### Pinout (24-pin FPC)

| Pin | Symbol | Function | Pandore Connection (SPI mode) |
|-----|--------|----------|-------------------------------|
| 1 | NC (GND) | No connection | GND |
| 2 | VLSS | Analog ground | VSS |
| 3 | VSS | Ground | VSS |
| 4 | NC | No connection | — |
| 5 | VDD | Logic supply (2.8–3.3V) | V3P3 rail |
| 6 | BS1 | Interface select | VSS (= 0 for SPI) |
| 7 | BS2 | Interface select | VSS (= 0 for SPI) |
| 8 | CS# | Chip select (active low) | Management MCU GPIO |
| 9 | RES# | Reset (active low) | Management MCU GPIO |
| 10 | D/C# | Data/Command select | Management MCU GPIO |
| 11 | R/W# | Read/Write (SPI: tie low) | VSS |
| 12 | E/RD# | Enable/Read (SPI: tie low) | VSS |
| 13 | D0 | SPI: SCLK | Management MCU SPI CLK |
| 14 | D1 | SPI: MOSI (SDIN) | Management MCU SPI TX |
| 15 | D2 | SPI: NC | — |
| 16–20 | D3–D7 | Unused in SPI (tie low) | VSS |
| 21 | IREF | Segment current ref | Resistor to VSS (set 10 µA) |
| 22 | VCOMH | COM deselected voltage | 4.7 µF cap to VSS |
| 23 | VCC | Display drive (12–13V) | V12 rail + 4.7 µF cap |
| 24 | NC (GND) | No connection | GND |

#### Power Integration with Pandore

- **VDD (logic):** Connect directly to Pandore `V3P3` rail (3.3V)
- **VCC (OLED drive):** Connect directly to Pandore `V12` rail (12V) — within the 12.0–13.0V spec range, no boost converter needed
- **Ground:** Connect to `VSS` (digital ground domain, not AVSS)
- **IREF resistor:** R = (VCC − 3.5V) / 10 µA. For VCC = 12V: R ≈ 850 kΩ (nearest standard: 820 kΩ or 910 kΩ). Fine-tune for desired brightness.

#### Software

- **u8g2 constructor:** `U8G2_SSD1309_128X64_NONAME0_F_4W_HW_SPI`
- **Pico SDK SPI:** Standard `spi_write_blocking()` with manual CS/DC GPIO control
- **Interface:** 4-wire SPI (fastest option, recommended over I2C)
- **Power-up sequence:** VDD first → send Display Off → init → clear screen → VCC on → delay 100 ms → Display On
- **Power-down sequence:** Display Off → VCC off → delay 100 ms → VDD off

#### IREF and VCOMH

- **IREF (pin 21):** R = (VCC − 3.5V) / 10 µA. For VCC = 12.5V (typ): R ≈ 900 kΩ → use **910 kΩ** (R196 in BOM, confirmed). For 12.0V: ~850 kΩ. Fine-tune for desired brightness.
- **VCOMH (pin 22):** Bypass cap to VSS — use **2.2 µF** (not 4.7 µF)

#### Sourcing Options

| Manufacturer | Part Number | Notes | Source |
|---|---|---|---|
| Microtips/Raystar | **REX012864AYAP3N00000** | SSD1309, 128×64, yellow emitting, same 24-pin FPC — **primary choice** | Mouser 668-REX012864AYAP3N |
| Midas Displays | MCOT128064B1V-WM | SSD1309, 128×64, white emitting — **alternate** | DigiKey.ca #21322651 |
| Generic (Amazon) | JESSINIE 1.54" SSD1309 24-pin | Bare COG panels, verify 24-pin before ordering | Amazon.ca |

#### Dev Prototyping Setup

For firmware development before Pandore PCB arrives:

- **Display module:** Waveshare WAVE-25512 (1.54" OLED, SSD1309, 7-pin SPI header breakout — same panel on a PCB)
- **MCU board:** Waveshare RP2350-Plus (WAVE-29371) — full 40-pin Pico 2 pinout, best for display driver dev
- **Ethernet board:** Waveshare RP2350-ETH (WAVE-29266) — for networking experiments
- **Source:** ABRA Electronics, Montreal (local pickup)

---

## LattePanda Mu — Host CPU (U1)

- **Architecture:** x86-64, Intel Processor N100 (4 cores, up to 3.4 GHz) or N305 (8 cores, up to 3.8 GHz)
- **Recommended variant:** DFR1146 (N100, 8 GB LPDDR5) or **DFR1147 (N100, 16 GB LPDDR5, preferred)** for Max/MSP and heavy DSP workloads
- **Board configuration (3 boards):** 1× **DFR1147** (N100, 16 GB — Mouser, the preferred heavy-DSP unit) + 1× **DFR1146** (N100, 8 GB — Mouser) + 1× **LattePanda Mu 8 GB Evaluation Kit** (Amazon, Jan 2026, ASIN B0D4VC43HC = Mu + Lite Carrier, the firmware dev unit). Net fleet: **two 8 GB + one 16 GB**. Only **2× FIT0981 active coolers** were bought for the 3 boards — the third has no active cooler yet.
- **N100 vs N305:** N305 gives only ~13% single-core gain (GB6: 1217→1376) at ~2× price — not worth it for real-time audio where single-thread performance dominates. The 16 GB RAM is more valuable than the extra cores.
- **Geekbench 6:** N100 = 1217 single / 3115 multi; N305 = 1376 single / 5249 multi
- **TDP:** Configurable 6W–35W (6W passive, 35W active cooling)
- **Power rails:** V3P3 (3.3V), V12 (12V)

### Exposed Interfaces

**UART:**
| Bus | Description |
|-----|-------------|
| `UART0{UART}` | General purpose |
| `UART1{UART}` | General purpose |
| `UART2{UART}` | General purpose |
| `AUDIO.MIDI{UART}` | MIDI data (via Teensy USB) |

**I2C:**
| Bus | Description |
|-----|-------------|
| `I2C2{I2C}` | Peripheral bus |
| `I2C3{I2C}` | Peripheral bus |
| `I2C4{I2C}` | Peripheral bus |
| `I2C5{I2C}` | Peripheral bus |

**USB (8 lanes from LattePanda Mu — NOT 8 user-facing ports):**

> **Important distinction.** The LattePanda Mu exposes **8 USB lanes** (logical) to the carrier. Pandore breaks them out into **only 4 user-facing USB-A receptacles**: J2 (USB2-A_2stacked, Same Sky 61400826021) = 2× USB 2.0 ports stacked, and J3 (USB3-A_2stacked, Amphenol 1003-004-01010) = 2× USB 3.0 ports stacked. The remaining lanes are routed internally (Teensy audio bridge, Intel AX210 WiFi/BT M.2 module, etc.). Plus 2× USB-C receptacles (J28/J29, PCBWay-assembled) for the Teensy 4.1 audio/MIDI bridge. **When writing for non-technical audiences (sub, paper, presentation): say "4 USB-A ports + 2 USB-C", not "8 USB".**

| Lane | Type | Description |
|------|------|-------------|
| `USBP1{USB3}` | USB 3.0 | → J3 (front USB-A) |
| `USBP2{USB3}` | USB 3.0 | → J3 (front USB-A) |
| `USBP3{USB2}` | USB 2.0 | → J2 (front USB-A) |
| `USBP4{USB2}` | USB 2.0 | → J2 (front USB-A) |
| `USBP5{USB2}` | USB 2.0 | Internal (M.2 / WiFi+BT) |
| `USBP6{USB2}` | USB 2.0 | Internal |
| `USBP7{USB2}` | USB 2.0 | Internal |
| `USBP8{USB2}` | USB 2.0 | Internal |
| `AUDIO.USB{USB2}` | USB 2.0 | Teensy audio bridge — **routed via 2× pogo pins (J28/J29 = Same Sky CPG-23-SMT-TR) that contact the Teensy's bottom-side USB-D+/D- pads**. The Teensy's own front-edge USB-C jack is what's exposed at Pandore's back panel. |

**PCIe:**
| Lane | Type | Description |
|------|------|-------------|
| `PCIEP0{PCIE1X}` | PCIe x1 | Ethernet / peripheral |
| `PCIEP1{PCIE1X}` | PCIe x1 | Peripheral |
| `PCIEP2{PCIE1X}` | PCIe x1 | Peripheral |
| `PCIEP3{PCIE4X}` | PCIe x4 | NVMe M.2 / high-bandwidth |

**Display:**
| Signal | Description |
|--------|-------------|
| `DISP{HDMI}` | HDMI output (DDIB bus) |

**GPIO (directly exposed):**
| Pin | Description |
|-----|-------------|
| `GPP_A12` | General purpose |
| `GPP_B11`, `GPP_B14` | General purpose |
| `GPP_D0`, `GPP_D2`, `GPP_D3` | General purpose |
| `GPP_E0` | General purpose |
| `GPP_F12`–`GPP_F16` | General purpose (5 pins) |

**System Control:**
| Signal | Description |
|--------|-------------|
| `PWRSW` | Power switch |
| `RSTSW` | Reset switch |
| `BIOS{QSPI SEL}` | BIOS flash select |

---

## MIDI Interface

### Circuit

```
MIDI IN (5-pin DIN, SDS-50J)
    │
    └→ H11L1 Optoisolator → MIDI.RX → Teensy UART → USB MIDI → LattePanda Mu
                                                                       │
LattePanda Mu → USB MIDI → Teensy UART → MIDI.TX → MIDI OUT (5-pin DIN, SDS-50J)
```

- **Connectors:** 2× SDS-50J (Same Sky 5-pin DIN)
- **Isolation:** H11L1 optoisolator with Schmitt-trigger output on MIDI IN
- **Signals:** `MIDI.TX`, `MIDI.RX`, `MIDIRX`, `MIDITX`
- **Power:** `VMIDI` supply rail
- **UART:** Connected via `UART` hierarchical label

---

## Display

- **Connector:** HDMI Type-A receptacle (J1, 19-pin)
- **Bus:** DDIB from LattePanda Mu
- **Signals:** 3 TMDS data pairs + 1 clock pair (differential)

| Signal | Description |
|--------|-------------|
| `_HDMI.CLK+`, `_HDMI.CLK-` | Pixel clock (differential) |
| `_HDMI.D0+`, `_HDMI.D0-` | Data lane 0 |
| `_HDMI.D1+`, `_HDMI.D1-` | Data lane 1 |
| `_HDMI.D2+`, `_HDMI.D2-` | Data lane 2 |
| `DISABLE` | Display enable/disable control |

---

## Storage — M.2 Slots

### M.2 Key-M (J13)

- **Format:** M.2 2280 Key-M (NGFF)
- **Interface:** PCIe x4 via `PCIEP3{PCIE4X}`
- **Use:** NVMe SSD

### M.2 Key-A+E (J19)

- **Format:** M.2 2280 Key-A+E (NGFF)
- **Use:** WiFi/Bluetooth module or alternate storage
- **Selected module:** Intel AX210 (WiFi 6E tri-band + Bluetooth 5.3, M.2 2230 Key-E) — Amazon.ca

### Mounting Options

M2M42, M2AE30, M2M60, M2M80, M2M110 — supports multiple card lengths.

---

## Ethernet

- **Controllers:** 2× Realtek **RTL8111H-CG** (U7, U8) — PCIe Gigabit Ethernet controllers
- **Connectors:** 2× Amphenol **RJE58-188-5411** (J8, J9) — shielded 8P8C with dual LEDs (Yellow/Green), Cat5e (Mouser: 523-RJE58-188-5411). **As of 2026-05: 5411 backordered at Mouser CA — substitute with Amphenol RJE58-188-5441 (Mouser 523-RJE58-188-5441), same KK 254 family, same footprint, LEDs Green/Yellow (sides swapped from 5411).** KiCad footprint `reekilib_con:amphenol_RJE58-188-54x1-0x` accepts any RJE58-188-54x1 variant by design (`ki_fp_filters` allows the whole family).
- **Isolation transformers:** Würth 749020111A pulse transformers (T1, T2) on each port
- **Interface:** Each RTL8111H connects via PCIe x1 from LattePanda Mu
- **Use:** Dual Gigabit Ethernet — one for general network, one for dedicated audio/control (OSC, etc.)

---

## Main Encoder (E1)

- **Part:** Bourns PEL12T-4225T-S1024
- **Type:** 24-pulse/rev optical encoder + momentary push switch + RGB LED illumination
- **Resolution:** 24 PPR (96 edges/rev in quadrature)
- **Use:** Primary navigation/value encoder for the instrument UI
- **Connections:** Encoder A/B pulses → Management MCU GPIO; RGB LED → Management MCU PWM outputs; push switch → Management MCU GPIO

---

## Parts Not Assembled by PCBWay (DNP — Order Separately)


**Interactive BOM:** [hw/bom/ibom.html](hw/bom/ibom.html) — open in browser, click any designator to highlight on the PCB.

Connectors and footprints are on the PCB; the parts themselves must be hand-soldered. The complete Mouser order was placed 2026-05-19 — quantities below are per board × 3 boards. All rows are confirmed against purchase records.

| # | BOM# | Per board | Part | BOM original | Installed | Source | Notes |
|---|------|-----------|------|-------------|-----------|--------|-------|
| 1 | 40 | 1 | **Encoder RGB+switch** (E1) | Bourns PEL12T-4225T-S1024 | same | Mouser 652-PEL12T4225TS1024 | 24 PPR, push, RGB |
| 2 | 47 | 2 | **XLR+TRS combo** (J4, J5) | Neutrik NCJ9FI-H-0 | same | Mouser 568-NCJ9FI-H-O | |
| 3 | 50 | 2 | **Ethernet RJ45** (J8, J9) | Amphenol RJE581885411 | **RJE58-188-5441** (5411 backordered) | Mouser 523-RJE58-188-5441 | 8P8C, dual LEDs (Green/Yellow), Cat5e, same KK254 footprint |
| 4 | 51 | 2 | **MIDI DIN** (J10, J11) | Same Sky SDS-50J | same | Mouser 490-SDS-50J | 5-pin DIN 180° |
| 5 | 52 | 1 | **Line out TRS** (J12) | Neutrik NSJ12HF-1 | same | Mouser 568-NSJ12HF-1 | 6.35mm stacking stereo |
| 6 | 55 | 2 | **GPIO pin header** (J15, J16) | Samtec MTSW-108-22-L-T-330-RA | **same** (MTSW-108, confirmed) | Samtec direct | 3×8 R/A 2.54mm. **Invoice confirms the real 8-pos MTSW-108 was ordered — the "cut-down MTSW-110" alt was NOT used.** |
| 7 | 56 | 2 | **Grove connectors** (J17, J18) | TE 2041145-4 | **TE 440055-4** | Mouser 571-440055-4 | HPI 2.0mm R/A THT, same family |
| 8 | 105 | 1 | **Headphone vol pot** (R273) | Bourns PTR902-2015K-B103 | **PTR902-2020K-A103** | Mouser 652-PTR902-2020KA103 | Audio taper, 20mm shaft |
| 9 | — | 1 | **OLED panel** (J25) | — | **REX012864AYAP3N00000** (primary) / MCOT128064B1V-WM (alt) | Mouser 668-REX012864AYAP3N / DigiKey #21322651 | Bare 24-pin FPC panel; J25 ZIF socket is PCBWay-assembled |
| 10 | — | 1 | **Teensy 4.1** (U9) | — | PJRC Teensy 4.1 (SparkFun DEV-20359 = headerless) | Mouser / PJRC / DigiKey | Footprint `reekilib_som:teensy_4.1`, 2.54 mm pitch THT, 24+24+5 pins |
| 10a | — | 2 | **Teensy long-row headers** | — | Samtec **TSW-124-07-T-S** | Mouser 200-TSW12407TS | 24-pin, 2.54 mm pitch, **2.54 mm insulator** (sets Teensy↔Pandore gap), direct-solder stack |
| 10b | — | 1 | **Teensy USB-host header** | — | Samtec **TSW-105-07-T-S** | Mouser 200-TSW10507TS | 5-pin, same family |
| 10c | — | 2 | **USB-D± pogo pins** (J28, J29) | — | Same Sky **CPG-23-SMT-TR** | Mouser 490-CPG-23-SMT-TR | **Spring contacts that tap Teensy's bottom-side USB-D+/D- pads** — NOT USB-C receptacles. Working height 2.50–2.90 mm (normal 2.70 mm), Ø1.80 pad / Ø1.35 hole, hand-soldered |
| 11 | — | 1 | **M.2 NVMe SSD** (J13) | — | User choice | — | Storage for host OS / samples |
| 12 | — | 1 | **M.2 WiFi/BT** (J19) | — | **Intel AX210** (WiFi 6E + BT 5.3) | Amazon.ca | |

---

## Expansion

### Extra Port Headers — AIO/DIO (J15, J16, DNP)

- **BOM part:** Samtec MTSW-108-22-L-T-330-RA (3×8, 2.54mm, right-angle, THT)
- **Alt:** MTSW-110-22-S-T-330-RA (10-pos) — cut to 8-pos before assembly
- **Footprint:** `reekilib_con:HDR254P3X8-THRA`
- **Ordered from:** Samtec direct (ships next day)
- **Power:** these headers carry the **`VRTIO`** rail, which in `pandore-rtmcu.kicad_sch` is a **plain wire straight to `V3P3`** (no regulator, no fuse, no series element) — i.e. 3.3V. Connected to the RTIO MCU (RP2350B).

### UART / I2C breakout headers (J33–J36, on-board)

- 1×3 headers in `pandore-extraport.kicad_sch`: **J34 = UART0, J33 = UART1, J35 = I2C3, J36 = I2C4** (LattePanda Mu buses).
- **No power pin** — each is GND + 2 signals only.

### Grove Connectors (J17, J18, DNP) — I2C sensor ports

- **BOM part:** TE Connectivity 2041145-4 (HPI 2.0mm, R/A, DIP, 4-pos)
- **Installed part:** TE 440055-4 — same AMP HPI 2.0mm family, same R/A through-hole form factor (Mouser: 571-440055-4)
- 4-pin Grove/HY2.0 compatible, wired for **I2C** sensor modules

**Verified electrical design (from `pandore-mgmtmcu.kicad_sch`, 2026-09):**

| Fact | Detail |
|---|---|
| **Voltage** | **3.3V ONLY.** The connector symbol's power pin is literally named `3.3V`, not `VCC` — this is a deliberately 3.3V-native port, not a mistake. |
| **No jumper** | There is **no jumper, 0Ω option, or unpopulated footprint** to switch Grove to 5V. Confirmed against all 13 board jumpers (JMP1–JMP15). To get 5V you must hardware-mod (lift a PTC output leg, jumper to V5) — and the signal pins still need level shifting because RP2350 GPIO is 3.3V-only, not 5V-tolerant. |
| **Power source** | V+ comes from **`VSTBY`** (always-on standby rail, ~3.3V from LDO U27 LDL212DR) through a per-port PTC fuse. **Not** a switched rail. |
| **PTC fuses** | J17 → PTC1, J18 → PTC2. Both **Bel Fuse 0ZCM0010FF2G: 0.1A hold, 6V max.** So each port is budgeted ~100 mA, shared with BIOS / boot control / CPU module / mgmt MCU on the same standby domain. |
| **Signal chain** | RP2350 mgmt-MCU GPIO → **R197** (560Ω quad series array, Panasonic EXB-28V561JX) → **D27** (ESD204DQAR TVS array, 5V clamp) → connector. |
| **No pull-ups on Pandore** | Bus pull-ups are expected on the sensor module (both Grove and Qwiic modules supply their own). |
| **Two independent I2C buses** | Grove **A (J17) = mgmt-MCU I2C0**; Grove **B (J18) = mgmt-MCU I2C1**. Not a shared bus. |
| **Pin mapping** | `PRIM = SCL`, `SEC = SDA`. (A: PRIM=I2C0.SCL/SEC=I2C0.SDA; B: PRIM=I2C1.SCL/SEC=I2C1.SDA.) Signal pins are the connector's D0/D1. |

> ⚠️ **560Ω series resistors constrain I2C pull-up sizing.** R197's 560Ω sits between MCU and connector. When the bus is pulled low, the MCU pin sees `560 × I_pullup` above ground; RP2350 V_IL ≈ 0.99V, so total parallel pull-up must stay **above ~2.4 kΩ**. A single SparkFun Qwiic board (2.2 kΩ pull-ups) is at the edge; two chained will break it. Adafruit STEMMA QT (10 kΩ) is safe. Remedy: cut pull-up jumpers on chained boards, or drop R197 to ~100Ω in rev A1. **Measure on the bench before committing.**

### Sensor ecosystem — use Qwiic / STEMMA QT (NOT M5Stack)

The Grove ports exist to give the average user an easy plug-in sensor solution. **Ecosystem research (2026-09) settled on Qwiic / STEMMA QT / Arduino Modulino, because they are 3.3V-native and match the port Pandore already has.**

**Why not the obvious Grove vendors:**

| Ecosystem | Verdict | Reason |
|---|---|---|
| **M5Stack Units** | ✗ Incompatible as-is | Grove port defined as **5V** power; most Units have an onboard 5V→3.3V LDO feeding the sensor die (e.g. ENV III's QMP6988 maxes at 3.6V). Won't get correct power from Pandore's 3.3V port. Nicely cased ($3–$33), but voltage often absent from their spec tables. |
| **Seeed Grove** | ~ Partial | Grove is **5V-default**; only a **~60-module subset** is 3.3V-safe (cf. Seeed's own 3.3V Grove Base Hat for Raspberry Pi, which documents the same limitation). "3.3V/5V" on a module = **rated supply range, logic follows VCC** — no jumper. Feeding 5V-logic modules 3.3V works for LDO/wide-Vin types but not all. |
| **Qwiic / STEMMA QT / Modulino** | ✓ **Recommended** | **3.3V by definition** (`GND / 3.3V / SDA / SCL`). Always 3.3V logic → **no level shifter, no rail change, no hazard.** I2C-only (no analog/UART ambiguity). 400+ boards across SparkFun (strict 3.3V), Adafruit (3–5V safe), Arduino Modulino (12 modules, C++ **and** MicroPython libs). Two connectors per board = daisy-chainable. |

**"3.3V/5V" mechanisms on dual-rated modules (why there's usually no jumper):**
1. **Wide-Vin chip, logic follows VCC** (e.g. Grove SHT31) — VCC feeds die directly; 5V VCC → 5V logic. *This is the 5V hazard on a shared port.*
2. **Onboard LDO** (e.g. Grove Digital Light XC6206, Human Presence XC6206) — self-regulates to 3.3V, logic always 3.3V. Safest.
3. **Solder pads** (rare, e.g. Grove Lightning AS3935) — bridge pads with iron. Fails the average-user test.

**Connector gap is a $2 cable, works on rev A0 today (unmodified):**
- Adafruit **#4528** — Grove to STEMMA QT / Qwiic / JST SH (100mm)
- SparkFun **PRT-15109** — Qwiic Cable, Grove Adapter (100mm)
- These adapters are **I2C-only** — which is exactly Pandore's Grove wiring. For rev A1, swap J17/J18 footprint to JST SH 1.0mm to make it native.

**Rev A1 recommendations (all verified against schematic):**
- Move Grove V+ off `VSTBY` to a **switched 3.3V** rail (a Qwiic chain of 8–10 sensors at 5–10 mA each lands right on the 100 mA PTC limit). The board already proves the **ETEK ET20162** load-switch pattern (U29–U33, 1A, used on all USB VBUS) — reuse it.
- Drop R197 from 560Ω to ~100Ω to widen the I2C pull-up budget.
- If M5Stack's cased-unit aesthetic is wanted later, that (and only that) justifies a 5V-switchable port **plus** a PCA9306/TXS0102 translator per port — but the 400-board Qwiic catalog with zero-risk wiring is the better default.

### Other

- **UARTDBG** — 3-pin serial debug header
- **USB-C overcurrent detection** (`USB_OC`)

---

## Bringup / Hand-Assembly (per Laurence's bringup doc)

Reference: [doc/test/bringup/pandore_a0_bringup.md](doc/test/bringup/pandore_a0_bringup.md) (commit `4497a3b`, 2026-05-19).

### Mechanical mounting stack-ups

| Mount | Screw | Standoff | Washer | Nut | Board-to-board gap | Notes |
|---|---|---|---|---|---|---|
| **PCB chassis mounts** (×8) | **M3** standard | — | — | — | n/a | `MNT1` is the chassis-ground anchor — populate `R1` + `C1` to connect VSS to chassis at single point |
| **LattePanda Mu** (×4) | **M2.5** machine screw | M2.5 × 5 mm threaded stackable standoff | M2.5 flat washer | M2.5 nut | **5.5 mm** | uxcell M2.5×5mm Male-Female standoff (Amazon); washer compresses ~0.3 mm under torque |
| **Teensy 4.1** (×0 mech, ×53 elec) | — | — | — | — | **~2.54 mm** | No mechanical screws — held entirely by Samtec TSW headers. **Insulator sets the gap.** CPG-23 pogo pins need 2.50–2.90 mm working height (normal 2.70) — TSW-124-07-T-S's 2.54 mm puts the pin near max compression, within spec but tight. Align pogo pins carefully before soldering. |
| **M.2 Key-AE** (WiFi/BT, ×1) | **M2** machine screw | M2 × 2.5 mm standoff (grind a 6 mm down) | — | M2 nut | **2.45 mm** | Heavy tools needed for the grind |
| **M.2 Key-M** (NVMe, ×1) | **M2** machine screw | M2 × 6 mm standoff | M2 flat washer | M2 nut | **6.65 mm** | Standoff body length + washer = ~6.3 mm; M.2 connector compliance absorbs the 0.35 mm |

### Hardware sourcing (Laurence's choices)

| Item | Source |
|---|---|
| M3 chassis screws | McMaster **92832A215** |
| M2.5 standoff/nut/screw kit | XLX assortment, Amazon CA (B07FMV5RMG) |
| M2 standoff/nut/screw kit | Emperoch kit, Amazon CA (B0G13683TS) |
| **M2.5 flat washer** (Mouser) | Essentra **16M02556080** — nylon, 2.7 mm ID / 5.6 mm OD / 0.8 mm thick, 1000-pack |
| **M2 flat washer** (Mouser) | Essentra **MFW010A** — nylon, ~2.2 mm ID / 5.0 mm OD / 0.3 mm thick, 1000-pack |
| Single M2.5 × 5 mm standoff (alt) | uxcell, Amazon CA (B08F21MDT8) |

### Other manual-assembly items

| Item | Part / Notes |
|---|---|
| RTC battery | CR2032 (any source, Amazon CA easy) |
| Manual jumpers (15 total: JMP1–JMP15) | Standard 2.54 mm jumper shunts. JMP15 is special: `PON` power-on jumper. Some need elongated shunts. |
| Encoder (E1) | Bourns PEL12T-4225T-S1024 — manually assembled (cost + sourcing) |
| Audio connectors | J4, J5 (XLR combo), J12 (TRS line out) — hand-soldered |
| Ethernet connectors | J8, J9 (RJE58-188-5441) — hand-soldered |
| RTIO connectors | J15, J16 — hand-soldered, **needs support during soldering** (header strongly overhangs PCB edge) |
| Teensy GPIO expansion | EXP10–EXP13 — hand-soldered |
| Fan headers | J27, J38 (Molex 47053-1000) — PCBWay-assembled, but fan cable's PC-fan plug needs cutting and re-terminating with KK 254 housing (22-01-3047) |

---

## Power Distribution

### Rails

| Rail | Voltage | Current | Purpose |
|------|---------|---------|---------|
| `V12` | 12V | — | LattePanda Mu core |
| `V5` | 5V | **2A budgeted (10W); 3.5A silicon** | From buck U19 (AP63356Q, FB 158k/30k → 5.01V). Digital peripherals, USB VBUS (4 ports ×1A + Teensy 1A = 5A of switch capacity oversubscribing the rail), **fan headers** |
| `V3P3` | 3.3V | 2A budgeted; 3.5A silicon | From buck U20 (AP63356Q, FB 93.1k/30k → 3.28V). MCUs, codec digital, I/O. Also feeds `VRTIO` (hard-wired to V3P3) on the GPIO headers |
| `AV5` | 5V | — | Analog audio supply |
| `AV3P3` | 3.3V | — | Analog audio supply |
| `VM2` | — | — | M.2 slot supply |
| `VMIDI` | — | — | MIDI interface supply |
| `VSTBY` | ~3.3V | — | Standby (from LDO U27 LDL212DR, Vo=3.3/Io=0.1A). Also feeds **Grove ports** J17/J18 via PTC1/PTC2. CR2032 backup. |
| `VCORE` | — | — | Core voltage |
| `48V Phantom` | 48V | 10 mA | Condenser microphone bias |

### Ground Domains

| Ground | Description |
|--------|-------------|
| `VSS` | Primary digital ground |
| `AVSS` | Analog audio ground |
| `VSSISO` | Isolated analog ground |

### DC Input Jack

- **Part:** Same Sky **PJ-063BH** (right-angle through-hole DC barrel jack, schematic in `pandore-power`)
- **Center pin:** **Ø 2.5 mm** (NOT 2.1 mm) — accepts a **5.5 × 2.5 × 11 mm** plug, center positive
- **Ratings:** 24 VDC max, 8 A max, 30 mΩ contact resistance
- **PCB-assembled by PCBWay**

> ⚠️ **PSU compatibility:** Most consumer 12 V/5 A bricks use the **5.5 × 2.1 mm** plug (AAEON EP-PS12V5A60WFJ, Cicor SW3101F-C2, Phihong PPL65W-120, TT Powerpax PSAD65-12-B1). **These will not fit Pandore.** The 5 W/2.1 mm plug's center hole is smaller than PJ-063BH's 2.5 mm center pin.

### Recommended PSU

- **DFRobot FIT1021** (Mouser **426-FIT1021**) — 12 V / 5 A / 60 W wall adapter with **5.5 × 2.5 × 11 mm plug** and interchangeable US/EU/UK heads, ~$22 CAD. Designed by DFRobot as the official adapter for the LattePanda Mu — zero compatibility risk.
- Alternative (if FIT1021 unavailable): **Mean Well GST90A12-P1M** (Mouser 709-GST90A12-P1M, 12 V/6.67 A/80 W, 5.5 × 2.5 mm plug, IEC C14 — needs separate cord). The `-P1M` suffix in Mean Well's catalog = 5.5 × 2.5 mm plug; `-P1J` = wrong (2.1 mm).

### Power ICs (from BOM)

| Part | Designator | Type | Role |
|------|-----------|------|------|
| Diodes AP63356Q | U19, U20 | Synchronous buck, 3.5A | Main DC-DC regulators (V5, V3P3) |
| STM LDL212DR | U13, U14, U27 | Ultra-low-dropout LDO | Local clean supply rails |
| ETEK ET20162 | U29–U33 | 5.5V / 1A current-limit load switch × 5 | USB VBUS switching (U29–U32 = 4 USB-A ports; U33 = Teensy USB host). 1A is a **fixed** limit (no ILIM pin). |
| TI LM5158RTER | U21 | Flyback/boost controller | 48V phantom power supply |
| TI TPS7A4001DGNR | U22 | Ultra-low-noise 40V LDO | Post-regulation of 48V phantom rail |
| Murata NXE2S1212MC-R7 | U12 | **2W** isolated DC/DC, 12V→12V (167 mA) | Isolated 12V for audio analog domain — critical to 114 dB DR spec |

### Protection

- Reverse-polarity protection
- **USB VBUS:** overcurrent handled by the ETEK ET20162 load switches (U29–U33), 1A fixed limit each — **not** the PTC fuses
- **PTC fuses PTC1/PTC2** (Bel Fuse 0ZCM0010FF2G, 0.1A hold, 6V max) protect the **Grove ports** (J17/J18) on the `VSTBY` rail — *corrected: earlier docs said "on USB VBUS", which is wrong*
- Power sequencing managed by Management MCU (RP2350, U4)

### Boot Control

| Signal | Description |
|--------|-------------|
| `~{USBBOOT}` | USB boot enable (active low) |
| `RSTSW` | Reset switch → Management MCU |
| `PWRSW` | Power switch → Management MCU |
| `STATE0`, `STATE3` | System state monitoring |
| `PON` (JMP15) | Power-on jumper |
| `B1`, `B2` | Momentary tactical switches (reset/power) |

Power sequencing uses MOSFETs Q11, Q12, Q14, Q15 (MOSFET_EN-N).

---

## Thermal

- **Dual fan headers:** CPU fan (**J27**) + system fan (**J38**), each with PWM + tachometer
- **Fan header part:** Molex **47053-1000** — KK 254 (Mini-Latch), 2.54 mm pitch, 4-pin, vertical THT, friction lock. **PCBWay-assembled.**
- **Mating female (cable-side) — order if making custom fan cables:**
  - Housing: Molex **22-01-3047** (Mouser 538-22-01-3047) — 4-circuit KK 254 Mini-Latch™ housing
  - Crimp terminals: Molex **08-50-0114** (Mouser 538-08-50-0114) — 22–30 AWG, tin
- **Cable pinout — VERIFIED against `pandore-fan.kicad_sch` (2026-09):** pin 1 = GND, **pin 2 = V5 (5V, NOT 12V)**, pin 3 = Tach, pin 4 = PWM. Power is fed **directly from V5 with no load switch or fuse** between rail and header. J27 and J38 are wired identically.
  - ⚠️ **Correction:** earlier docs claimed "+12V (Yellow)" per the Intel 4-wire spec. **The schematic has no V12 anywhere in the fan sheet — it's 5V.** Consistent with the DFRobot FIT0981 being a 5V cooler. If you re-terminate a *12V PC fan* against the old note it will get 5V and barely spin.
- **Heatsink options:**
  - FIT0981 — Active cooler (fan + heatsink), **5V fan** — **ships with PC-fan plug; cut & re-terminate with 22-01-3047 to mate Pandore's KK 254**
  - FIT0982 — Thin passive heatsink
  - FIT0989 — Fanless heatsink
- **Fan control:** PWM via Management MCU

---

## PCB Specifications

| Parameter | Value |
|-----------|-------|
| Dimensions | 260 mm × 110 mm |
| Layers | 4 (F.Cu / In1 / In2 / B.Cu) |
| Total components | 804 (480 front, 324 back) |
| SMD components | 700 |
| Through-hole | 83 |
| Unique parts | 141 |
| Total pads | 3,161 (2,702 SMD + 459 TH) |
| Vias | 2,217 |
| Drill holes | 2,439 |

---

## Repository Structure

```
pandore/
  AUDIO_PERFORMANCE.md   Audio specs (separate GitHub page)
  README.md              Project overview
  hw/                    Schematics (.kicad_sch) and PCB layout (.kicad_pcb)
  doc/
    arch/                Architecture diagrams (draw.io)
    img/                 Board renders
    reference/           Datasheets, app notes, design guides (PDF)
  lib/                   3D models (.step), KiCad symbols and footprints
  release/               Manufacturing artifacts (Gerbers, BOM, placement, 3D)
```

---

## Schematic Hierarchy

Top-level: `pandore.kicad_sch` → 24 sub-sheets:

**Audio (9 sheets):**
`audio`, `audio-codec`, `audio-inputs`, `audio-inbuf`, `audio-outputs`, `audio-outbuf`, `audio-isolation`, `audio-monitor`, `audio-power`

**Compute (5 sheets):**
`computer`, `cpumod` (LattePanda Mu), `mcu` (RP2350B RTIO), `mgmtmcu` (Management), `rtmcu`

**Power (2 sheets):**
`power`, `audio-power`

**Interface (6 sheets):**
`eth`, `usbport`, `midi`, `display`, `extraport`, `mdot2`

**System (3 sheets):**
`bootctl`, `bios`, `fan`

---

## Component Library

All schematics use the `reekilib` custom symbol/footprint library.

**3D Models (in `lib/`):**
- `LattePanda_Mu.step` — SBC module
- `LattePanda_Mu_H8.0_Horizontal.step` — Horizontal variant (8 mm clearance)
- `FIT0981_Active_cooler.STEP` — Active heatsink/fan
- `FIT0982-Thin-Heatsink.step` — Thin passive heatsink
- `FIT0989-Fanless-Heatsink.step` — Fanless heatsink

**KiCad Libraries:**
- `MCU_Module_LattePanda.kicad_sym` — LattePanda symbol
- `Module_LattePanda.pretty/` — LattePanda footprints (4 mm and 8 mm variants)

---

## Reference Documentation (`doc/reference/`)

| Document | Topic |
|----------|-------|
| RP2350 datasheet | MCU pinout, peripherals, electrical specs |
| Hardware design with RP2350 | PCB layout guidelines, decoupling, routing |
| LattePanda Mu EVA guide | Module pinout, power requirements, I/O mapping |
| Lite Carrier for LattePanda Mu (V2) | Carrier board reference design |
| CS4272 (via SuperAudioBoard docs) | Codec configuration, I2S timing, register map |
| THAT1512 gain configuration (DN138) | Reference design (not used in final BOM) |
| AES129 Designing Mic Preamps | Preamp circuit topology |
| Phantom power (SBOA320A) | 48V phantom PSU with op-amp |
| Ultra-low noise 48V phantom (RAQ-176) | Low-noise phantom supply design |
| Analog Secrets / More Analog Secrets | Analog design best practices |
| `thatmicpre/` (git submodule) | THAT Corp mic preamp reference designs |
| V50 regulator design (WBDesign) | 5V regulator design reference |

---

## Development Notes

### Firmware Targets

See [Software & Firmware Development → Firmware targets](#firmware-targets-recap) for the four targets, the repo, the verified toolchain, pin maps, and the wire protocol.

### Key Design Decisions

- **I2S isolation** prevents digital noise from corrupting audio — the audio domain has separate power (AV3P3/AV5) and ground (AVSS/VSSISO)
- **Teensy 4.1 as bridge** rather than direct I2S to LattePanda Mu — enables class-compliant USB Audio without custom x86 drivers
- **Dual RP2350** separates real-time I/O (latency-critical) from management (power, thermal, boot) — prevents priority inversion
- **48V phantom** is ultra-low-noise by design — critical for condenser microphone sensitivity
- **M.2 Key-M on PCIe x4** — full NVMe bandwidth for recording/sample playback
