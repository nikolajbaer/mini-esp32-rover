// Anime ball-jointed doll, about 9" (226 mm with hair) tall, strung with elastic cord.
//
// Pick what to render with `part`:
//   assembly | exploded
//   head | hair_bob | hair_twintails
//   chest | pelvis
//   upper_arm_r | forearm_r | hand_r | thigh_r | shin_r | foot_r   (and _l)
//   s_hook
// e.g.  openscad -D 'part="chest"' -o stl/chest.stl doll.scad
//
// `hair` picks the hairstyle shown in the assembly.
//
// Axes: the doll faces +y, +z is up, the ground is z = 0. +x is the doll's
// right side. Every part is modelled where it sits in the standing doll; the
// STLs keep that position (the slicer drops them onto the bed).
//
// Stringing (2 mm round elastic):
//   arms   hand hook - forearm - upper arm - across the chest - other arm - hand hook
//   legs   foot hook - shin - thigh - across the pelvis - other leg - foot hook
//   torso  head hook - neck - chest - waist - pelvis, hooked round the leg cord
// The hooks are wire S-hooks caught on printed bars inside the hands, feet and
// head. Take the hair off to reach the head hook.
//
// Every joint is a ball on one part sitting in a cup on the next. The elastic
// pulls the ball into the cup, so cups are never deeper than a hemisphere and
// nothing snaps together.

part = "assembly";
hair = "bob";        // bob | twintails

/* [Fits and stringing] */
wall = 2.0;           // shell wall of hollow parts
fit = 0.25;           // clearance between a ball and its cup
cup_wall = 2.0;       // thickness of the cups
cord_d = 3.6;         // holes the elastic runs through (2 mm cord, doubled where it loops)
hook_bar_d = 1.6;     // bars the S-hooks catch on
stem_clear = 0.8;     // extra room round a stem as the joint swings
slot_frac = 0.6;      // elastic slots in the balls cover this much of the swing; the cord bends the rest

/* [Head] */
head_c = [0, 0, 193.5];   // head origin; the crown is at about z = 222, 226 with hair
cran = [47, 47, 51];      // cranium ellipsoid: width, depth, height
cran_z = 3;               // cranium centre above head_c
cheek_r = 10.6;
cheek_p = [12.9, 7.8, -16.8];  // x is mirrored
chin_r = 5.3;
chin_p = [0, 11.5, -25.2];
ear_p = [0, 0.5, -9];     // x is worked out from the head width
ear_s = [3.2, 6.4, 8.4];

/* [Face] */
eye_style = "engraved";   // engraved | smooth (paint or decals on a blank face)
eye_x = 11.2;
eye_z = -8.4;
eye_w = 11.0;
eye_h = 13.0;
eye_tilt = 4;
iris_d = 8.0;
engrave = 0.45;           // depth of engraved lines
line_w = 0.7;             // width of engraved lines
mouth_w = 4.6;
mouth_z = -20.5;
mouth_smile = 0.9;
nose_z = -15;

/* [Hair seam] */
// The hair is the back and top of the head. The seam is a flat plane from the
// hairline at the front (y, z) to the nape at the back, both relative to head_c.
seam_front = [23, 13];
seam_back = [-23, -12];
hair_t = 4.0;             // hair thickness outside the skin
lip_h = 2.5;              // registration lip on the hair, reaching under the seam
magnet_d = 5.0;           // two 5 x 2 mm disc magnets per side of the seam
magnet_h = 2.0;
boss_d = 9;

/* [Quality] */
$fn = 48;
lock_fn = 16;
lock_steps = 8;

// ----------------------------------------------------------------------------
// Vector helpers

function unit(v) = v / norm(v);
function perp(d) = abs(d.z) < 0.9 ? unit(cross(d, [0, 0, 1])) : unit(cross(d, [1, 0, 0]));
// Rotate v about unit axis k by a degrees (Rodrigues).
function rotv(v, k, a) = v * cos(a) + cross(k, v) * sin(a) + k * (k * v) * (1 - cos(a));
function ang(a, b) = acos(max(-1, min(1, unit(a) * unit(b))));

