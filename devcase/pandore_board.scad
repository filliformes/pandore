// =====================================================================
//  pandore_board.scad  —  Pandore Rev A0: measured board data + ghost
// ---------------------------------------------------------------------
//  Included by pandore_dev_case.scad. Not meant to be opened alone.
//
//  COORDINATES ("board coords", mm)
//      x : 0 .. 260   left  -> right     (= KiCad x - 20)
//      y : 0 .. 110   FRONT -> BACK      (= 150 - KiCad y)
//      z : 0 = PCB TOP surface, + up
//
//  BACK  edge (y = 110) : volume pot, phones, line out, 2x combo, MIDI,
//                         ETH1, HDMI, 2x USB-A stacks, 12 V barrel
//  RIGHT edge (x = 260) : DIO / AIO 3x8 right-angle headers, 2x Grove,
//                         VIN screw terminal
//  FRONT edge (y = 0)   : ETH2, V5/V3.3 screw terminals, PWR/RST buttons,
//                         Teensy GPIO rows (EXP10-12)
//  LEFT  edge (x = 0)   : Teensy 4.1 USB (jack sits 14 mm inside the edge)
//
//  SOURCES
//   * x/y : footprint positions in hw/pandore.kicad_pcb (Rev A0)
//   * z, widths, protrusions : sliced from the friend's assembly
//     (casing/casingPandore.3mf, real vendor models) — every connector
//     position there matched KiCad to 0.01 mm.
//   * parts cross-checked against the /pandore skill (installed parts):
//     PTR902-2020K-A103 pot (20 mm shaft), PEL12T-4225T encoder,
//     RJE58-188-5441 RJ45, TE 440055-4 Grove, MTSW-108 3x8 R/A,
//     PJ-063BH barrel, Mu on 5.5 mm M2.5 standoffs, NVMe on 6.65 mm.
// =====================================================================

PCB_W = 260;
PCB_D = 110;
PCB_T = 1.6;

// ---------------------------------------------------------------------
//  8x M3 chassis holes  [x, y, cover-column diameter (0 = no column)]
//  Column diameters are the largest that clear neighbouring parts.
// ---------------------------------------------------------------------
MOUNTS = [
    [255,   105, 6.0],   // MNT1  back-right (between DC jack and edge)
    [255,     5, 7.0],   // MNT2  front-right
    [183,     5, 7.0],   // MNT3  front (SSD runs just behind it, underneath)
    [ 85,     5, 7.0],   // MNT4  front
    [  5,     5, 7.0],   // MNT5  front-left
    [  5,   105, 0.0],   // MNT6  back-left: pot shaft passes 3.5 mm above -> no column
    [108,   105, 5.5],   // MNT7  between IN1 combo and MIDI OUT (0.3 mm each side)
    [160.1, 105, 7.0]    // MNT8  between MIDI IN and ETH1
];

// ---------------------------------------------------------------------
//  Wall openings.
//  [ name, side, u,
//    bodyShape, bodyA, bodyB, bodyZc,      <- connector face
//    plugShape, plugA, plugB, plugZc,      <- mating plug / overmold
//    prot, label ]
//   u      : x for back/front walls, y for left/right walls
//   circle : A = diameter            rect : A = width, B = height
//   Zc     : centre height above PCB top
//   prot   : how far the CONNECTOR BODY sticks out past the PCB edge.
//            If the body reaches into the wall, the body outline is cut
//            and the cover gets a U-notch so it can drop over it.
//  (clearance is added in the case file)
// ---------------------------------------------------------------------
OPENINGS = [
 // ---------------- BACK ----------------
 ["POT",     "back",   5.9,  "circle", 6.2, 0,    6.53,  "circle", 6.2, 0,    6.53,  9.2, "VOL"],
 ["PHONES",  "back",  19.0,  "rect",   5.0, 5.0,  2.53,  "circle", 8.5, 0,    2.45,  1.8, "PHONES"],
 ["OUT",     "back",  40.52, "rect",  10.94,30.0, 16.01, "rect",  10.94,30.0, 16.01, 8.1, "OUT L/R"],
 ["IN2",     "back",  64.01, "circle",23.8, 0,    15.03, "circle",20.0, 0,    15.03, 9.0, "IN 2"],
 ["IN1",     "back",  91.41, "circle",23.8, 0,    15.03, "circle",20.0, 0,    15.03, 9.0, "IN 1"],
 ["MIDIOUT", "back", 123.9,  "rect",  20.0, 21.1, 10.58, "circle",16.0, 0,    10.6,  0.9, "MIDI OUT"],
 ["MIDIIN",  "back", 144.7,  "rect",  20.0, 21.1, 10.58, "circle",16.0, 0,    10.6,  0.9, "MIDI IN"],
 ["ETH1",    "back", 173.27, "rect",  17.17,14.14, 6.56, "rect",  13.4, 13.0,  7.6,  2.58,"ETH 1"],
 ["HDMI",    "back", 192.4,  "rect",  15.0, 6.0,   3.12, "rect",  19.0, 8.2,   3.26, 1.9, "HDMI"],
 ["USB2",    "back", 212.5,  "rect",  14.5, 15.45, 8.2,  "rect",  15.0, 16.3,  8.3,  2.05,"USB 2"],
 ["USB3",    "back", 230.4,  "rect",  14.5, 15.62, 8.53, "rect",  15.0, 16.3,  8.3,  2.05,"USB 3"],
 ["DC",      "back", 245.8,  "rect",  10.0, 9.0,   4.53, "circle", 9.0, 0,     5.03, 1.0, "12V"],
 // ---------------- RIGHT ---------------
 ["DIO",     "right", 21.81, "rect",  20.4, 8.1,   4.03, "rect",  20.6, 8.6,   4.2,  8.4, "DIO"],
 ["AIO",     "right", 44.69, "rect",  20.4, 8.1,   4.03, "rect",  20.6, 8.6,   4.2,  8.4, "AIO"],
 ["GROVE_B", "right", 63.75, "rect",  10.0, 4.7,   2.33, "rect",  10.4, 5.8,   2.6,  3.73,"B"],
 ["GROVE_A", "right", 77.0,  "rect",  10.0, 4.7,   2.33, "rect",  10.4, 5.8,   2.6,  3.73,"A"],
 ["VIN",     "right", 88.2,  "rect",   0,   0,     0,    "rect",   8.4, 8.5,   5.0,  0,   "VIN"],
 // ---------------- FRONT ---------------
 ["ETH2",    "front",225.68, "rect",  18.2, 15.0,  6.65, "rect",  18.2, 15.0,  6.65, 4.88,"ETH 2"],
 ["TERM",    "front",201.9,  "rect",   0,   0,     0,    "rect",  23.0, 8.0,   5.0,  0,   "5V  3V3"],
 // ---------------- LEFT ----------------
 // Teensy 4.1 USB: jack face is 14 mm inside the board edge, so the
 // hole is sized for the micro-USB plug overmold to reach it.
 ["TEENSY",  "left",  16.02, "rect",   0,   0,     0,    "rect",  12.5, 9.0,   5.5,  0,   "TEENSY"]
];

