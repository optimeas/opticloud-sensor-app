"""Writes the custom symbols opticloud.pulse and opticloud.off from the contours of the app icon.

Input: the JSON of trace.swift, a list of closed loops of [x, y] points: the outline of the cloud, its hole, and the
pulse. Output: one .symbolset per symbol in the given asset catalog, as SF Symbols template 6.0 with the three masters
Ultralight-S, Regular-S, and Black-S. The masters are the same shape, so the symbol does not change with the weight.
Control Center shows only symbols of a recent template version; a template 3.0 with Regular-M alone stayed empty there.
"""
import json
import os
import sys

loops = json.load(open(sys.argv[1]))
outdir = sys.argv[2]


def extent(loop):
    return (max(p[0] for p in loop) - min(p[0] for p in loop)) * (max(p[1] for p in loop) - min(p[1] for p in loop))


outer, inner, pulse = sorted(loops, key=lambda l: -extent(l))
x0 = min(p[0] for p in outer); x1 = max(p[0] for p in outer)
y0 = min(p[1] for p in outer); y1 = max(p[1] for p in outer)

# Height of the glyph in the medium size; small is 0.783 of it, as in the templates of SF Symbols.
H = 72.0
SMALL = 0.783
k = H / (y1 - y0) * SMALL
W = (x1 - x0) * k
MARGIN = 4 * SMALL
BASELINE_S, CAPLINE_S = 696.0, 625.54
top_s = (BASELINE_S + CAPLINE_S) / 2 - H * SMALL / 2
COLUMNS = {"Ultralight-S": 559.0, "Regular-S": 1391.0, "Black-S": 2224.0}
GUIDES = [("Baseline-S", 696), ("Capline-S", 625.54), ("Baseline-M", 1126), ("Capline-M", 1055.54),
          ("Baseline-L", 1556), ("Capline-L", 1485.54)]


def area(loop):
    return sum(loop[i - 1][0] * loop[i][1] - loop[i][0] * loop[i - 1][1] for i in range(len(loop))) / 2


def shapes(left):
    """The ring of the cloud, the pulse, and the flat line, placed in the column with the given left margin."""
    gx = left + MARGIN
    tr = lambda p: (gx + (p[0] - x0) * k, top_s + (p[1] - y0) * k)

    def path(loop, reverse=False):
        pts = [tr(p) for p in (reversed(loop) if reverse else loop)]
        return f"M{pts[0][0]:.2f} {pts[0][1]:.2f}" + "".join(f"L{x:.2f} {y:.2f}" for x, y in pts[1:]) + "Z"

    # The hole runs against the outer contour, so that nonzero filling leaves it open.
    ring = path(outer) + path(inner, reverse=(area(outer) > 0) == (area(inner) > 0))
    # The flat line: the stroke of the pulse at its left end, from its left to its right end.
    px0 = min(p[0] for p in pulse); px1 = max(p[0] for p in pulse)
    ends = [p[1] for p in pulse if p[0] < px0 + 25]
    top, bottom = min(ends), max(ends)
    cy = (top + bottom) / 2
    (ax, ay), (bx, by) = tr((px0, cy)), tr((px1, cy))
    r = (bottom - top) / 2 * k
    flat = (f"M{ax + r:.2f} {ay - r:.2f}H{bx - r:.2f}A{r:.2f} {r:.2f} 0 0 1 {bx - r:.2f} {by + r:.2f}"
            f"H{ax + r:.2f}A{r:.2f} {r:.2f} 0 0 1 {ax + r:.2f} {ay - r:.2f}Z")
    return gx + W + MARGIN, ring, path(pulse), flat


def svg(name, line):
    guides, margins, groups = [], [], []
    for n, y in GUIDES:
        guides.append(f'  <line id="{n}" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="{y}" y2="{y}"/>')
    for column, left in COLUMNS.items():
        right, ring, pulse_d, flat_d = shapes(left)
        for side, x in (("left", left), ("right", right)):
            margins.append(f'  <line id="{side}-margin-{column}" style="fill:none;stroke:#00AEEF;stroke-width:0.5;opacity:1.0;" x1="{x:.2f}" x2="{x:.2f}" y1="600.785" y2="720.121"/>')
        second = pulse_d if line == "pulse" else flat_d
        groups.append(f'  <g id="{column}">\n   <path d="{ring}"/>\n   <path d="{second}"/>\n  </g>')
    nl = "\n"
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">
<!--Generated from the optiCLOUD Sensor app icon by tracing its outline.-->
<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="3300" height="2200">
 <g id="Notes">
  <rect height="2200" id="artboard" style="fill:white;opacity:1" width="3300" x="0" y="0"/>
  <text id="template-version" style="stroke:none;fill:black;font-family:sans-serif;font-size:13;text-anchor:end;" transform="matrix(1 0 0 1 3036 1933)">Template v.6.0</text>
  <text id="descriptive-name" style="stroke:none;fill:black;font-family:sans-serif;font-size:13;text-anchor:end;" transform="matrix(1 0 0 1 3036 1953)">{name}</text>
 </g>
 <g id="Guides">
{nl.join(guides)}
{nl.join(margins)}
 </g>
 <g id="Symbols">
{nl.join(groups)}
 </g>
</svg>
'''


for name, line in (("opticloud.pulse", "pulse"), ("opticloud.off", "flat")):
    d = os.path.join(outdir, name + ".symbolset")
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, name + ".svg"), "w") as f:
        f.write(svg(name, line))
    with open(os.path.join(d, "Contents.json"), "w") as f:
        f.write(json.dumps({"info": {"author": "xcode", "version": 1},
                            "symbols": [{"filename": name + ".svg", "idiom": "universal"}]}, indent=2) + "\n")
    print(name)
