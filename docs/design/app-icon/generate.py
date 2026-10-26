# Writes the icon sources of this folder, one subfolder per variant. Usage: python3 generate.py <this folder>
# b1 is the icon of the apps; b2 and b3 are kept as alternatives. dev is b1 in orange for the iOS development build.
import math, os, sys
out = sys.argv[1]

# Geometry in a 100x100 box: the outline of a cloud, three circles over a flat base.
A, B, C = (34, 59, 14), (52, 47, 20), (68, 61, 12)
BASE = 73

def upper_intersection(p, q):
    (x0, y0, r0), (x1, y1, r1) = p, q
    d = math.dist((x0, y0), (x1, y1))
    a = (r0 * r0 - r1 * r1 + d * d) / (2 * d)
    h = math.sqrt(r0 * r0 - a * a)
    mx, my = x0 + a * (x1 - x0) / d, y0 + a * (y1 - y0) / d
    points = [(mx + h * (y1 - y0) / d, my - h * (x1 - x0) / d), (mx - h * (y1 - y0) / d, my + h * (x1 - x0) / d)]
    return min(points, key=lambda pt: pt[1])

def f(v):
    return f"{v:.2f}".rstrip("0").rstrip(".")

ab, bc = upper_intersection(A, B), upper_intersection(B, C)
CLOUD = (f"M{A[0]},{BASE} "
         f"A{A[2]},{A[2]} 0 0,1 {f(ab[0])},{f(ab[1])} "
         f"A{B[2]},{B[2]} 0 1,1 {f(bc[0])},{f(bc[1])} "
         f"A{C[2]},{C[2]} 0 0,1 {C[0]},{BASE} Z")
ZIGZAG = "M29,61 L39,61 L45,49 L52,66 L58,55 L67,55"
ARC = "M31,63 Q52,64 64,47"
STROKE = 5
# b2: a rising curve splits the filled cloud; half the gap, across the curve.
dx, dy = 1.4, 2.6
ABOVE = f"M-10,{64.8-dy} L{14-dx},{66-dy} Q{60-dx},{70-dy} {86-dx},{30-dy} L{105.5-dx},{-dy} L110,-10 L-10,-10 Z"
BELOW = f"M-10,{64.8+dy} L{14+dx},{66+dy} Q{60+dx},{70+dy} {86+dx},{30+dy} L{105.5+dx},{dy} L110,110 L-10,110 Z"

BLUE_LIGHT, BLUE, ORANGE, ORANGE_DEEP = "#62a0cf", "#0088c2", "#f39200", "#f36000"
BLACK, GREY, WHITE = "#2e1900", "#e6e6e5", "#ffffff"

# A layer is ("stroke", path, color) or ("fill", path, color, clip).
VARIANTS = {
    "b1": {
        "background": ("gradient", BLUE_LIGHT, BLUE),
        "light": [("stroke", CLOUD, WHITE), ("stroke", ZIGZAG, ORANGE)],
        "dark": [("stroke", CLOUD, BLUE_LIGHT), ("stroke", ZIGZAG, ORANGE)],
        "tinted": [("stroke", CLOUD, "#f0f0f0"), ("stroke", ZIGZAG, "#a0a0a0")],
    },
    "dev": {
        "background": ("gradient", ORANGE, ORANGE_DEEP),
        "light": [("stroke", CLOUD, WHITE), ("stroke", ZIGZAG, BLACK)],
        "dark": [("stroke", CLOUD, ORANGE), ("stroke", ZIGZAG, GREY)],
        "tinted": [("stroke", CLOUD, "#f0f0f0"), ("stroke", ZIGZAG, "#a0a0a0")],
    },
    "b2": {
        "background": ("solid", WHITE),
        "light": [("fill", CLOUD, BLACK, ABOVE), ("fill", CLOUD, ORANGE_DEEP, BELOW)],
        "dark": [("fill", CLOUD, GREY, ABOVE), ("fill", CLOUD, ORANGE, BELOW)],
        "tinted": [("fill", CLOUD, "#f0f0f0", ABOVE), ("fill", CLOUD, "#8c8c8c", BELOW)],
    },
    "b3": {
        "background": ("solid", BLACK),
        "light": [("stroke", CLOUD, WHITE), ("stroke", ARC, ORANGE)],
        "dark": [("stroke", CLOUD, GREY), ("stroke", ARC, ORANGE)],
        "tinted": [("stroke", CLOUD, "#f0f0f0"), ("stroke", ARC, "#a0a0a0")],
    },
}