// Point the +z axis along v.
module orient(v) {
    rotate([0, acos(v.z / norm(v)), atan2(v.y, v.x)]) children();
}
module rod(p, v, r, l) { translate(p) orient(v) cylinder(r = r, h = l); }
module rod2(a, b, r) { hull() { translate(a) sphere(r); translate(b) sphere(r); } }

// Hull of ellipsoids: [[centre, semi-axes], ...], shrunk inward by i.
module blob(list, i = 0) {
    hull() for (e = list)
        translate(e[0]) scale([for (k = e[1]) max(0.3, k - i)]) sphere(1);
}

big = 300;

// ----------------------------------------------------------------------------
// Joints
//
// A joint: [centre, socket axis, ball radius, stem radius, rest stem direction,
//           swing directions].
// The socket axis points out of the cup's mouth, towards the part with the
// ball. The swing directions are the directions the ball's stem can take,
// seen from the socket part; the cup is cut away to let the stem through.

function cone_dirs(d, a, n = 12) =
    concat([d], a == 0 ? [] : [for (i = [0 : n - 1]) rotv(rotv(d, perp(d), a), d, 360 * i / n)]);
function fan_dirs(d, k, a0, a1, n = 8) = [for (i = [0 : n]) rotv(d, k, a0 + (a1 - a0) * i / n)];

function J(c, axis, R, rs, rest, swing) = [c, unit(axis), R, rs, unit(rest), swing];

// Directions of the socket's pole as seen from the ball, over the whole swing:
// where the ball's elastic slot has to reach.
function slot_dirs(j) = [
    for (s = j[5])
        let(k = norm(cross(j[4], s)) < 1e-6 ? perp(j[4]) : unit(cross(j[4], s)))
        rotv(-j[1], k, -slot_frac * ang(j[4], s))
];

// Added to the part that carries the ball.
module ball_add(j) {
    translate(j[0]) sphere(j[2]);
    rod(j[0], j[4], j[3], j[2] + 6);
}
module ball_cut(j) {
    hull() for (d = slot_dirs(j)) rod(j[0], d, cord_d / 2, j[2] + 1);
    rod(j[0], j[4], max(cord_d / 2, j[3] - 1.6), j[2] + 8);
}

// Added to the part that carries the cup; the caller clips it to the body.
module socket_add(j) {
    intersection() {
        translate(j[0]) sphere(j[2] + fit + cup_wall);
        rod(j[0], -j[1], j[2] + fit + cup_wall + 1, j[2] + fit + cup_wall + 1);
    }
    rod(j[0], j[1], j[2] + fit + cup_wall - 0.05, j[2] + 10);  // a hair thinner: no tangent faces
}
module socket_cut(j) {
    translate(j[0]) sphere(j[2] + fit);
    rod(j[0], j[1], j[2] + fit, 40);                       // way in for the ball
    hull() for (d = j[5]) rod(j[0], d, j[3] + stem_clear, 40);  // swing
    rod(j[0], -j[1], cord_d / 2, j[2] + fit + cup_wall + 2); // elastic
}

// ---- the joints of the standing doll. s = +1 right, -1 left.
X = [1, 0, 0]; Y = [0, 1, 0]; Z = [0, 0, 1];

neck_j = J([0, -3, 177.5], -Z, 6.5, 5.2, -Z, cone_dirs(-Z, 28));
waist_j = J([0, 0, 125], Z, 9, 7, Z, cone_dirs(Z, 18));
function shoulder_j(s) = let(ax = unit([s * 0.7, 0, -0.7]))
    J([s * 17, 0, 153], ax, 5.5, 3.8, [s * 0.3, 0, -1], cone_dirs(ax, 52));
function elbow_j(s) = J([s * 20, 0, 122], Z, 4.5, 3.2, Z,
    concat(cone_dirs(Z, 8), fan_dirs(Z, X, 0, -120)));
