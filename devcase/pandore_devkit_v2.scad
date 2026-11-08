// =====================================================================
//  PANDORE — FOND DEVKIT V2  (une seule pièce, carte Rev A0)
// ---------------------------------------------------------------------
//  Suggestion d'Alex Burton : un « fond devkit » pour transporter et
//  manipuler la carte sans stress. Une plaque monobloc avec un rebord sur
//  tout le contour, à la hauteur des connecteurs Ethernet. Tous les ports
//  sont ouverts en U vers le haut : on dépose simplement le Pandore dedans.
//  Le rebord protège tout ce qui ne devrait pas s'accrocher au pouce ; les
//  XLR et le haut de la carte dépassent, c'est voulu.
//
//  Pensé pour être manipulé de façon robuste :
//   * parois et plancher de 3 mm ;
//   * nervures triangulaires (qui s'épaississent vers le bas) sur chaque
//     languette mince entre deux ports, ex. entre les deux USB ;
//   * congés au pied des plots ;
//   * côté droit : une seule grande ouverture (DIO/AIO, Grove, VIN) au lieu
//     de languettes de 1,5 mm qui casseraient.
//
//  Fixation : inserts thermiques M2.5 dans les 8 plots (les trous de la
//  carte sont M3, mais on manque de vis M3). Vis M2.5 × 6 tête bombée par
//  le dessus de la carte.
//
//  F5 = aperçu rapide (pour jouer avec les curseurs), F6 = rendu complet
//  (obligatoire avant d'exporter le STL). Fenêtre > Customizer.
//  Données de la carte : pandore_board.scad. Licence CERN-OHL-S-2.0.
// =====================================================================

/* [Vue] */
// Ce qu'on affiche / exporte
partie = "assemblage"; // [assemblage, fond]
// Fantôme de la carte assemblée
voir_carte = true;
// Fantôme des fiches et câbles
voir_fiches = false;
// Couper la vue pour inspecter
coupe = false;
coupe_axe = "y"; // [x, y]
coupe_x = 136; // [-5:1:265]
coupe_y = 60; // [-5:1:120]

/* [Forme] */
// Épaisseur des parois
paroi = 3; // [2:0.1:5]
// Épaisseur du plancher
plancher = 3; // [2:0.1:5]
// Rayon des coins verticaux
rayon_coins = 6; // [1:0.5:20]
// Arrondi (chanfrein) du dessus du rebord
chanfrein_haut = 1.2; // [0:0.1:3]
// Chanfrein du dessous
chanfrein_bas = 1; // [0:0.1:3]
// Hauteur du rebord au-dessus du dessus de la carte (Ethernet = 14,2)
hauteur_rebord = 15; // [6:0.5:35]
// Hauteur des plots : dessous de la carte au-dessus du plancher (le SSD NVMe pend 8,8 mm sous la carte)
hauteur_plots = 11.5; // [9:0.5:25]
// Jeu entre la carte et la paroi intérieure (l'arrière est fixé par l'épaulement des combos)
jeu_gauche = 0.6; // [0.3:0.1:3]
jeu_droite = 0.6; // [0.3:0.1:3]
jeu_avant = 1.0; // [0.3:0.1:6]
jeu_arriere = 2.7; // [2.2:0.1:8]

/* [Ouvertures] */
// Jeu ajouté à chaque ouverture (total, deux côtés)
jeu_ouvertures = 1.0; // [0:0.1:3]
// Rayon au fond des U (évite l'amorce de fissure)
rayon_fond_u = 1.5; // [0.5:0.1:4]
// Côté droit : une seule ouverture continue (DIO, AIO, Grove, VIN)
fusion_droite = true;
// Ouverture pour la micro-USB du Teensy (côté gauche)
port_teensy = true;
// Fente pour les fils des borniers 5 V / 3,3 V (avant)
fente_borniers = true;

/* [Renforts] */
// Nervures triangulaires sur les languettes minces entre deux ports
nervures = true;
// Une languette plus étroite que ça reçoit une nervure
seuil_nervure = 8; // [2:0.5:20]
// Saillie de la nervure en bas (vers l'extérieur)
nervure_bas = 6; // [1:0.5:12]
// Saillie de la nervure en haut du rebord
nervure_haut = 1; // [0:0.25:4]
// Congé au pied des plots
conge_plots = 3; // [0:0.5:6]

