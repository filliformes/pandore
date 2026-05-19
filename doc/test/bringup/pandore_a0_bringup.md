# Pandore A0 bring-up

- [Pandore A0 bring-up](#pandore-a0-bring-up)
  - [Manual Assembly](#manual-assembly)
    - [Mounts \& Mechanic](#mounts--mechanic)
      - [Mounting PCB itself](#mounting-pcb-itself)
      - [SBC - LattePanda mu](#sbc---lattepanda-mu)
      - [Teensy](#teensy)
      - [M.2 key AE](#m2-key-ae)
      - [M.2 key M](#m2-key-m)
    - [Jumpers](#jumpers)
      - [Manual jumper](#manual-jumper)
      - [Chassis connection](#chassis-connection)
    - [Battery](#battery)
    - [Encoder](#encoder)
    - [Connectors](#connectors)
      - [Audio connectors](#audio-connectors)
      - [Ethernet connectors](#ethernet-connectors)
      - [RTIO connectos](#rtio-connectos)
      - [Teensy GPIO expansion](#teensy-gpio-expansion)
  - [Testing](#testing)
    - [Process](#process)
    - [Goals](#goals)
    - [Results](#results)

## Manual Assembly

### Mounts & Mechanic

#### Mounting PCB itself

All **8** PCB mounts are [M3 standard screws][m3_screw_link] and standoff, they are open to many final integration mounting scheme, the board itself should be rigid enough for usage on a desk or semi fixed setup

> Note: only `MNT1` is electrically connected to chassis (the actual electrical connection is not [mounted by default](#chassis-connection))

#### SBC - LattePanda mu

- distance between boards: 5.5mm
- screw type: M2.5

A [M2.5 kit][m25_kit_link] for the nut and screw is the easiest for low-volume

requires 2 mounting stack:

- 1× [threaded stackable standoff M2.5 5mm][m25_standoff_link]
- 1× threaded nut M2.5
- 1× machine screw M2.5
- 1× flat washer M2.5

#### Teensy

- distance between boards: ~2.5mm

The **2** chosen [pogo pin][pogo_pin_link] for USB contact have a working range of [2.5 : 2.9]mm, care should be taken to correctly align those 2 spring contact before soldering down the teensy module

#### M.2 key AE

- distance between boards: 2.45mm
- screw type: M2

requires 1 mounting stack:

- 1× threaded stackable standoff M2 2.5mm (NOT in common kits, ground down a 6mm down to ~2.5mm)
- 1× threaded nut M2
- 1× machine screw M2

> NOTE: This requires heavy tools

#### M.2 key M

- distance between boards: 6.65mm
- screw type: M2

a [kit of M2 standoff][m2_kit_link] and [washers][m2_washer_kit_link] is the easiest approach for low-volume

requires 1 mounting stack:

- 1× threaded stackable standoff M2 6mm
- 1× threaded nut M2
- 1× machine screw M2
- 1× flat washer M2

### Jumpers

#### Manual jumper

A total of **15** manual jumper exist on the board, they all require an additional jumper to be added: [Elongated][jumper_header_long_link], [normal][jumper_header_link]  
The jumper list : JMP1 - JMP15

#### Chassis connection

To connect `VSS` to the chassis the single point of contact should be `MNT1` and `R1`, `C1` should be assembled on the board (see [BOM](/release/pandore_2026-03-19_A0_release.zip) for actual component).  
The connection is intended to be easy to adapt the actual impedance to chassis desired and to channel all currents into a single point of reference.

### Battery

Requires a [CR2032][cr2032_link] to be installed in the socket

### Encoder

Manual assembly of the encoder was chosen to reduce assembly cost and ease sourcing of the exact desired encoder

### Connectors

#### Audio connectors

J4, J5, J12 requires manual assembly

#### Ethernet connectors

J8, J9 requires manual assembly

#### RTIO connectos

J15, J16 requires manual assembly, supports for it during soldering needs to be taken into consideration as it is strongly overhanging outside the PCB.

#### Teensy GPIO expansion

EXP10 - 13 requires manual assembly

---

## Testing

### Process

### Goals

### Results

<!-- link -->

[m3_screw_link]: https://www.mcmaster.com/92832A215/
[jumper_header_link]: https://www.amazon.ca/Gikfun-Micro-Jumper-Arduino-EK1025C/dp/B06XGSZ91M?crid=3HA2RJFKJJH83&dib=eyJ2IjoiMSJ9.XE1VoL3YFsnvT5n9fBXzWOiKnZOh7LnegADqrwdIvO2LqFiMsuBfqZhMN3eAh4g0-wZKhjEHHhwyLQZDT35YLm0mH9BUdBqNrZi92p3ByPNvIj_dtkLEwj3yvjBDtXwPpqrxP8KaSiYuMM2YQgOME5SUW9x2MT1KBw6qJ9Zu_vFBTAW3WhD1hu0k6BHMsH8bc3N8fXlbDy0sZ3UsVg6l-sLoXefIm1uEOh_vpwQCT7fgGeaxNnapC0w32D_aBMyL4BJ6C-busqkoFEwYlWJC8qag1NCH3zTV5HEhNbmpmu0.UR0h5iOWdSOxjbIXXcyVVASNp3uD5F1DsCWhYjNxplk&dib_tag=se&keywords=jumper+header&qid=1779215427&sprefix=jumper+heade%2Caps%2C157&sr=8-25
[jumper_header_long_link]: https://www.amazon.ca/uxcell-2-54mm-Lengthened-Circuit-Connection/dp/B08Y7YJGL1?crid=3HA2RJFKJJH83&dib=eyJ2IjoiMSJ9.XE1VoL3YFsnvT5n9fBXzWOiKnZOh7LnegADqrwdIvO2LqFiMsuBfqZhMN3eAh4g0-wZKhjEHHhwyLQZDT35YLm0mH9BUdBqNrZi92p3ByPNvIj_dtkLEwj3yvjBDtXwPpqrxP8KaSiYuMM2YQgOME5SUW9x2MT1KBw6qJ9Zu_vFBTAW3WhD1hu0k6BHMsH8bc3N8fXlbDy0sZ3UsVg6l-sLoXefIm1uEOh_vpwQCT7fgGeaxNnapC0w32D_aBMyL4BJ6C-busqkoFEwYlWJC8qag1NCH3zTV5HEhNbmpmu0.UR0h5iOWdSOxjbIXXcyVVASNp3uD5F1DsCWhYjNxplk&dib_tag=se&keywords=jumper+header&qid=1779215427&sprefix=jumper+heade%2Caps%2C157&sr=8-7
[m2_kit_link]: https://www.amazon.ca/Emperoch-Spacers-Standoff-Circuit-Computer/dp/B0G13683TS?crid=1CHX5EQ0XT8KF&dib=eyJ2IjoiMSJ9.XBI9B3qG2lppQEIwhbK0R5VNMnEhpmn_0v-rGENSrL_2vIqgdO6sC6QUAjnWmabrAKl6wB-cjcpCc4bf-pY_qabPejPEw50QieHmWlMdlAN5PYgrEd_2wMb3pWyx3DPcJp8jNj8FMwY2_n1YQUfB4vfnRvcMz4FLfCp-CDDVyj4kw_4TS2HBp0Dc5pJVbBZ3TUdz_fEurvlXX5ugiRhJQgXIwytk-58MolfpLbGXTNJjsg59RslSxN5HaGz1RBu1ax_6Ncsn6HkZWis7IE0lmMf-RAipPdmIJ7tQTtNcmjg.bo-vNPjqno2DqJ-S3V2DH2WN-_5qeS3QDgLiia3mL10&dib_tag=se&keywords=m2+standoff+kit&qid=1779216228&sprefix=m2+standof+kit%2Caps%2C110&sr=8-7
[m2_washer_kit_link]: https://www.amazon.ca/Emperoch-Spacers-Standoff-Circuit-Computer/dp/B0G13683TS?crid=1CHX5EQ0XT8KF&dib=eyJ2IjoiMSJ9.XBI9B3qG2lppQEIwhbK0R5VNMnEhpmn_0v-rGENSrL_2vIqgdO6sC6QUAjnWmabrAKl6wB-cjcpCc4bf-pY_qabPejPEw50QieHmWlMdlAN5PYgrEd_2wMb3pWyx3DPcJp8jNj8FMwY2_n1YQUfB4vfnRvcMz4FLfCp-CDDVyj4kw_4TS2HBp0Dc5pJVbBZ3TUdz_fEurvlXX5ugiRhJQgXIwytk-58MolfpLbGXTNJjsg59RslSxN5HaGz1RBu1ax_6Ncsn6HkZWis7IE0lmMf-RAipPdmIJ7tQTtNcmjg.bo-vNPjqno2DqJ-S3V2DH2WN-_5qeS3QDgLiia3mL10&dib_tag=se&keywords=m2+standoff+kit&qid=1779216228&sprefix=m2+standof+kit%2Caps%2C110&sr=8-7
[pogo_pin_link]: https://www.sameskydevices.com/product/interconnect/connectors/pogo-pins/cpg-23-smt-tr
[m25_standoff_link]: https://www.amazon.ca/uxcell-M2-5x5mm-Male-Female-Motherboard-Quadcopter/dp/B08F21MDT8?crid=1TT4AOLQLPDR9&dib=eyJ2IjoiMSJ9.CRnQFFd5CKU2EhYU2zr9HwAqXMQBqL-4lz3RhP5wxPEGWNXAF9YuI6-TH9NVbZ3c5JlVbPw-hK7TLxIGmlUXx4_eE1q88nXqIJKGjglyA4UjvFmMzQ5Yh2x3Z8tHNeMp8kQAvOBnw4OICF5e7cWxsvYMfqtp4Q1JVolYpHJ9PPS8DfN5UO_IMgvjPxHTo8rLkudDochEWmlQqQDXsCN75CkHpM9FsQzUqnJjhPjT9fuKYkpUgZlFCFA07R5AbpJ7FIp9aGPOF74lF_Y_kr0mFPleaReF_vgYnKBWhkSZJXg._GAYZb9oVTPexLicmGIf54-WbDFqq7FILL0_Qgxf4iQ&dib_tag=se&keywords=m2.5+standoff+5mm&qid=1779217516&sprefix=m2+5+standoff+5mm%2Caps%2C110&sr=8-6
[m25_kit_link]: https://www.amazon.ca/XLX-Male-Female-Female-Female-Assortment-Stainless/dp/B07FMV5RMG?crid=1HJ2HERE8FE8Q&dib=eyJ2IjoiMSJ9.HrQpjGa9CN9DrYIfI1LysGNKudk1tSxTPdWGHml6P-Oo3WCm3we6rzIHy-uZSPte7H0S1UVQXa31sKmHWSlyTdHEbS6DfMNIZ5UMaFz09BXm-K6bNKrDesBFVtWxjDtsDE4I6BW_-HMlpYQ-TjvGnJCTAtZgMaslQD3KrfUPKAvdDx2kToYuIZneWbA9MsVav4QOclbVXq1H7MLNP_IGBnh2q1y88TkTFcdCOTFw9JqH_OQ_M5FfH2JCswZoiNI3oj5-zk2tJ8FY8lBIvbgnTIil7yyJIVnXWus5B4rcCJM.2F90r9yApMK_ywBDcXTnfi1qI6L5FOU4xU2NqlKAHlY&dib_tag=se&keywords=m2.5+standoff&qid=1779217719&sprefix=m2+5+standoff%2Caps%2C135&sr=8-6
[cr2032_link]: https://www.amazon.ca/s?k=CR2032&crid=19SXD1OPVG0N3&sprefix=cr2032%2Caps%2C226&ref=nb_sb_noss_1