function wrist_j(s) = J([s * 21, 0, 94], -Z, 3.5, 2.4, -Z, cone_dirs(-Z, 40));
function hip_j(s) = J([s * 9.5, 0, 99], -Z, 7, 5.2, -Z,
    concat(cone_dirs(-Z, 25), fan_dirs(-Z, X, 0, 65)));
function knee_j(s) = J([s * 8, 0, 57], Z, 6, 4.4, Z,
    concat(cone_dirs(Z, 8), fan_dirs(Z, X, 0, 115)));
function ankle_j(s) = J([s * 7.5, 0, 11], -Z, 4.5, 3.0, -Z,
    concat(cone_dirs(-Z, 25), fan_dirs(-Z, X, -35, 35)));

// A part: outer blobs, the joints whose ball it carries, the joints whose cup
// it carries, and extra solids (hook bars and the like).
module jointed(outer, balls, cups) {
    difference() {
        union() {
            difference() {
                blob(outer);
                difference() {
                    blob(outer, wall);
                    for (j = balls) translate(j[0]) sphere(j[2] + 1);
                }
            }
            for (j = balls) ball_add(j);
            intersection() {
                blob(outer);
                union() for (j = cups) socket_add(j);
            }
            children();
        }
        for (j = balls) ball_cut(j);
        for (j = cups) socket_cut(j);
    }
}

// A bar across a pocket for an S-hook: pocket centre p, bar along axis k.
module hook_pocket(p, k, size) {
    translate(p) cube(size, center = true);
}
module hook_bar(p, k, len) {
    rod(p - k * len / 2, k, hook_bar_d / 2, len);
}

// ----------------------------------------------------------------------------
// Body

chest_shape = [
    [[0, 0, 148], [14, 9.5, 12]],
    [[0, 0, 136], [12, 8.5, 9]],
    [[0, 1, 152], [15, 8, 6]],
    [[14, 0, 154], [5, 5, 5]],
    [[-14, 0, 154], [5, 5, 5]],
    [[0, -1, 160], [5.5, 5, 4]],
];
module chest() {
    jointed(chest_shape, [neck_j, waist_j], [shoulder_j(1), shoulder_j(-1)])
        rod([0, -3, 158], Z, neck_j[3], 18);   // neck
}

pelvis_shape = [
    [[0, 0, 112], [15, 10.5, 9]],
    [[0, 0, 104], [16.5, 11, 8]],
    [[0, -1, 98], [12, 9, 5]],
    [[0, 0, 120], [12, 9, 4]],
];
module pelvis() { jointed(pelvis_shape, [], [waist_j, hip_j(1), hip_j(-1)]); }

function upper_arm_shape(s) = [
    [[s * 19, 0, 145], [5.5, 5.5, 6]],
    [[s * 19.5, 0, 130], [4.5, 4.5, 7]],
];
module upper_arm(s) { jointed(upper_arm_shape(s), [shoulder_j(s), elbow_j(s)], []); }

function forearm_shape(s) = [
    [[s * 20, 0, 118], [5.2, 5.2, 5]],
    [[s * 20.5, 0, 106], [4.2, 4.2, 8]],
    [[s * 21, 0, 97], [4, 4, 3.5]],
];
module forearm(s) { jointed(forearm_shape(s), [], [elbow_j(s), wrist_j(s)]); }

// Relaxed mitten hand, palm towards the body. Solid apart from the hook pocket.
function hand_shape(s) = [
    [[s * 21.5, 0, 86], [2.9, 5.2, 5.5]],
    [[s * 21.5, 0.6, 78], [2.4, 4.6, 4.5]],
    [[s * 20.3, 4.2, 85], [1.9, 1.9, 3.8]],
];
module hand(s) {
    j = wrist_j(s);
    p = [s * 21.5, 0, 87];
    difference() {
        union() { blob(hand_shape(s)); ball_add(j); }
        ball_cut(j);
        difference() {
            hook_pocket(p, Y, [3.2, 6, 6]);
            hook_bar(p, Y, 7);
        }
    }
}

