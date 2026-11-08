# Fond devkit V2 (OpenSCAD)

Un fond monobloc pour transporter et manipuler le Pandore Rev A0 sans stress. C'est une suggestion d'Alex Burton : on dépose simplement la carte dans une plaque à rebord, sans couvercle.

- **Rebord sur tout le contour**, à la hauteur des prises Ethernet (15 mm au-dessus de la carte). Il protège tout ce qui ne devrait pas s'accrocher au pouce. Les XLR et le haut de la carte dépassent, c'est voulu.
- **Ports ouverts en U vers le haut**, pour déposer et retirer la carte sans rien démonter.
- **Pensé pour être manipulé de façon robuste.** Parois et plancher de 3 mm. Chaque languette mince entre deux ports, par exemple entre les deux USB, a une nervure en losange : saillie maximale (6 mm) à la hauteur de la carte, là où la languette prend racine et casserait, puis elle se résorbe pour affleurer la paroi au bas du fond. Les plots ont un congé à leur pied.
- **Côté droit :** une seule grande ouverture pour DIO, AIO, Grove et VIN, au lieu de languettes de 1,5 mm qui casseraient.
- **Aucun texte**, ni sur les faces ni dessous.

## Fichiers

| Fichier | Rôle |
|---|---|
| `pandore_devkit_v2.scad` | Le fond, avec tous les curseurs |
| `pandore_board.scad` | Données mesurées de la carte : connecteurs, trous de fixation, zones à éviter |
| `stl/pandore_devkit_v2_fond.stl` | STL prêt à imprimer, réglages par défaut |
| `ghost/` | Fantôme de la carte pour l'aperçu, local seulement (non publié) |

Sans le dossier `ghost/`, le fond s'affiche quand même, simplement sans la carte.

## Ouvrir

1. Ouvre `pandore_devkit_v2.scad` dans OpenSCAD.
2. Active **Fenêtre > Customizer** : tous les curseurs sont en français, rangés par onglet.
3. **F5** pour l'aperçu, **F6** pour le rendu complet avant d'exporter le STL. Le rendu prend environ 1 min 30.

Le STL des réglages par défaut est déjà dans `stl/pandore_devkit_v2_fond.stl`.

## Fixation

La carte se visse sur les 8 plots avec des **inserts thermiques M2.5**. Les trous de la carte sont M3, mais on manque de vis M3 ; une vis M2.5 passe sans problème.

| Pièce | Qté | Où |
|---|---|---|
| Insert thermique M2.5, 4 mm de long | 8 | Dans le haut de chaque plot, posé au fer par le dessus, fond à plat |
| Vis M2.5 × 6 tête bombée | 8 | Par le dessus de la carte, dans les inserts |
| Patins adhésifs Ø10 | 4 | Dans les creux sous le fond |

Le trou d'insert fait **3,6 mm de diamètre et 5 mm de profondeur** (4 mm d'insert plus 1 mm pour la matière déplacée). Les fabricants ne recommandent pas tous le même perçage pour le M2.5 : vérifie la valeur sur l'emballage de tes inserts et ajuste `insert_d` (et `insert_long`) avant d'imprimer. L'insert doit affleurer le dessus du plot, car la carte repose directement dessus.

Au plot MNT6 (arrière gauche), l'axe du potentiomètre de volume passe à 3,5 mm au-dessus de la carte : une tête bombée M2.5 (environ 1,4 mm) passe dessous.

## Impression (QIDI Q2)

- **Dimensions :** 267,2 × 119,7 × 31,1 mm, plus 6 mm de nervures à l'arrière et à l'avant à la hauteur de la carte (rien ne dépasse au plateau). Ça tient sur le plateau de 270 mm de la Q2. Il reste peu de marge en largeur : désactive jupe et bordure.
- **Orientation :** à plat sur le plancher, tel qu'exporté. Aucun support : les U sont ouverts vers le haut, et le dessous des nervures ne fait que 22° avec la verticale (la console avertit si un réglage dépasse 45°).

## Réglages utiles

| Curseur | Effet |
|---|---|
| `hauteur_rebord` | Hauteur du rebord au-dessus de la carte (14,2 = dessus des prises Ethernet) |
| `seuil_nervure` | Les languettes plus étroites que ça reçoivent une nervure |
| `nervure_max`, `nervure_haut` | Saillie de la nervure au plus large et en haut du rebord |
| `nervure_z_max` | Hauteur du plus large, par rapport au dessus de la carte (0 = carte ; les fonds des U sont entre −2,3 et +2,9 mm) |
| `paroi`, `plancher` | Épaisseurs |
| `fusion_droite` | Une seule ouverture côté droit, ou une par connecteur |
| `insert_d`, `insert_long` | Taille des inserts M2.5 |

La console liste les dimensions, le nombre de languettes renforcées et la quincaillerie à chaque F5 ou F6.
