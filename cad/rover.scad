// Mini ESP32 tracked rover - parametric model.
//
// Pick what to render with `part`:
//   assembly | chassis | deck | sprocket | idler | pin | track | plate | hubtest
// e.g.  openscad -D 'part="chassis"' -o chassis.stl rover.scad
//
// Axes in the assembly: +x forward, +y left, +z up, ground at z = 0.
// The two motors sit crosswise and staggered: the left track is driven at the
// front, the right track at the rear. That keeps the body barely wider than
// one motor is long. Between them the driver board lies on the floor with the
// XIAO above it, USB-C port out through the left wall between the track runs.
// The battery rides on top of the deck.

part = "assembly";

/* [Measure these on your parts] */
// DC motor can: width, height (across the flats), length
motor_d = 10;         // round can diameter
motor_flat = 8;       // distance across the two flats
motor_len = 11.25;    // can only
motor_tail = 1.25;    // end boss and wire tabs behind the can
// Gearbox: diameter and length (motor face to gearbox face)
gbox_d = 10;
gbox_len = 7;
// Output: "gear" = small pinion on the gearbox (star socket in the hub),
//         "d"    = plain D shaft
shaft_type = "gear";
// Pinion: tooth count, tip diameter, width of the valley between two teeth.
// gear_teeth = 0 gives a plain round bore of gear_od - 0.3 to force the
// pinion into, if your printer cannot resolve the keys.
gear_teeth = 6;
gear_od = 4.46;
gear_valley_w = 0.75;
gear_key_depth = 0.7; // how far the hub's keys reach down between the teeth
gear_fit = 0.1;       // clearance added all round the pinion profile
// D shaft: diameter, distance across the flat
shaft_d = 3.0;
shaft_flat = 2.5;
// Length of the pinion / shaft beyond the gearbox face
shaft_len = 3.5;      // 3 mm of teeth plus a 0.5 mm tip
// Battery (602030), XIAO and DRV8833 board footprints
batt = [33, 20, 6.25]; // length includes the protection board and wire tab
xiao = [21, 17.8];    // length (USB end to antenna end), width
drv = [18.6, 16];
drv_h = 3.2;          // driver board thickness including its parts

/* [Tracks] */
pitch = 5;            // tooth pitch along the belt
sprocket_teeth = 12;
belt_teeth = 26;      // sets the wheelbase: (belt_teeth - sprocket_teeth) * pitch / 2
belt_w = 8;
band_t = 1.0;         // thickness of the flexible band
tooth_h = 1.2;        // inner drive teeth
tread_h = 2.0;        // outer grip bars; taller = more ground clearance
track_slack = 1.0;    // extra belt length over the exact fit (negative = tighter)

/* [Body] */
inner_w = 24.6;       // inside width of the tub
wall = 2;
end_wall = 1.6;
floor_t = 1.6;
deck_t = 1.6;
screw_pilot_d = 1.7;  // M2 self-tapping into plastic
screw_clear_d = 2.3;
pin_d = 4.0;          // idler axle pin
pin_hole_d = 4.1;     // hole in the chassis wall (light press fit)
fit = 0.2;            // general sliding clearance
motor_fit = 0.05;     // per-side clearance on the motor flats (grip)
gbox_boss_h = 0.5;    // raised ring around the pinion on the gearbox face, if any
nose_d = 7.4;         // sprocket hub nose that reaches through the wall

/* [Hidden] */
$fn = 64;
eps = 0.01;

pitch_r = sprocket_teeth * pitch / (2 * PI);
wheelbase = (belt_teeth - sprocket_teeth) * pitch / 2;
sprocket_r = pitch_r - band_t / 2;             // belt inner surface rides here
track_r = pitch_r + band_t / 2 + tread_h;
axle_z = track_r;
ax = wheelbase / 2;                            // axle x position (+/-)

body_d = max(motor_d, gbox_d);
motor_bot = axle_z - body_d / 2;
floor_top = motor_bot - 1.25;                  // pads lift the motor off the floor
ground_clearance = floor_top - floor_t;        // follows the track thickness
wall_top = axle_z + body_d / 2;                // deck clamps the motors here
bx = ax + body_d / 2 + fit + end_wall;        // body half length
by = inner_w / 2 + wall;                       // body half width
rib_t = 1.2;
rib_x = ax - body_d / 2 - fit - rib_t;        // inner face of the motor pocket rib
// Electronics bay between the motor pockets
bay_x = rib_x;                                 // half length of the bay
pcb_z = floor_top + drv_h + 2.3;               // underside of the XIAO, above the driver and its wires
far_y = inner_w / 2 - xiao.x;                  // antenna end of the XIAO
// Deck screws: two beside the XIAO's USB end, two behind its antenna end.
// The pilot holes sit partly in the wall so the posts stay slim.
post_x = xiao.y / 2 + 0.2 + 1.6;
post_x2 = 4;
post_y = inner_w / 2 - 0.3;