function thigh_shape(s) = [
    [[s * 9.5, 0, 90], [8, 8.5, 9]],
    [[s * 8.5, 0, 72], [6.5, 7, 8]],
    [[s * 8, 0, 62], [5.5, 6, 5]],
];
module thigh(s) { jointed(thigh_shape(s), [hip_j(s), knee_j(s)], []); }

function shin_shape(s) = [
    [[s * 8, 0, 53], [6.6, 7, 6]],
    [[s * 7.8, -1, 40], [5.5, 6.5, 9]],
    [[s * 7.5, 0, 22], [3.8, 4.2, 6]],
    [[s * 7.5, 0, 14], [5, 5.2, 5]],
];
module shin(s) { jointed(shin_shape(s), [], [knee_j(s), ankle_j(s)]); }

function foot_shape(s) = [
    [[s * 7.5, -3, 5], [4.5, 5, 5]],
    [[s * 7.5, 6, 5], [5, 8, 5]],
    [[s * 7.5, 16, 3.5], [4.5, 5, 3.5]],
];
module foot(s) {
    j = ankle_j(s);
    p = [s * 7.5, 0, 3.6];
    difference() {
        union() { blob(foot_shape(s)); ball_add(j); }
        ball_cut(j);
        difference() {
            hook_pocket(p, X, [6, 6, 3.6]);
            hook_bar(p, X, 7);
        }
        translate([-big / 2, -big / 2, -big]) cube(big);   // flat sole
    }
}

// ----------------------------------------------------------------------------
// Head (head-local coordinates: origin head_c)

module skull(i = 0) {
    hull() {
        translate([0, 0, cran_z]) scale(cran / 2 - [i, i, i]) sphere(1);
        for (s = [-1, 1])
            translate([s * cheek_p.x, cheek_p.y, cheek_p.z]) sphere(max(0.3, cheek_r - i));
        translate(chin_p) sphere(max(0.3, chin_r - i));
    }
}
module shell(o, i) { difference() { skull(o); skull(i); } }

// Seam plane.
seam_p1 = [0, seam_front[0], seam_front[1]];
seam_p2 = [0, seam_back[0], seam_back[1]];
seam_n = unit(cross(X, seam_p1 - seam_p2));     // points up and back, into the hair
seam_v = unit(seam_p1 - seam_p2);              // along the seam, forward
seam_o = (seam_p1 + seam_p2) / 2;
module hair_side(off = 0) {
    translate(seam_o + seam_n * off) orient(seam_n) translate([-big / 2, -big / 2, 0]) cube(big);
}
module face_side(off = 0) {
    translate(seam_o + seam_n * off) orient(-seam_n) translate([-big / 2, -big / 2, 0]) cube(big);
}

// Where the seam plane meets the cranium, going from the seam's middle along d.
function in_cran(p) =
    pow(p.x / (cran.x / 2), 2) + pow(p.y / (cran.y / 2), 2) + pow((p.z - cran_z) / (cran.z / 2), 2) <= 1;
function rim_t(d, lo = 0, hi = 60, n = 20) =
    n == 0 ? lo : let(m = (lo + hi) / 2)
        in_cran(seam_o + d * m) ? rim_t(d, m, hi, n - 1) : rim_t(d, lo, m, n - 1);
// Two magnets, at the front and back of the seam, set in from the skin.
boss_at = [for (d = [seam_v, -seam_v]) seam_o + d * (rim_t(d) - wall - boss_d / 2 + 1)];

head_neck_j = J(neck_j[0] - head_c, neck_j[1], neck_j[2], neck_j[3], neck_j[4], neck_j[5]);

function face_half_width(z) =
    max(cran.x / 2 * sqrt(max(0, 1 - pow((z - cran_z) / (cran.z / 2), 2))),
        cheek_p.x + sqrt(max(0, pow(cheek_r, 2) - pow(z - cheek_p.z, 2))));

