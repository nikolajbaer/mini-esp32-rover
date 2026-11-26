// Chibi doll head - parametric, 3D-printable, modelled on the layout of a
// small vinyl "chibi doll" head (Nendoroid-Doll-style).
//
// Pick what to render with `part`:
//   assembly | exploded | section | face | eyes | holder | hair_front | hair_back
// e.g.  openscad -D 'part="face"' -o stl/face.stl head.scad
//
// The head comes apart the same way as the reference head:
//   face        skin shell: face, cheeks, chin, ears. Open at the back.
//   eyes        two eye discs joined by a bridge, seen through the eye holes.
//   holder      plate that clamps the eyes from behind, with the neck socket
//               (a ball cup with a slot underneath) on a box behind it.
//   hair_front  top cap with bangs and side locks; sits over the face.
//   hair_back   back of the head; the face's rear tongue slides into it.
//   pins        hair_front and hair_back are pinned together with three
//               short pieces of 1.75 mm filament.
//
// Axes: +x is the doll's left, +y forward (the way the face looks), +z up.
// The origin is the centre of the cranium. All sizes in mm.
//
// Sizes marked "MEASURE" were estimated from photos of the reference parts on
// 5 mm graph paper, so they are only good to about +-1 mm. Check them with
// calipers on the original before relying on a fit, especially the neck socket.

part = "assembly";

/* [Head shape] */
// Cranium: an ellipsoid. Width (x), depth (y), height (z) of the full ellipsoid.
cran_w = 23;          // MEASURE: face shell is ~23 mm across at the temples
cran_d = 23;
cran_h = 25;
cran_z = 1.5;         // centre height of the cranium above the origin
// Cheeks: two spheres hulled onto the cranium. Bigger, lower and further
// forward = rounder, more baby-like face.
cheek_r = 5.2;
cheek_x = 6.3;        // from the centre line
cheek_y = 3.8;
cheek_z = -8.2;
// Chin: a small sphere. Raise chin_y for a pointier, more grown-up face.
chin_r = 2.6;
chin_y = 5.6;
chin_z = -12.3;
// Ears
ear = true;
ear_size = [1.6, 3.2, 4.2]; // thickness out from the head, depth, height
ear_y = 0.2;
ear_z = -4.2;

/* [Shells and fits] */
wall = 1.2;           // face shell and hair inner wall
hair_t = 3.0;         // hair thickness outside the skin
split_y = -1.0;       // face / back-of-head seam, measured along y
lap = 3.0;            // how far the face's tongue reaches into hair_back
fit = 0.15;           // clearance in slip fits; raise for FDM (0.25)
pin_d = 1.75;         // filament used as pins
pin_len = 7;          // total pin length (half in each hair part)

/* [Eyes] */
eye_mode = "insert";  // "insert" = holes + separate eye discs, "painted" = no holes, engraved outline
eye_x = 5.6;          // MEASURE: centre-to-centre is 2 * eye_x (~11 mm on the reference)
eye_z = -4.2;
eye_w = 5.6;          // hole width
eye_h = 6.6;          // hole height
eye_tilt = 4;         // degrees; positive tilts the outer corners up
eye_round = 1.0;      // 1 = ellipse, 0.6..0.9 flattens the top into a lid line
eye_seat_y = 7.2;     // flat seat for the eye discs, inside the face
eye_plug = 1.8;       // how far the eye disc reaches forward into its hole
eye_lip = 1.2;        // how far the eye disc overlaps the hole all round
eye_t = 1.2;          // thickness of the disc behind the seat
iris_d = 4.6;         // iris on the printed eye
pupil_d = 2.0;
engrave = 0.35;       // depth of engraved lines (painted eyes, mouth)

/* [Neck socket - MEASURE against your doll body] */
ball_d = 5.0;         // ball (or flared peg tip) on the body's neck
slot_w = 3.3;         // width of the neck shaft under the ball
slot_len = 6.5;       // fore-aft length of the slot: sets how far the head nods
socket_y = -1.5;      // where the neck enters, fore-aft
socket_z = -4.4;      // ball centre height
box_wall = 1.2;
plate_t = 1.4;        // holder plate behind the eyes
neck_hole_d = 7.0;    // opening in the bottom of the head
neck_hole_len = 4.0;  // extra fore-aft length of that opening (for nodding)

