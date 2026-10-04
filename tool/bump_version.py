#!/usr/bin/env python3
"""Bumps the app version in pubspec.yaml before a new Google Play release.

    python3 tool/bump_version.py patch   # 1.0.0+1 -> 1.0.1+2  (bug fixes)
    python3 tool/bump_version.py minor   # 1.0.1+2 -> 1.1.0+3  (new games/books)
    python3 tool/bump_version.py major   # 1.1.0+3 -> 2.0.0+4  (big redesign)
    python3 tool/bump_version.py build   # 1.1.0+3 -> 1.1.0+4  (re-upload, same version)

The version name (1.0.1) is what parents see in the Play Store. The build
number (+2) is Android's versionCode: Google Play only accepts an upload if it
is higher than every build uploaded before, so it always goes up by one.
"""
import pathlib
import re
import sys

PUBSPEC = pathlib.Path(__file__).resolve().parent.parent / "pubspec.yaml"


def main() -> None:
    part = sys.argv[1] if len(sys.argv) > 1 else ""
    if part not in ("major", "minor", "patch", "build"):
        sys.exit(__doc__)
    text = PUBSPEC.read_text()
    m = re.search(r"^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$", text, re.M)
    if not m:
        sys.exit("pubspec.yaml needs a version like 1.0.0+1")
    major, minor, patch, build = map(int, m.groups())
    if part == "major":
        major, minor, patch = major + 1, 0, 0
    elif part == "minor":
        minor, patch = minor + 1, 0
    elif part == "patch":
        patch += 1
    build += 1
    new = f"{major}.{minor}.{patch}+{build}"
    PUBSPEC.write_text(text[: m.start()] + f"version: {new}" + text[m.end():])
    print(f"{m.group(0).split(':', 1)[1].strip()} -> {new}  (versionName {major}.{minor}.{patch}, versionCode {build})")


if __name__ == "__main__":
    main()