module ear(s) {
    x = s * (face_half_width(ear_p.z) - 0.8);
    translate([x, ear_p.y, ear_p.z]) difference() {
        scale(ear_s / 2 + [ear_s.x / 2, 0, 0]) sphere(1, $fn = 32);
        translate([s * ear_s.x * 0.9, 0.6, 0])
            scale([ear_s.x * 0.5, ear_s.y * 0.28, ear_s.z * 0.3]) sphere(1, $fn = 24);
        translate([-s * 20 - s * 0.6, 0, 0]) cube(40, center = true);
    }
}

// A line engraved into the face, projected along +y. pts in x-z.
module face_line(pts, w = line_w) {
    for (i = [0 : len(pts) - 2]) hull() for (p = [pts[i], pts[i + 1]])
        translate([p[0], 0, p[1]]) rotate([-90, 0, 0]) cylinder(d = w, h = 40, $fn = 12);
}
function eye_pts(s, grow = 0, n = 28) = [
    for (i = [0 : n]) let(a = 360 * i / n,
        x0 = (eye_w / 2 + grow) * cos(a), z0 = (eye_h / 2 + grow) * sin(a),
        t = s * eye_tilt)
        [s * eye_x + x0 * cos(t) - z0 * sin(t), eye_z + x0 * sin(t) + z0 * cos(t)]
];
function circle_pts(c, r, n = 24) = [for (i = [0 : n]) [c[0] + r * cos(360 * i / n), c[1] + r * sin(360 * i / n)]];
function arc_pts(w, z, sag, n = 8) = [for (i = [0 : n]) let(x = -w / 2 + w * i / n)
    [x, z - sag * (1 - pow(2 * x / w, 2))]];

module face_engraving() {
    if (eye_style == "engraved") for (s = [-1, 1]) {
        face_line(eye_pts(s));
        // heavier upper lash line
        face_line([for (p = eye_pts(s, 0.4)) if (p[1] > eye_z + eye_h * 0.15) p], line_w * 1.8);
        face_line(circle_pts([s * eye_x, eye_z - 0.6], iris_d / 2));
    }
    face_line(arc_pts(mouth_w, mouth_z, mouth_smile));
}

module head() {
    j = head_neck_j;
    bar_z = j[0].z + j[2] + fit + cup_wall + 3;
    translate(head_c) difference() {
        union() {
            intersection() { shell(0, wall); face_side(); }
            for (s = [-1, 1]) ear(s);
            // nose: a small bump on the skin
            intersection() {
                skull(-0.8);
                translate([0, 0, nose_z]) rotate([-90, 0, 0]) scale([1.3, 1, 1]) cylinder(r = 1, h = 40, $fn = 20);
            }
            // neck cup, hung from a tube down to the opening under the head
            intersection() { skull(); face_side(); socket_add(j); }
            // hook bar over the cup, on two legs
            for (sx = [-1, 1]) rod2([sx * 5, j[0].y, bar_z], [sx * 5, j[0].y, j[0].z + 2], 1.2);
            rod2([-5, j[0].y, bar_z], [5, j[0].y, bar_z], hook_bar_d / 2);
            // magnet bosses
            for (b = boss_at) intersection() {
                rod(b, -seam_n, boss_d / 2, 12);
                skull(0.01);
            }
        }
        socket_cut(j);
        face_engraving_cut();
        for (b = boss_at) magnet_pocket(b, -seam_n);
        hair_side();
    }
}
module face_engraving_cut() { difference() { face_engraving(); skull(engrave); } }
module magnet_pocket(b, d) { rod(b - d * 0.01, d, magnet_d / 2 + 0.1, magnet_h + 0.15); }

// ----------------------------------------------------------------------------
// Hair