/* [Fixation] */
// Diamètre du trou pour l'insert M2.5 (vérifie la valeur recommandée sur l'emballage)
insert_d = 3.6; // [3:0.05:4.5]
// Longueur de l'insert M2.5
insert_long = 4; // [3:0.5:8]
// Diamètre des plots
plot_d = 7.5; // [6:0.5:10]

/* [Impression] */
// Largeur du plateau (QIDI Q2 = 270)
plateau = 270; // [180:1:400]
pieds = true;
pieds_d = 10.5; // [6:0.5:20]
// Aérations sous le SSD NVMe
aerations = true;

/* [Hidden] */
include <pandore_board.scad>

$fa = 6;
$fs = 0.5;
EPS = 0.01;

// ---------------------------------------------------------------- dérivées
gl = jeu_gauche; gr = jeu_droite; gf = jeu_avant; gb = jeu_arriere;
X0 = -gl - paroi;  X1 = PCB_W + gr + paroi;
Y0 = -gf - paroi;  Y1 = PCB_D + gb + paroi;
ZB = -PCB_T - hauteur_plots - plancher;     // dessous du fond
FLOOR_TOP = ZB + plancher;
RIM = hauteur_rebord;                        // dessus du rebord
OUT_W = X1 - X0;  OUT_D = Y1 - Y0;  OUT_H = RIM - ZB;

function side_gap(s) = s == "back" ? gb : s == "front" ? gf : s == "right" ? gr : gl;
// face extérieure / intérieure de chaque paroi, le long de sa normale sortante
function face_out(s) = s == "back" ? Y1 : s == "front" ? -Y0 : s == "right" ? X1 : -X0;

// ---------------------------------------------------------------- ouvertures
function keep_row(r) = (r[0] == "TEENSY") ? port_teensy : (r[0] == "TERM") ? fente_borniers : true;
ROWS = [for (r = OPENINGS) if (keep_row(r)) r];

// le corps du connecteur compte seulement s'il dépasse dans la paroi
function protr(r) = r[11] > side_gap(r[1]) - 0.1;
function half_w(shape, a) = a > 0 ? (a + jeu_ouvertures) / 2 : 0;
function hw(r) = max(protr(r) ? half_w(r[3], r[4]) : 0, half_w(r[7], r[8]));
function bot(shape, a, b, zc) = a <= 0 ? 1e4 : (shape == "circle" ? zc - (a + jeu_ouvertures) / 2 : zc - (b + jeu_ouvertures) / 2);
function zbot(r) = min(protr(r) ? bot(r[3], r[4], r[5], r[6]) : 1e4, bot(r[7], r[8], r[9], r[10]));

// côté droit fusionné : une seule ouverture de la première à la dernière
RIGHT_ROWS = [for (r = ROWS) if (r[1] == "right") r];
RIGHT_LO = min([for (r = RIGHT_ROWS) r[2] - hw(r)]);
RIGHT_HI = max([for (r = RIGHT_ROWS) r[2] + hw(r)]);
RIGHT_BOT = min([for (r = RIGHT_ROWS) zbot(r)]);

// liste [côté, u_bas, u_haut, z_bas] de toutes les ouvertures réelles
SLOTS = concat(
    [for (r = ROWS) if (!(fusion_droite && r[1] == "right")) [r[1], r[2] - hw(r), r[2] + hw(r), zbot(r)]],
    fusion_droite && len(RIGHT_ROWS) > 0 ? [["right", RIGHT_LO, RIGHT_HI, RIGHT_BOT]] : []
);

// tri rapide sur u_bas
function qsort(v) = len(v) <= 1 ? v : let(p = v[floor(len(v) / 2)][1])
    concat(qsort([for (e = v) if (e[1] < p) e]), [for (e = v) if (e[1] == p) e], qsort([for (e = v) if (e[1] > p) e]));