/* [Face details] */
mouth = true;
mouth_w = 2.4;
mouth_z = -10.0;
mouth_smile = 0.5;    // sag of the mouth arc; negative frowns
nose = true;          // tiny bump between the eyes and the mouth
nose_z = -7.4;

/* [Hair] */
// Every lock is a tapering ribbon laid on the head. A lock is placed by its
// azimuth (degrees around the head, 0 = centre of the face, 90 = doll's left
// ear) and runs from a root height down to a tip height.
brow_z = 9.0;         // lower edge of the hair cap at the front (hidden by bangs)
side_x = 8.0;         // the cap comes lower beyond this |x| (temples)
side_z = 0.5;         // lower edge of the cap at the temples
bangs = 7;            // number of bang locks
bang_spread = 58;     // degrees either side of centre covered by bangs
bang_root_z = 11;     // where bang locks start (under the cap)
bang_tip_z = [0.2, -1.2, 0.8, -1.8, 0.8, -1.2, 0.2]; // tip heights, cycled; eye tops are at eye_z + eye_h/2
bang_w = 6.5;         // lock width at the root
lock_rise = 0.6;      // locks stand this far proud of the hair cap
bang_curl = 0.8;      // tips lift off the forehead by this much
bang_sway = 6;        // degrees: tips lean toward the centre line
side_locks = true;
lock_az = 76;         // azimuth of the side locks (in front of the ears)
lock_tip_z = -15;
lock_w = 5.0;
lock_flip = 2.5;      // outward flick at the tip
back_flips = 9;       // flicks around the nape
flip_az = 115;        // flicks are spread from -flip_az to +flip_az round the back
flip_root_z = 0;
flip_tip_z = -12;
flip_w = 6.0;
flip_out = 3.5;       // how far the flicks curl outward (and up)
nape_z = -9.0;        // lowest point of the back hair shell

/* [Quality] */
$fn = 48;
strand_fn = 16;
strand_steps = 8;

// ----------------------------------------------------------------------------
// Basic shapes

// The skin surface, shrunk inward by `i` (negative grows it).
module skull(i = 0) {
    hull() {
        translate([0, 0, cran_z])
            scale([cran_w / 2 - i, cran_d / 2 - i, cran_h / 2 - i]) sphere(1);
        for (s = [-1, 1])
            translate([s * cheek_x, cheek_y, cheek_z]) sphere(max(0.2, cheek_r - i));
        translate([0, chin_y, chin_z]) sphere(max(0.2, chin_r - i));
    }
}

// Region between two offsets of the skin: `outer` (more negative = further out)
// and `inner`.
module shell(outer, inner) {
    difference() { skull(outer); skull(inner); }
}

big = 80;
module half_front(y)  { translate([-big, y, -big]) cube([2 * big, big, 2 * big]); }
module half_back(y)   { translate([-big, y - big, -big]) cube([2 * big, big, 2 * big]); }
module above(z)       { translate([-big, -big, z]) cube([2 * big, 2 * big, big]); }

// Front surface of the cranium ellipsoid, out by `o`: y at a given x, z.
function cran_y(x, z, o = 0) =
    let(a = cran_w / 2 + o, b = cran_d / 2 + o, c = cran_h / 2 + o,
        k = 1 - pow(x / a, 2) - pow((z - cran_z) / c, 2))
    b * sqrt(max(0, k));

// Eye outline in the x-z plane, centred, before tilt.
module eye_shape2d(grow = 0) {
    w = eye_w + 2 * grow;
    h = eye_h + 2 * grow;
    intersection() {
        scale([w / 2, h / 2]) circle(1);
        // eye_round < 1 shaves the top flat-ish
        translate([-w, -h / 2]) square([2 * w, h * (0.5 + 0.5 * eye_round)]);
    }
}

// Eye outline placed on side s (+1 = doll's left), extruded along y.
module eye_prism(s, grow, y0, y1) {
    translate([s * eye_x, y1, eye_z]) rotate([90, 0, 0])
        rotate([0, 0, s * eye_tilt])
            linear_extrude(y1 - y0) eye_shape2d(grow);
}

// ----------------------------------------------------------------------------
// Face