flange = 1.2;                                  // 45 degree belt guide flanges
wheel_gap = 0.6;                               // wall to wheel
wheel_w = belt_w + 0.4 + 2 * flange;
nose_len = wheel_gap + wall - gbox_boss_h - 0.3; // stops just short of the gearbox
boss_len = 3;                                  // idler pin boss inside the wall
pin_len = wall + boss_len + wheel_gap + wheel_w + 0.3;

assert(motor_bot >= floor_top, "motor sits below the floor: more teeth or less clearance");
assert(2 * bay_x >= max(xiao.y, drv.x) + 1, "electronics bay too short: raise belt_teeth");
assert(inner_w >= xiao.x + 3.3, "XIAO does not fit across the tub: raise inner_w");
assert(2 * bx >= batt.x + 3, "battery overhangs the deck");
assert(inner_w >= gbox_len + motor_len + motor_tail + 3 + 1.9, "motor does not fit across the tub: raise inner_w");

// ---------------------------------------------------------------- chassis --
// side: +1 = motor shaft exits the left wall (+y), -1 = right wall.
module motor_pocket_add(side) {
  // The whole motor sits inside the tub. The gearbox is trapped between the
  // wall (whose slot only passes the pinion) and the ends of two cheeks; the
  // cheeks grip the flats of the can so it cannot turn. The deck holds it down.
  cheek_t = 1.5;
  cheek_len = motor_len;
  cy = inner_w / 2 - gbox_len - 0.15;          // cheek start, measured from the centre line
  for (sx = [-1, 1]) translate([sx > 0 ? motor_flat / 2 + motor_fit : -motor_flat / 2 - motor_fit - cheek_t,
                                side > 0 ? cy - cheek_len : -cy, floor_top - eps])
    cube([cheek_t, cheek_len, axle_z + 2.5 - floor_top]);
  // pads under the gearbox and the can
  for (dy = [1.5, gbox_len + 1, gbox_len + motor_len - 4])
    translate([-motor_flat / 2 - fit, side > 0 ? inner_w / 2 - dy - 3 : -inner_w / 2 + dy, floor_top - eps])
      cube([motor_flat + 2 * fit, 3, motor_bot - floor_top + eps]);
  // boss for the idler pin on the opposite wall, carried down to the floor so it prints
  translate([0, -side * inner_w / 2, 0]) hull() {
    translate([0, 0, axle_z]) rotate([90, 0, 0])
      translate([0, 0, side > 0 ? -boss_len : 0]) cylinder(d = pin_d + 4, h = boss_len);
    translate([-(pin_d + 4) / 2, side > 0 ? 0 : -boss_len, floor_top - eps])
      cube([pin_d + 4, boss_len, eps]);
  }
}

module motor_pocket_cut(side) {
  // U slot for the pinion and the sprocket nose; narrower than the gearbox
  translate([0, side * (inner_w / 2 - eps), 0]) rotate([0, 0, side > 0 ? 0 : 180]) {
    translate([0, 0, axle_z]) rotate([-90, 0, 0]) cylinder(d = nose_d + 0.6, h = wall + 2 * eps);
    translate([-nose_d / 2 - 0.3, 0, axle_z]) cube([nose_d + 0.6, wall + 2 * eps, wall_top]);
  }
  // idler pin hole, opposite wall
  translate([0, -side * (inner_w / 2 - boss_len - eps), axle_z]) rotate([side > 0 ? 90 : -90, 0, 0])
    cylinder(d = pin_hole_d, h = wall + boss_len + 2 * eps);
}

// Supports for the XIAO, and the deck screw posts, all rising from the floor.
module bay_add() {
  z0 = floor_top - eps;
  // USB end: a shelf under each corner of the board, and a post beside it
  for (sx = [-1, 1]) {
    translate([sx > 0 ? 6.6 : -bay_x, inner_w / 2 - 2.5, z0]) cube([bay_x - 6.6, 2.5 + eps, pcb_z - z0]);
    translate([sx > 0 ? xiao.y / 2 + 0.2 : -bay_x - rib_t, inner_w / 2 - 2, z0])
      cube([bay_x + rib_t - xiao.y / 2 - 0.2, 2 + eps, wall_top - z0]);
  }
  // antenna end: a shelf under the board and a full-height stop behind it
  translate([-6.3, -inner_w / 2 - eps, z0]) cube([12.6, far_y + 1.2 + inner_w / 2, pcb_z - z0]);
  translate([-6.3, -inner_w / 2 - eps, z0]) cube([12.6, far_y - 0.25 + inner_w / 2, wall_top - z0]);
}