// languettes minces entre deux ouvertures voisines : [côté, centre, largeur]
function tabs_of(s) = let(v = qsort([for (e = SLOTS) if (e[0] == s) e]))
    len(v) < 2 ? [] :
    [for (i = [0 : len(v) - 2]) let(w = v[i + 1][1] - v[i][2])
        if (w > 0.4 && w < seuil_nervure) [s, (v[i][2] + v[i + 1][1]) / 2, w]];
TABS = concat(tabs_of("back"), tabs_of("front"), tabs_of("right"), tabs_of("left"));

// =====================================================================
//  Rapport (console)
// =====================================================================
module rapport() {
    echo(str("FOND DEVKIT V2  ", OUT_W, " x ", OUT_D, " x ", OUT_H, " mm  (+ nervures ", nervures ? nervure_bas : 0, " mm à l'arrière / avant)"));
    if (OUT_W + (nervures && len(tabs_of("right")) + len(tabs_of("left")) > 0 ? nervure_bas : 0) > plateau)
        echo(str("ATTENTION : plus large que le plateau (", plateau, " mm)"));
    if (RIM < 14.2) echo("NOTE : le rebord est plus bas que les prises Ethernet (14,2 mm)");
    if (FLOOR_TOP > SSD_BOTTOM - 1.5) echo("ATTENTION : plots trop courts pour le SSD NVMe sous la carte");
    if ((plot_d - insert_d) / 2 < 1.4) echo("ATTENTION : paroi trop mince autour des inserts");
    echo(str("  nervures : ", len(TABS), " languettes renforcées"));
    echo(str("  fixation : 8 inserts M2.5 (trou ", insert_d, " x ", insert_long + 1,
             " mm) + 8 vis M2.5 x 6 tête bombée, par le dessus de la carte"));
}
rapport();

// =====================================================================
//  Volume extérieur et cavité
// =====================================================================
module outline2d(o) {
    rr = max(rayon_coins + o, 0.2);
    hull() for (x = [X0 - o + rr, X1 + o - rr], y = [Y0 - o + rr, Y1 + o - rr])
        translate([x, y]) circle(r = rr);
}

module outer() {
    rr = rayon_coins; ch = chanfrein_haut; cb = chanfrein_bas;
    hull() for (x = [X0 + rr, X1 - rr], y = [Y0 + rr, Y1 - rr]) translate([x, y, ZB]) {
        if (cb > EPS) cylinder(r1 = rr - cb, r2 = rr, h = cb);
        translate([0, 0, cb]) cylinder(r = rr, h = OUT_H - cb - ch);
        if (ch > EPS) translate([0, 0, OUT_H - ch]) cylinder(r1 = rr, r2 = rr - ch, h = ch);
    }
}

module cavity() {
    translate([0, 0, FLOOR_TOP]) linear_extrude(OUT_H) outline2d(-paroi);
    // petit chanfrein sur l'arête intérieure du rebord (plus doux aux doigts)
    hull() {
        translate([0, 0, RIM - 0.8]) linear_extrude(EPS) outline2d(-paroi);
        translate([0, 0, RIM + EPS]) linear_extrude(EPS) outline2d(-paroi + 0.8);
    }
}

// =====================================================================
//  Ouvertures en U (ouvertes vers le haut)
// =====================================================================
module shape2d(shape, a, b, zc, u, c) {
    if (shape == "circle" && a > 0) translate([u, zc]) circle(d = a + c);
    else if (shape == "rect" && a > 0) let(r = min(rayon_fond_u, (a + c) / 2 - 0.05, (b + c) / 2 - 0.05))
        translate([u, zc]) offset(r = r) square([max(a + c - 2 * r, 0.1), max(b + c - 2 * r, 0.1)], center = true);
}

module u_up() { hull() { children(); translate([0, 400]) children(); } }

module through_wall(side) {
    d = paroi + 2;
    if (side == "back")       translate([0, Y1 + 1, 0])  rotate([90, 0, 0])  linear_extrude(d) children();
    else if (side == "front") translate([0, -gf + 1, 0]) rotate([90, 0, 0])  linear_extrude(d) children();
    else if (side == "right") translate([X1 - d + 1, 0, 0]) rotate([90, 0, 90]) linear_extrude(d) children();
    else if (side == "left")  translate([X0 - 1, 0, 0])  rotate([90, 0, 90]) linear_extrude(d) children();
}