module eye_boss() {
    // Fills the face behind the eyes so the eye discs sit on a flat seat.
    intersection() {
        skull(wall / 2);
        hull() for (s = [-1, 1])
            eye_prism(s, eye_lip + 1.2, eye_seat_y, cran_d);
    }
}

module face() {
    difference() {
        union() {
            intersection() { shell(0, wall); half_front(split_y); }
            // tongue that slides into hair_back
            intersection() {
                shell(wall / 2, wall);
                half_front(split_y - lap);
                half_back(split_y + 0.01);
            }
            if (eye_mode == "insert") eye_boss();
            if (ear) for (s = [-1, 1]) ear(s);
            if (nose)
                intersection() {
                    skull(-0.45);
                    translate([0, 0, nose_z]) rotate([-90, 0, 0])
                        scale([1.2, 0.9, 1]) cylinder(r = 0.5, h = big, $fn = 20);
                }
        }
        if (eye_mode == "insert")
            for (s = [-1, 1]) {
                eye_prism(s, 0, eye_seat_y - 1, cran_d);
                // pocket that locates the disc
                eye_prism(s, eye_lip + fit, eye_seat_y - eye_t, eye_seat_y + 0.6);
            }
        else
            for (s = [-1, 1]) difference() {
                eye_prism(s, 0, 0, cran_d);
                eye_prism(s, -0.5, 0, cran_d);
                skull(engrave);
            }
        if (mouth) mouth_cut();
        neck_hole();
    }
}

module ear(s) {
    // Rounded nub on the side, slightly cupped.
    x = s * (face_half_width(ear_z) - 0.4);
    translate([x, ear_y, ear_z]) difference() {
        scale(ear_size / 2 + [ear_size[0] / 2, 0, 0]) sphere(1, $fn = 32);
        translate([s * ear_size[0] * 0.9, 0.3, 0])
            scale([ear_size[0] * 0.5, ear_size[1] * 0.28, ear_size[2] * 0.3]) sphere(1, $fn = 24);
        translate([-s * 10 - s * 0.3, 0, 0]) cube(20, center = true);
    }
}

// Half-width of the head at height z (ears sit on the cranium/cheek blend).
function face_half_width(z) =
    max(cran_w / 2 * sqrt(max(0, 1 - pow((z - cran_z) / (cran_h / 2), 2))),
        cheek_x + sqrt(max(0, pow(cheek_r, 2) - pow(z - cheek_z, 2))));

module mouth_cut() {
    // Shallow engraved arc on the face surface.
    steps = 6;
    for (i = [0 : steps - 1]) {
        x0 = -mouth_w / 2 + mouth_w * i / steps;
        x1 = -mouth_w / 2 + mouth_w * (i + 1) / steps;
        hull() for (x = [x0, x1]) {
            z = mouth_z - mouth_smile * (1 - pow(2 * x / mouth_w, 2));
            translate([x, 0, z]) rotate([-90, 0, 0]) cylinder(d = 0.45, h = cran_d, $fn = 12);
        }
    }
}

module neck_hole() {
    hull() for (dy = [-neck_hole_len / 2, neck_hole_len / 2])
        translate([0, socket_y + dy, -big]) cylinder(d = neck_hole_d, h = big + socket_z);
}

// ----------------------------------------------------------------------------
// Eyes

// One eye disc: a flange behind the seat and a plug that fills the hole.
module eye_disc(s) {
    eye_prism(s, eye_lip, eye_seat_y - eye_t, eye_seat_y);
    eye_prism(s, -fit, eye_seat_y - 0.01, eye_seat_y + eye_plug);
}

module eyes() {
    for (s = [-1, 1]) eye_disc(s);
    // bridge between the discs, like the reference part
    translate([0, eye_seat_y - eye_t / 2, eye_z])
        cube([2 * eye_x - eye_w, eye_t, 1.6], center = true);
}

// Iris and pupil as separate bodies, for multi-colour printing or as masks.
module iris() {
    for (s = [-1, 1])
        translate([s * eye_x, eye_seat_y + eye_plug - 0.4, eye_z - 0.2]) rotate([-90, 0, 0])
            difference() {
                cylinder(d = iris_d, h = 0.41);
                translate([0, 0, -1]) cylinder(d = pupil_d, h = 3);
            }
}
module pupil() {
    for (s = [-1, 1])
        translate([s * eye_x, eye_seat_y + eye_plug - 0.4, eye_z - 0.2]) rotate([-90, 0, 0])
            cylinder(d = pupil_d, h = 0.41);
}