module chassis() {
  difference() {
    union() {
      difference() {
        translate([-bx, -by, ground_clearance]) cube([2 * bx, 2 * by, wall_top - ground_clearance]);
        translate([-bx + end_wall, -inner_w / 2, floor_top]) cube([2 * (bx - end_wall), inner_w, wall_top]);
      }
      // ribs closing the motor pockets (wires pass over the top)
      for (s = [-1, 1]) translate([s > 0 ? rib_x : -rib_x - rib_t, -inner_w / 2 - eps, floor_top - eps])
        cube([rib_t, inner_w + 2 * eps, axle_z - floor_top]);
      bay_add();
      translate([ax, 0, 0]) motor_pocket_add(1);
      translate([-ax, 0, 0]) motor_pocket_add(-1);
    }
    translate([ax, 0, 0]) motor_pocket_cut(1);
    translate([-ax, 0, 0]) motor_pocket_cut(-1);
    // open-topped notch in the left wall for the USB-C socket
    translate([-5.1, inner_w / 2 - eps, pcb_z + 0.9]) cube([10.2, wall + 2 * eps, wall_top]);
    for (sx = [-1, 1]) {
      translate([sx * post_x, post_y, wall_top - 8]) cylinder(d = screw_pilot_d, h = 8 + eps);
      translate([sx * post_x2, -post_y, wall_top - 8]) cylinder(d = screw_pilot_d, h = 8 + eps);
    }
  }
}

// ------------------------------------------------------------------- deck --
// Clamps the motors, closes the bay and carries the battery between low rails.
// Flat underneath, so it prints without supports.
module deck() {
  rail_h = 3; rail_t = 1.2;
  ex = batt.x / 2 + 0.2;            // battery end
  ey = batt.y / 2 + 0.2;            // battery side
  difference() {
    union() {
      translate([-bx, -by, 0]) cube([2 * bx, 2 * by, deck_t]);
      translate([0, 0, deck_t - eps]) {
        // rear end stop, and a front one that leaves the right side open for the leads
        translate([-ex - rail_t, -ey - rail_t, 0]) cube([rail_t, 2 * (ey + rail_t), rail_h]);
        translate([ex, -2, 0]) cube([rail_t, ey + rail_t + 2, rail_h]);
        // short side rails at the corners, clear of the screw heads
        for (sx = [-1, 1]) translate([sx > 0 ? ex - 4 : -ex - rail_t, ey, 0]) cube([4 + rail_t, rail_t, rail_h]);
        translate([-ex - rail_t, -ey - rail_t, 0]) cube([4 + rail_t, rail_t, rail_h]);
      }
    }
    // slot for the battery leads, down into the corner of the bay behind the XIAO
    hull() for (x = [7.8, 9.8]) translate([x, -inner_w / 2 + 1.4, -eps]) cylinder(d = 2.6, h = deck_t + 2 * eps);
    for (sx = [-1, 1]) {
      translate([sx * post_x, post_y, -eps]) cylinder(d = screw_clear_d, h = deck_t + 2 * eps);
      translate([sx * post_x2, -post_y, -eps]) cylinder(d = screw_clear_d, h = deck_t + 2 * eps);
    }
  }
}

// ----------------------------------------------------------------- wheels --
module groove2d() {
  d = tooth_h + 0.3;
  polygon([[sprocket_r + 0.5, -1.5], [sprocket_r - d, -0.9], [sprocket_r - d, 0.9], [sprocket_r + 0.5, 1.5]]);
}

// Printed as modelled: outer face on the bed, flanges are self-supporting cones.
module wheel_body() {
  difference() {
    union() {
      cylinder(r1 = sprocket_r + flange, r2 = sprocket_r, h = flange);
      cylinder(r = sprocket_r, h = wheel_w);
      translate([0, 0, wheel_w - flange]) cylinder(r1 = sprocket_r, r2 = sprocket_r + flange, h = flange);
    }
    translate([0, 0, flange]) linear_extrude(wheel_w - 2 * flange)
      for (i = [0 : sprocket_teeth - 1]) rotate(i * 360 / sprocket_teeth) groove2d();
  }
}

