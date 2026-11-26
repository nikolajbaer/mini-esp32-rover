# Anime ball-jointed doll

A 3D-printable ball-jointed doll, about 9" (226 mm with hair) tall, with an
oversized anime head and interchangeable hair. It is held together inside by
elastic cord and wire S-hooks, like a resin BJD. Everything comes from one
parametric file, [`doll.scad`](doll.scad).

![Front (bob), side (twin tails) and back](render.png)

> **Status:** first draft. Nothing has been printed or strung yet. Expect to
> tune the joint fits (`fit`) and the cup depths after the first test prints.

## Parts

| Part | Qty | Joints it carries |
| --- | --- | --- |
| `head` | 1 | neck cup, head hook bar, 2 magnets |
| `hair_bob`, `hair_twintails` | 1 of each style | 2 magnets; the hair is the back and top of the head |
| `chest` | 1 | neck ball, waist ball, both shoulder cups |
| `pelvis` | 1 | waist cup, both hip cups |
| `upper_arm_r` / `_l` | 1 + 1 | shoulder ball, elbow ball |
| `forearm_r` / `_l` | 1 + 1 | elbow cup, wrist cup |
| `hand_r` / `_l` | 1 + 1 | wrist ball, hook bar |
| `thigh_r` / `_l` | 1 + 1 | hip ball, knee ball |
| `shin_r` / `_l` | 1 + 1 | knee cup, ankle cup |
| `foot_r` / `_l` | 1 + 1 | ankle ball, hook bar |

Every joint is a ball on one part sitting in a cup on the next. The elastic
pulls each ball into its cup, so the cups are no deeper than a hemisphere and
nothing has to snap together. The elbows and knees bend one way only (the
elbows about 120°, the knees about 115°). The other joints swivel in a cone.

### Hardware

- 2 mm round elastic cord, about 1 m
- 5 wire S-hooks, about 10 mm long, bent from 0.8 mm steel or brass wire
  (`s_hook.stl` is a printable stand-in for testing only)
- 4 disc magnets, 5 × 2 mm, plus 2 more for each extra hairstyle
- A stringing tool: a loop of stiff wire, or a long crochet hook

## Stringing

There are three runs of elastic:

1. **Legs:** tie one end to an S-hook and hook it onto the bar in the right
   foot (inside the ankle ball). Feed the cord up through the shin, thigh and
   right hip into the pelvis, across, and down through the left hip, thigh and
   shin. Then tie it to an S-hook on the left foot's bar. Tension it so the
   feet pull firmly into the ankles.
2. **Torso:** hook an S-hook onto the bar inside the head (take the hair off to
   reach it). Run the cord down through the neck ball, the chest and the
   waist ball into the pelvis. There, hook it round the leg cord with a second
   S-hook.
3. **Arms:** start at the right hand's hook bar. Run the cord through the
   forearm, upper arm and right shoulder into the chest, across, and out
   through the left arm to the left hand.

Tighter cord holds poses better but makes the doll harder to move. Tie, test
and re-tie.

## Interchangeable hair

The head is cut on a flat, slanted seam that runs from the hairline at the
front to the nape at the back. Everything above the seam belongs to the
hairstyle: the back of the skull, the bangs and the locks.

- Two magnets in the head and two in each hair piece hold it on.
- A thin lip on the hair, inside the head's rim, stops it sliding.
- Taking the hair off also opens the head, so you can reach the head hook.

Make sure the magnet polarities match before gluing them in.

To make a new style, write a module that calls `hair_cap() { ... }` and put
`lock(...)` and `ribbon(...)` calls inside it. `hair_cap` already supplies the
skull, the lip, the magnets and the trimming, so the new style fits every
head printed from this file. `hair_bob()` and `hair_twintails()` are examples.

- `lock(az, root_z, tip_z, width, ...)` lays a tapering lock on the head.
  `az` is the angle around the head (0 is the face, 90 is the doll's right).
- `ribbon(points, ...)` is a free-hanging strand, such as a tail.

## Tuning

The parameters are at the top of `doll.scad`:

- **Fits and stringing:**
  - `fit`: ball-to-cup clearance. 0.25 mm suits resin, use 0.3–0.4 for FDM.
  - `cord_d`: size of the elastic holes.
  - `wall`: shell thickness.
- **Head:** cranium, cheek and chin sizes. Bigger, lower cheeks give a rounder,
  younger face.
- **Face:** eye position, size and tilt, the iris, the mouth and the nose.
  - `eye_style = "engraved"` cuts shallow guide lines for painting.
  - `"smooth"` leaves a blank face for decals or face-up.
- **Joints:** each one is a single line, `neck_j`, `shoulder_j(s)`, and so
  on. A line gives the centre, ball radius, stem radius and how far the joint
  swings.

The body parts are hulls of ellipsoids (`chest_shape`, `thigh_shape(s)`,
and so on), so you reshape the body by editing those lists.

## Printing

The parts are small and smooth and have ball joints, so they print best on a
**resin (MSLA) printer**. Hollow parts need drain holes; the joint openings
usually serve. On FDM, use a 0.25 mm nozzle, 0.08–0.12 mm layers, supports
under the balls and cups, and `fit = 0.35`.

The STLs in [`stl/`](stl) are in their standing position. Turn them in the
slicer to suit your printer.

To regenerate the STLs:

```sh
cd doll
for p in head hair_bob hair_twintails chest pelvis \
         upper_arm_r upper_arm_l forearm_r forearm_l hand_r hand_l \
         thigh_r thigh_l shin_r shin_l foot_r foot_l s_hook; do
  openscad -D "part=\"$p\"" -o stl/$p.stl doll.scad
done
```

## Known gaps in this draft

- Single joints only. Double-jointed elbows and knees would let them fold
  further.
- Mitten hands, with no separate fingers.
- No stand. A 9" BJD with a big head is top-heavy, so plan on a doll stand
  with a waist clip.
- The face is engraved, not sculpted. The eyes are guides for paint or decals.