// ----------------------------------------------------------------------------
// Holder: clamps the eyes and carries the neck socket.

plate_front = eye_seat_y - eye_t + 0.2;   // presses 0.2 mm into the eye discs
box_s = ball_d + 2 * box_wall;

module holder() {
    difference() {
        intersection() {
            skull(wall + fit);
            union() {
                // plate across the whole inside of the face
                translate([-big, plate_front - plate_t, -big]) cube([2 * big, plate_t, 2 * big]);
                // box back to the inner wall of hair_back
                translate([-box_s / 2, -big, socket_z - box_s / 2])
                    cube([box_s, big + plate_front - 0.01, box_s]);
            }
            // keep the plate out of the tongue region so it slides in from behind
            half_front(split_y - lap);
        }
        // ball cup and the slot under it
        translate([0, socket_y, socket_z]) sphere(d = ball_d + fit);
        hull() for (dy = [-1, 1] * (slot_len - slot_w) / 2)
            translate([0, socket_y + dy, socket_z - big]) cylinder(d = slot_w + fit, h = big);
        // lightening window so the plate is not a solid disc
        translate([0, plate_front - plate_t - 1, cran_z + 4])
            rotate([-90, 0, 0]) cylinder(d = 8, h = plate_t + 2);
    }
}

// ----------------------------------------------------------------------------
// Hair

// Half-width scale of the head at height z: the cranium ellipse above its
// centre, full width below it (the cheeks keep the face wide down there).
function kz(z) = z >= cran_z ? sqrt(max(0.05, 1 - pow((z - cran_z) / (cran_h / 2), 2))) : 1;

// Point on the head at azimuth `az`, height z, `off` outside the skin.
function surf(az, z, off) =
    [(cran_w / 2 * kz(z) + off) * sin(az), (cran_d / 2 * kz(z) + off) * cos(az), z];

// Tilt of the surface normal above the horizontal at height z.
function elev(z) = z > cran_z ? asin(min(0.95, (z - cran_z) / (cran_h / 2))) : 0;

// A lock of hair: root at (az, z0), tip at z1. It lies on the skin, its width
// w narrowing to a point and its thickness th to a third. `rise` makes it stand
// proud of the hair cap so the locks read as separate. `curl` lifts the tip off
// the head (and up a little), `sway` turns the tip round the head by that many
// degrees.
module lock(az, z0, z1, w, th = hair_t, curl = 0, sway = 0, rise = lock_rise) {
    n = strand_steps;
    function thick(t) = th * (1 - 0.66 * t);
    function p(t) = let(a = az + sway * t * t, z = z0 + (z1 - z0) * t + curl * 0.5 * pow(t, 3))
        [surf(a, z, thick(t) / 2 + rise * (1 - t) + curl * t * t), a, elev(z)];
    for (i = [0 : n - 1]) hull() for (t = [i / n, (i + 1) / n]) {
        q = p(t);
        translate(q[0]) rotate([0, 0, -q[1]]) rotate([q[2], 0, 0])
            scale([max(0.3, w * (1 - t * t)) / 2, thick(t) / 2,
                   max(0.6, w * (1 - t * t)) / 2 + abs(z1 - z0) / n / 2])
                sphere(1, $fn = strand_fn);
    }
}

module bang_strands() {
    for (i = [0 : bangs - 1]) {
        a = bangs == 1 ? 0 : -bang_spread + 2 * bang_spread * i / (bangs - 1);
        lock(a, bang_root_z, bang_tip_z[i % len(bang_tip_z)], bang_w,
             curl = bang_curl, sway = -sign(a) * bang_sway);
    }
}

module side_lock_strands() {
    if (side_locks) for (s = [-1, 1]) {
        lock(s * lock_az, side_z + 7, lock_tip_z, lock_w, curl = lock_flip, sway = s * 6);
        lock(s * (lock_az - 14), side_z + 7, (lock_tip_z + side_z) * 0.6, lock_w * 0.8,
             curl = lock_flip * 0.6, sway = s * -6);
        lock(s * (lock_az + 15), side_z + 7, lock_tip_z * 0.8, lock_w * 0.9,
             curl = lock_flip, sway = s * 8);
    }
}