// 2D hole that the motor output pushes into. `clr` is added all round.
module shaft_bore2d(clr = gear_fit) {
  if (shaft_type == "d") {
    intersection() {
      circle(d = shaft_d + 0.15);
      translate([-shaft_d, -shaft_d / 2 - 0.075]) square([2 * shaft_d, shaft_flat + 0.15]);
    }
  } else if (gear_teeth == 0) {
    circle(d = gear_od - 0.3);
  } else {
    // round bore at the tooth tips, with one key per valley reaching part way
    // down between the teeth. Keys are sized from the valley width, so the
    // root diameter does not need to be known.
    rt = gear_od / 2 + clr;
    ri = gear_od / 2 - gear_key_depth;
    w_in = gear_valley_w + 0.1 - 2 * clr;
    w_out = w_in + gear_key_depth * 0.8;
    difference() {
      circle(r = rt);
      for (i = [0 : gear_teeth - 1]) rotate(i * 360 / gear_teeth)
        polygon([[ri, -w_in / 2], [rt + 0.5, -w_out / 2], [rt + 0.5, w_out / 2], [ri, w_in / 2]]);
    }
  }
}

module sprocket() {
  difference() {
    union() {
      wheel_body();
      // nose: carries the socket through the wall to the gearbox face
      translate([0, 0, wheel_w - eps]) cylinder(d = nose_d, h = nose_len);
    }
    translate([0, 0, -eps]) linear_extrude(wheel_w + nose_len + 1) shaft_bore2d();
  }
}

module idler() {
  difference() {
    wheel_body();
    translate([0, 0, -eps]) cylinder(d = pin_d + 0.5, h = wheel_w + 2 * eps);
  }
}

// Three small pucks, same thickness as the sprocket hub, with the shaft bore
// at clearance gear_fit - 0.1 / gear_fit / gear_fit + 0.1 (1, 2, 3 notches).
// Print this first and see which one the motor output presses into snugly.
module hubtest() {
  h = 4;
  difference() {
    union() {
      for (i = [0 : 2]) translate([i * 11, 0, 0]) cylinder(d = 10, h = h);
      translate([0, -2, 0]) cube([22, 4, 1]);  // web joining the pucks
    }
    for (i = [0 : 2]) translate([i * 11, 0, 0]) {
      translate([0, 0, -eps]) linear_extrude(wheel_w) shaft_bore2d(gear_fit + (i - 1) * 0.1);
      for (n = [0 : i]) translate([-1.6 + n * 1.6 - 0.4, 4, -eps]) cube([0.8, 2, wheel_w]);
    }
  }
}

// Printed head down.
module pin() {
  cylinder(d = pin_d + 3, h = 1.2);
  cylinder(d = pin_d, h = 1.2 + pin_len);
}

// ------------------------------------------------------------------ track --
// Pose on the belt pitch line at arc length s: [x, y, tangent angle].
// Runs clockwise seen from the left: forward along the top, down the front.
function belt_pose(s, run) =
  let (h = run / 2, R = pitch_r, arc = PI * R)
  s < run ? [-h + s, R, 0] :
  s < run + arc ? let (a = (s - run) / R * 180 / PI) [h + R * sin(a), R * cos(a), -a] :
  s < 2 * run + arc ? [h - (s - run - arc), -R, 180] :
  let (a = (s - 2 * run - arc) / R * 180 / PI) [-h - R * sin(a), -R * cos(a), 180 - a];

tooth_pts = [[-1.1, -band_t / 2 + eps], [-0.7, -band_t / 2 - tooth_h], [0.7, -band_t / 2 - tooth_h], [1.1, -band_t / 2 + eps]];
tread_pts = [[-1.3, band_t / 2 - eps], [-0.9, band_t / 2 + tread_h], [0.9, band_t / 2 + tread_h], [1.3, band_t / 2 - eps]];
belt_len = 2 * wheelbase + 2 * PI * pitch_r + track_slack;   // along the pitch line

// The printable track: a round ring standing on its edge (TPU). Printing it
// round keeps the wall even all the way around, so it runs true.
module track() {
  R = belt_len / (2 * PI);
  linear_extrude(belt_w) {
    difference() {
      circle(r = R + band_t / 2, $fn = 240);
      circle(r = R - band_t / 2, $fn = 240);
    }
    for (i = [0 : belt_teeth - 1]) {
      a = i * 360 / belt_teeth;
      translate([R * cos(a), R * sin(a)]) rotate(a - 90) polygon(tooth_pts);
      b = (i + 0.5) * 360 / belt_teeth;
      translate([R * cos(b), R * sin(b)]) rotate(b - 90) polygon(tread_pts);
    }
  }
}