module openings() {
    for (sd = ["back", "front", "right", "left"])
        through_wall(sd) union() {
            for (r = ROWS) if (r[1] == sd && !(fusion_droite && sd == "right")) u_up() union() {
                if (protr(r)) shape2d(r[3], r[4], r[5], r[6], r[2], jeu_ouvertures);
                shape2d(r[7], r[8], r[9], r[10], r[2], jeu_ouvertures);
            }
            if (fusion_droite && sd == "right" && len(RIGHT_ROWS) > 0)
                u_up() let(r = min(rayon_fond_u, 3)) translate([RIGHT_LO + r, RIGHT_BOT + r])
                    offset(r = r) square([RIGHT_HI - RIGHT_LO - 2 * r, 1]);
        }
}

// =====================================================================
//  Nervures : triangle collé à la face extérieure de chaque languette,
//  fin en haut du rebord, épais en bas.
// =====================================================================
module rib(side, u, w) {
    ww = max(w - 0.3, 1.2);
    // repère local : x = le long de la paroi, y = vers l'extérieur, z = haut
    module wedge() hull() {
        translate([-ww / 2, -0.6, ZB]) cube([ww, nervure_bas + 0.6, EPS]);
        translate([-ww / 2, -0.6, RIM - chanfrein_haut - EPS]) cube([ww, nervure_haut + 0.6, EPS]);
    }
    if (side == "back")       translate([u, Y1, 0]) wedge();
    else if (side == "front") translate([u, Y0, 0]) rotate([0, 0, 180]) wedge();
    else if (side == "right") translate([X1, u, 0]) rotate([0, 0, -90]) wedge();
    else if (side == "left")  translate([X0, u, 0]) rotate([0, 0, 90]) wedge();
}

// =====================================================================
//  Plots + inserts M2.5
// =====================================================================
module plots() {
    for (m = MOUNTS) translate([m[0], m[1], FLOOR_TOP - EPS]) {
        cylinder(d = plot_d, h = hauteur_plots + EPS);
        if (conge_plots > 0) cylinder(d1 = plot_d + 2 * conge_plots, d2 = plot_d, h = conge_plots * 1.5);
    }
}
module keepouts() { for (k = BOTTOM_KEEPOUTS) translate(k[0]) cube(k[1] - k[0]); }
module insert_holes() {
    for (m = MOUNTS) translate([m[0], m[1], -PCB_T]) {
        translate([0, 0, -(insert_long + 1)]) cylinder(d = insert_d, h = insert_long + 1 + EPS);
        translate([0, 0, -0.4]) cylinder(d1 = insert_d, d2 = insert_d + 0.8, h = 0.4 + EPS);
    }
}

// =====================================================================
//  Le fond
// =====================================================================
module fond() {
    difference() {
        union() {
            difference() { outer(); cavity(); }
            difference() { plots(); keepouts(); }
            if (nervures) for (t = TABS) rib(t[0], t[1], t[2]);
        }
        openings();
        insert_holes();
        if (pieds) for (x = [X0 + 14, X1 - 14], y = [Y0 + 14, Y1 - 14])
            translate([x, y, ZB - 1]) cylinder(d = pieds_d, h = 1 + 1.2);
        if (aerations)
            for (x = [142 : 6 : 212]) translate([x, 10, ZB - 1])
                hull() { cylinder(d = 3, h = plancher + 2); translate([0, 17, 0]) cylinder(d = 3, h = plancher + 2); }
    }
}

// =====================================================================
//  Vue
// =====================================================================
module section_clip() {
    if (coupe) intersection() {
        children();
        if (coupe_axe == "y") translate([-500, coupe_y, -500]) cube([1000, 500, 1000]);
        else translate([-500 + coupe_x, -500, -500]) cube([500, 1000, 1000]);
    } else children();
}

if (partie == "assemblage") section_clip() {
    color([0.20, 0.21, 0.24]) fond();
    if (voir_carte) ghost_board(voir_fiches);
}
else if (partie == "fond") translate([0, 0, -ZB]) fond();
