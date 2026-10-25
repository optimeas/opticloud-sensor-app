# Design

Shared design sources of optiCLOUD Sensor. Each app follows its platform's design standards; what is shared is the app icon and the brand colors.

## Brand colors

The colors come from the optiMEAS palette.

| Name | Hex | Use |
| --- | --- | --- |
| Accent blue | `#0088c2` | b1: background, lower right end of the gradient |
| Light blue 1 | `#62a0cf` | b1: background, upper left end of the gradient; the cloud in dark mode |
| Orange | `#f39200` | b1, b3: the curve; b2: the lower part in dark mode |
| Orange, deep | `#f36000` | b2: the lower part |
| Black 1 | `#2e1900` | b2: the upper part; b3: background |
| Grey 3 | `#e6e6e5` | b2: the upper part in dark mode; b3: the cloud in dark mode |

The optiMEAS logo is a trademark and is not part of this repository.

## App icon

A cloud with a measured curve. It refers to optiCLOUD and to the values the phone measures. There are three variants; **b1 is the icon of both apps**, b2 and b3 are kept as alternatives.

| Variant | Look |
| --- | --- |
| `b1` | White cloud outline with an orange zigzag curve, on a blue gradient |
| `b2` | Filled cloud split by a rising curve: dark above, orange below, on white |
| `b3` | White cloud outline with a soft orange arc, on Black 1 |

The geometry lives in [`app-icon/generate.py`](app-icon/generate.py), which writes all sources. Each variant folder holds:

| File | Use |
| --- | --- |
| `icon-light.svg` | iOS icon, default appearance, with background |
| `icon-dark.svg` | iOS icon, dark appearance, transparent background |
| `icon-tinted.svg` | iOS icon, tinted appearance, grey levels on a transparent background |
| `android/drawable/ic_launcher_foreground.xml` | Android adaptive icon, foreground; the cloud lies inside the 66 dp safe zone |
| `android/drawable/ic_launcher_background.xml` | Android adaptive icon, background |
| `android/drawable/ic_launcher_monochrome.xml` | Android themed icon |
| `android/mipmap-anydpi-v26/ic_launcher*.xml` | Android adaptive icon definitions |

[`app-icon/render.swift`](app-icon/render.swift) renders an SVG to the 1024 px PNG of the iOS asset catalog (macOS only):

```sh
cd docs/design/app-icon
python3 generate.py .
for v in light dark tinted; do
  swift render.swift b1/icon-$v.svg ../../../ios/OptiCloudSensor/Assets.xcassets/AppIcon.appiconset/AppIcon-$v.png
done
```

The Android app copies the files of `b1/android/` into `android/app/src/main/res/`.