// The same belt wrapped around the two wheels, for the assembly view only.
module track_fitted() {
  run = wheelbase;
  len = 2 * run + 2 * PI * pitch_r;
  step = len / belt_teeth;
  linear_extrude(belt_w) {
    difference() {
      hull() for (x = [-run / 2, run / 2]) translate([x, 0]) circle(r = pitch_r + band_t / 2, $fn = 96);
      hull() for (x = [-run / 2, run / 2]) translate([x, 0]) circle(r = pitch_r - band_t / 2, $fn = 96);
    }
    for (i = [0 : belt_teeth - 1]) {
      p = belt_pose((i * step + run / 2) % len, run);
      translate([p.x, p.y]) rotate(p[2]) polygon(tooth_pts);
      q = belt_pose(((i + 0.5) * step + run / 2) % len, run);
      translate([q.x, q.y]) rotate(q[2]) polygon(tread_pts);
    }
  }
}

// --------------------------------------------------------------- assembly --
module motor_mock() {  // shaft along +y, origin at the motor/gearbox joint on the axis
  color("silver") rotate([90, 0, 0]) linear_extrude(motor_len) intersection() {
    circle(d = motor_d);
    square([motor_flat, motor_d], center = true);
  }
  color("dimgray") rotate([90, 0, 0]) cylinder(d = 4, h = motor_len + motor_tail);
  color("white") rotate([-90, 0, 0]) cylinder(d = gbox_d, h = gbox_len);
  color("white") rotate([-90, 0, 0]) cylinder(d = shaft_type == "d" ? shaft_d : gear_od, h = gbox_len + shaft_len);
}

module side_parts(side) {  // side +1 = left
  wy = by + wheel_gap;
  drive_x = side * ax;
  // wheels are modelled outer face down; flip so the outer face points outward
  translate([drive_x, side * (wy + wheel_w), axle_z]) rotate([side * 90, 0, 0]) color("orange") rotate(90) sprocket();
  translate([-drive_x, side * (wy + wheel_w), axle_z]) rotate([side * 90, 0, 0]) color("gold") rotate(90) idler();
  translate([-drive_x, side * (wy + wheel_w + 0.3 + 1.2), axle_z]) rotate([side * 90, 0, 0]) color("gold") pin();
  translate([0, side * (wy + flange + 0.2 + (side > 0 ? belt_w : 0)), axle_z]) rotate([90, 0, 0]) color("dimgray") track_fitted();
  translate([drive_x, side * (inner_w / 2 - gbox_len), axle_z]) rotate([0, 0, side > 0 ? 0 : 180]) motor_mock();
}

module electronics_mock() {
  // driver board on the floor, XIAO above it with its USB-C socket in the wall notch
  dy = (far_y + 1.2 + inner_w / 2 - 2.5) / 2;
  color("purple") translate([-drv.x / 2, dy - drv.y / 2, floor_top]) cube([drv.x, drv.y, 1.6]);
  color("darkgreen") translate([-xiao.y / 2, far_y, pcb_z]) cube([xiao.y, xiao.x, 1.2]);
  color("silver") translate([-6, far_y + 1.5, pcb_z + 1.2]) cube([12, 12.5, 2.4]);
  color("gainsboro") translate([-4.5, inner_w / 2 - 6, pcb_z + 1.2]) cube([9, 7.3, 3.2]);
}

module assembly() {
  color("steelblue") chassis();
  color("lightsteelblue", 0.9) translate([0, 0, wall_top]) deck();
  side_parts(1);
  side_parts(-1);
  color("gold") translate([-batt.x / 2, -batt.y / 2, wall_top + deck_t]) cube(batt);
  electronics_mock();
}

// Everything rigid on one plate (PETG). Print the tracks separately in TPU.
module plate() {
  translate([0, 0, -ground_clearance]) chassis();
  translate([0, 2 * by + 6, 0]) deck();
  for (i = [0, 1]) {
    translate([-bx - 14, i * 24, 0]) sprocket();
    translate([-bx - 38, i * 24, 0]) idler();
    translate([-bx - 14 - i * 12, 46, 0]) pin();
  }
}

if (part == "assembly") assembly();
else if (part == "chassis") translate([0, 0, -ground_clearance]) chassis();
else if (part == "deck") deck();
else if (part == "sprocket") sprocket();
else if (part == "idler") idler();
else if (part == "pin") pin();
else if (part == "track") track();
else if (part == "plate") plate();
else if (part == "hubtest") hubtest();

echo(str("wheelbase=", wheelbase, " axle_z=", axle_z, " size LxWxH=", 2 * (ax + track_r), " x ",
         2 * (by + wheel_gap + wheel_w), " x ", max(2 * track_r, wall_top + deck_t + 4)));