// Half-width scale of the head at height z: the cranium ellipse above its
// centre, full width below it (the cheeks keep the head wide down there).
function kz(z) = z >= cran_z ? sqrt(max(0.05, 1 - pow((z - cran_z) / (cran.z / 2), 2))) : 1;
// Point on the head at azimuth az (0 = front, 90 = doll's right), height z,
// `off` outside the skin.
function surf(az, z, off) = [(cran.x / 2 * kz(z) + off) * sin(az), (cran.y / 2 * kz(z) + off) * cos(az), z];
function elev(z) = z > cran_z ? asin(min(0.95, (z - cran_z) / (cran.z / 2))) : 0;

// A lock of hair laid on the head: root at (az, z0), tip at z1. Width w
// narrows to a point, thickness th to a third. `rise` stands it proud of the
// hair underneath, `curl` lifts the tip off the head, `sway` turns the tip
// round the head by that many degrees.
module lock(az, z0, z1, w, th = hair_t, curl = 0, sway = 0, rise = 0.8) {
    n = lock_steps;
    function thick(t) = th * (1 - 0.66 * t);
    function p(t) = let(a = az + sway * t * t, z = z0 + (z1 - z0) * t + curl * 0.5 * pow(t, 3))
        [surf(a, z, thick(t) / 2 + rise * (1 - t) + curl * t * t), a, elev(z)];
    for (i = [0 : n - 1]) hull() for (t = [i / n, (i + 1) / n]) {
        q = p(t);
        translate(q[0]) rotate([0, 0, -q[1]]) rotate([q[2], 0, 0])
            scale([max(0.4, w * (1 - t * t)) / 2, thick(t) / 2,
                   max(0.8, w * (1 - t * t)) / 2 + abs(z1 - z0) / n / 2])
                sphere(1, $fn = lock_fn);
    }
}

// A free-hanging ribbon through points, for tails. Widths and thicknesses
// taper linearly from the first to the last point.
module ribbon(pts, w0, w1, t0, t1) {
    n = len(pts) - 1;
    for (i = [0 : n - 1]) hull() for (k = [i, i + 1]) {
        f = k / n;
        translate(pts[k]) scale([(w0 + (w1 - w0) * f) / 2, (t0 + (t1 - t0) * f) / 2, (w0 + (w1 - w0) * f) / 2])
            sphere(1, $fn = lock_fn);
    }
}

// Everything every hairstyle shares: the cap over the back and top of the
// head, the lip that locates it on the seam, and the magnet bosses.
module hair_cap(locks_below = true) {
    translate(head_c) difference() {
        union() {
            intersection() { shell(-hair_t, wall); hair_side(); }
            // lip under the seam, inside the face's wall, joined to the cap
            // by a ring just above the seam
            difference() {
                union() {
                    intersection() {
                        shell(wall + fit, wall + fit + 1.2);
                        hair_side(-lip_h);
                        face_side(2);
                    }
                    intersection() {
                        shell(wall - 0.01, wall + fit + 1.2);
                        hair_side();
                        face_side(2);
                    }
                }
                for (b = boss_at) rod(b - seam_n * 20, seam_n, boss_d / 2 + fit, 40);
            }
            for (b = boss_at) intersection() {
                rod(b, seam_n, boss_d / 2, 12);
                skull(wall / 2);
            }
            difference() {
                children();
                skull(-fit);
            }
        }
        for (b = boss_at) magnet_pocket(b, seam_n);
        skull(wall + fit + 1.2);
    }
}

// Bangs across the forehead: n locks spread over +-spread degrees, tip
// heights cycled from tips.
module bangs(n = 9, spread = 62, root = 22, tips = [0, -3, 1, -4, 0.5, -4, 1, -3, 0], w = 12) {
    for (i = [0 : n - 1]) {
        a = -spread + 2 * spread * i / (n - 1);
        lock(a, root, tips[i % len(tips)], w, curl = 1.6, sway = -sign(a) * 6);
    }
}

// Locks from the crown down the back to the nape, flicking out at the tips.
module back_locks(n = 11, tip = -26, flick = 5) {
    for (i = [0 : n - 1]) {
        a = 180 - 125 + 250 * (i + 0.5) / n;
        lock(a, cran_z + cran.z / 2 - 4, tip + (i % 2) * 3, 13, curl = flick,
             sway = (a < 180 ? -1 : 1) * 8);
    }
}