// Merged DIO+AIO slot (used when merge_io_slot = true): one clean opening
IO_SLOT = ["IO", "right", 33.25, "rect", 45.5, 8.6, 4.2, "rect", 45.5, 8.6, 4.2, 8.4, "DIO     AIO"];

// ---------------------------------------------------------------------
//  Top-side features
// ---------------------------------------------------------------------
ENC_XY      = [233.5, 67.2];     // PEL12T-4225T, vertical, M9 bushing
ENC_TOP     = 25.1;              // shaft tip above PCB top (25 mm shaft)
FAN_XY      = [136.6, 41.0];     // FIT0981 blower intake centre
FAN_D       = 38;                // intake diameter
COOLER_TOP  = 24.9;              // FIT0981 top above PCB top
COOLER_RECT = [112.4, 6.19, 160.75, 75.79];
MU_RECT     = [105.75, 6.2, 165.75, 75.8];   // LattePanda Mu module
MU_Z        = 5.5;                           // 5.5 mm M2.5 standoffs
TEENSY_RECT = [14.13, 6.62, 76.13, 25.42];
TEENSY_Z    = 2.54;                          // TSW insulator gap
SWITCH_H    = 2.5;                           // C&K PTS810 height

// [x, y, label]  — top-actuated tact switches, reached with printed plungers
BUTTONS = [
    [ 92.45,  4.90, "PWR"],   // B1
    [103.60,  4.75, "RST"],   // B2
    [245.47, 54.50, "B3"],    // B3 (near mgmt MCU)
    [245.46, 37.85, "B4"]     // B4 (near RTIO MCU)
];

// [x, y, w, h]  — light windows over status LED clusters
LED_WINDOWS = [
    [127.35,  2.65, 9.5, 3.6],   // D1 D2 D3
    [141.00,  4.45, 4.8, 3.4],   // D34 D35 D43
    [189.00,  3.70, 3.0, 2.6],   // D23
    [214.70,  3.70, 3.0, 2.6],   // D24
    [224.50, 18.40, 2.8, 2.8],   // D5
    [212.60, 63.95, 2.8, 2.8]    // D33
];

// Bottom-side keep-out (M.2 2280 NVMe on J13, 6.65 mm under the PCB)
BOTTOM_KEEPOUTS = [
    [[132, 6.3, -12.6], [218, 30.0, -7.0]]
];
SSD_BOTTOM = -10.4;   // lowest bottom-side part, relative to PCB top

// Top-side tall-part envelope used for clearance warnings
TALLEST_BACK = 31.01;   // NSJ12HF-1 stacked line-out jack
USB_TOP      = 16.34;   // USB-A stacks (under the control deck)

// =====================================================================
//  Ghost board
// =====================================================================
module ghost_board(plugs = false) {
    color([0.30, 0.55, 0.35, 0.9]) import("ghost/ghost_board.stl", convexity = 6);
    if (plugs) color([0.12, 0.12, 0.13]) import("ghost/ghost_plugs.stl", convexity = 6);
    // parts missing from the source assembly
    color([0.10, 0.55, 0.20])
        translate([TEENSY_RECT[0], TEENSY_RECT[1], TEENSY_Z])
            cube([TEENSY_RECT[2] - TEENSY_RECT[0], TEENSY_RECT[3] - TEENSY_RECT[1], 1.6]);
    color([0.8, 0.8, 0.82]) translate([TEENSY_RECT[0] - 0.6, 16.02 - 3.9, TEENSY_Z + 1.6]) cube([5.6, 7.8, 2.8]);
    color([0.9, 0.5, 0.1]) for (b = BUTTONS) translate([b[0] - 2.3, b[1] - 1.6, 0]) cube([4.6, 3.2, SWITCH_H]);
}