// Locks running from the crown down the back, so the back is not a bald dome.
crown_locks = 9;
module crown_strands() {
    for (i = [0 : crown_locks - 1]) {
        a = 180 - flip_az + 2 * flip_az * (i + 0.5) / crown_locks;
        lock(a, cran_z + cran_h / 2 - 2.5, flip_root_z + 1, 6.5, rise = 0.9,
             sway = (a < 180 ? -1 : 1) * 8);
    }
}

module back_flip_strands() {
    for (i = [0 : back_flips - 1]) {
        a = 180 - flip_az + 2 * flip_az * i / (back_flips - 1);
        lock(a, flip_root_z + 2, flip_tip_z + (i % 2) * 2, flip_w, curl = flip_out, rise = 0.9,
             sway = (a < 180 ? -1 : 1) * 10);
    }
}

// Pin positions on the seam, in the middle of hair_front's thickness.
function pin_pos(a) =
    let(k = sqrt(1 - pow(split_y / (cran_d / 2), 2)),
        rx = cran_w / 2 * k + hair_t / 2,
        rz = cran_h / 2 * k + hair_t / 2)
    [rx * cos(a), split_y, cran_z + rz * sin(a)];
pin_angles = [35, 90, 145];

module pin_holes() {
    for (a = pin_angles) translate(pin_pos(a)) rotate([90, 0, 0])
        cylinder(d = pin_d + fit + 0.05, h = pin_len + 1, center = true, $fn = 16);
}

module hair_front() {
    difference() {
        union() {
            intersection() {
                shell(-hair_t, -fit / 2);
                half_front(split_y);
                union() {
                    above(brow_z);
                    difference() {
                        above(side_z);
                        translate([-side_x, -big, -big]) cube([2 * side_x, 2 * big, 2 * big]);
                    }
                }
            }
            intersection() {
                union() { bang_strands(); side_lock_strands(); }
                half_front(split_y + 0.01);
            }
        }
        skull(-fit / 2);      // strands must not intrude into the face
        half_back(split_y);
        pin_holes();
    }
}

module hair_back() {
    difference() {
        union() {
            intersection() {
                shell(-hair_t, wall);
                half_back(split_y);
                above(nape_z);
            }
            intersection() {
                union() { back_flip_strands(); crown_strands(); }
                half_back(split_y - 0.01);
            }
        }
        // recess for the face's tongue
        intersection() {
            shell(wall / 2 - fit, wall + 0.01);
            half_front(split_y - lap - fit);
        }
        skull(wall);
        half_front(split_y);
        neck_hole();
        pin_holes();
    }
}

// ----------------------------------------------------------------------------
// Output

skin = [1.0, 0.86, 0.80];
hairc = [0.62, 0.64, 0.66];

module assembly(e = 0) {
    color(skin) translate([0, e * 1.2, 0]) face();
    color("white") translate([0, e * 0.4, 0]) eyes();
    color([0.15, 0.35, 0.75]) translate([0, e * 0.4, 0]) iris();
    color([0.05, 0.05, 0.1]) translate([0, e * 0.4, 0]) pupil();
    color([0.95, 0.80, 0.72]) translate([0, -e * 0.6, 0]) holder();
    color(hairc) translate([0, e * 1.0, e * 1.0]) hair_front();
    color(hairc) translate([0, -e * 2.0, 0]) hair_back();
}

if (part == "assembly") assembly(0);
else if (part == "exploded") assembly(10);
else if (part == "section") intersection() { assembly(0); translate([0, -big, -big]) cube(2 * big); }
// Print orientations: face and hair_front face-down is the best surface for
// resin with supports inside; see README.
else if (part == "face") rotate([-90, 0, 0]) face();
else if (part == "eyes") rotate([-90, 0, 0]) eyes();
else if (part == "iris") rotate([-90, 0, 0]) iris();
else if (part == "pupil") rotate([-90, 0, 0]) pupil();
else if (part == "holder") rotate([90, 0, 0]) holder();
else if (part == "hair_front") rotate([-90, 0, 0]) hair_front();
else if (part == "hair_back") rotate([90, 0, 0]) hair_back();