module side_locks(len = -30, flick = 4) {
    for (s = [-1, 1]) {
        lock(s * 74, 12, len, 10, curl = flick, sway = s * 6);
        lock(s * 88, 12, len * 0.75, 9, curl = flick, sway = s * 10);
        lock(s * 60, 14, len * 0.55, 8, curl = flick * 0.6, sway = -s * 6);
    }
}

module hair_bob() {
    hair_cap() { bangs(); side_locks(); back_locks(); }
}

// Twin tails tied high at the sides of the head.
tail_root = [24, -6, 12];
module tail(s) {
    r = [s * tail_root.x, tail_root.y, tail_root.z];
    pts = [for (i = [0 : 10]) let(t = i / 10)
        r + [s * (6 + 12 * t - 6 * t * t), -6 * t, -70 * t + 8 * t * t * (1 - t)]];
    ribbon(pts, 14, 1.5, 9, 2);
    ribbon([for (p = pts) p + [s * 1.5, -2.5, 3]], 10, 1, 7, 1.5);
    // hair tie
    translate(r + [s * 2.5, 0, 0]) rotate([0, 90, 0])
        rotate_extrude($fn = 32) translate([5, 0]) circle(1.6, $fn = 12);
}
module hair_twintails() {
    hair_cap() {
        bangs(spread = 58, tips = [-2, -5, -1, -6, -1, -6, -1, -5, -2]);
        side_locks(len = -24, flick = 2);
        back_locks(tip = -20, flick = 3);
        for (s = [-1, 1]) tail(s);
    }
}

module hair_piece(style) {
    if (style == "twintails") hair_twintails(); else hair_bob();
}

// ----------------------------------------------------------------------------
// S-hook to bend from wire is better; this printable one is for testing.
module s_hook() {
    for (s = [-1, 1]) translate([0, s * 2.0, 0]) rotate([0, 0, s > 0 ? 0 : 180])
        rotate_extrude(angle = 220, $fn = 32) translate([2.2, 0]) circle(0.6, $fn = 12);
    // spine joining the two curls
    let(e = [2.2 * cos(220), 2.0 + 2.2 * sin(220), 0]) rod2(e, -e, 0.6);
}

// ----------------------------------------------------------------------------
// Output

skin = [1.0, 0.88, 0.82];
hairc = [0.55, 0.62, 0.78];

module body(e = 0) {
    color(skin) {
        translate([0, 0, 2 * e]) chest();
        pelvis();
        for (s = [-1, 1]) {
            translate([s * e, 0, 2 * e]) upper_arm(s);
            translate([s * 1.5 * e, 0, 1 * e]) forearm(s);
            translate([s * 2 * e, 0, 0]) hand(s);
            translate([0, 0, -e]) thigh(s);
            translate([0, 0, -2 * e]) shin(s);
            translate([0, 0, -3 * e]) foot(s);
        }
        translate([0, 0, 3 * e]) head();
    }
    color(hairc) translate([0, -e, 4 * e]) hair_piece(hair);
}

if (part == "assembly") body(0);
else if (part == "exploded") body(12);
else if (part == "head") head();
else if (part == "hair_bob") hair_bob();
else if (part == "hair_twintails") hair_twintails();
else if (part == "chest") chest();
else if (part == "pelvis") pelvis();
else if (part == "upper_arm_r") upper_arm(1);
else if (part == "upper_arm_l") upper_arm(-1);
else if (part == "forearm_r") forearm(1);
else if (part == "forearm_l") forearm(-1);
else if (part == "hand_r") hand(1);
else if (part == "hand_l") hand(-1);
else if (part == "thigh_r") thigh(1);
else if (part == "thigh_l") thigh(-1);
else if (part == "shin_r") shin(1);
else if (part == "shin_l") shin(-1);
else if (part == "foot_r") foot(1);
else if (part == "foot_l") foot(-1);
else if (part == "s_hook") s_hook();