def svg_layer(layer, i):
    if layer[0] == "stroke":
        return (f'<path d="{layer[1]}" fill="none" stroke="{layer[2]}" stroke-width="{STROKE}" '
                f'stroke-linecap="round" stroke-linejoin="round"/>')
    return f'<path d="{layer[1]}" fill="{layer[2]}" clip-path="url(#c{i})"/>'

def svg(background, layers):
    defs = "".join(f'<clipPath id="c{i}"><path d="{l[3]}"/></clipPath>' for i, l in enumerate(layers) if l[0] == "fill")
    rect = ""
    if background and background[0] == "gradient":
        defs += (f'<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">'
                 f'<stop offset="0" stop-color="{background[1]}"/><stop offset="1" stop-color="{background[2]}"/></linearGradient>')
        rect = '<rect width="100" height="100" fill="url(#bg)"/>'
    elif background:
        rect = f'<rect width="100" height="100" fill="{background[1]}"/>'
    body = "\n    ".join(svg_layer(l, i) for i, l in enumerate(layers))
    # iOS: the cloud fills about 60 % of the icon, centred.
    return f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" width="1024" height="1024">
  <defs>{defs}</defs>
  {rect}
  <g transform="translate(50 50) scale(1.05) translate(-50 -52)">
    {body}
  </g>
</svg>
'''

def vector_layer(layer, color=None):
    color = color or layer[2]
    if layer[0] == "stroke":
        return f'''        <path
            android:pathData="{layer[1]}"
            android:strokeColor="{color}"
            android:strokeWidth="{STROKE}"
            android:strokeLineCap="round"
            android:strokeLineJoin="round" />'''
    return f'''        <group>
            <clip-path android:pathData="{layer[3]}" />
            <path
                android:fillColor="{color}"
                android:pathData="{layer[1]}" />
        </group>'''

def vector(layers, color=None):
    # Android adaptive icon: 108x108 dp, the cloud inside the 66 dp safe circle.
    body = "\n".join(vector_layer(l, color) for l in layers)
    return f'''<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="100"
    android:viewportHeight="100">
    <group
        android:pivotX="50"
        android:pivotY="50"
        android:scaleX="0.85"
        android:scaleY="0.85"
        android:translateY="-2">
{body}
    </group>
</vector>
'''

def android_background(background):
    if background[0] == "gradient":
        fill = f'''    <gradient
        android:angle="315"
        android:startColor="{background[1]}"
        android:endColor="{background[2]}" />'''
    else:
        fill = f'    <solid android:color="{background[1]}" />'
    return f'''<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">
{fill}
</shape>
'''

ADAPTIVE = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />
</adaptive-icon>
'''

def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "w").write(text)

for name, v in VARIANTS.items():
    base = f"{out}/{name}"
    write(f"{base}/icon-light.svg", svg(v["background"], v["light"]))
    write(f"{base}/icon-dark.svg", svg(None, v["dark"]))
    write(f"{base}/icon-tinted.svg", svg(None, v["tinted"]))
    if name == "dev":
        continue
    write(f"{base}/android/drawable/ic_launcher_foreground.xml", vector(v["light"]))
    write(f"{base}/android/drawable/ic_launcher_monochrome.xml", vector(v["light"], WHITE))
    write(f"{base}/android/drawable/ic_launcher_background.xml", android_background(v["background"]))
    for file in ["ic_launcher.xml", "ic_launcher_round.xml"]:
        write(f"{base}/android/mipmap-anydpi-v26/{file}", ADAPTIVE)
