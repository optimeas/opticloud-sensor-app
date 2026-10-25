# Writes OptiCloudSensor/About/Licenses.json from the resolved packages of the app and their license files, and
# OptiCloudSensor/About/License.txt from the license of this repository.
# Run from ios/ after `swift build` in SensorCore has checked out the packages:
#   python3 Tools/generate-licenses.py
import glob, json, os

resolved = json.load(open("OptiCloudSensor.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"))
checkouts = "SensorCore/.build/checkouts"

def read(folder, names):
    for name in names:
        path = os.path.join(folder, name)
        if os.path.exists(path):
            return open(path, encoding="utf-8").read().strip()
    return None

packages = []
for pin in sorted(resolved["pins"], key=lambda p: p["identity"]):
    folder = os.path.join(checkouts, pin["identity"])
    text = read(folder, ["LICENSE.txt", "LICENSE", "LICENSE.md"])
    if text is None:
        raise SystemExit(f"no license file for {pin['identity']}")
    license = "Apache License 2.0" if "Apache License" in text else "See license text"
    packages.append({
        "name": pin["identity"],
        "url": pin["location"].removesuffix(".git"),
        "version": pin["state"].get("version") or pin["state"].get("revision", "")[:7],
        "license": license,
        "notice": read(folder, ["NOTICE.txt", "NOTICE"]),
        "text": text,
    })

with open("OptiCloudSensor/About/License.txt", "w", encoding="utf-8") as file:
    file.write(open("../LICENSE", encoding="utf-8").read())

with open("OptiCloudSensor/About/Licenses.json", "w", encoding="utf-8") as file:
    json.dump(packages, file, indent=1, ensure_ascii=False)
print(f"{len(packages)} packages")
