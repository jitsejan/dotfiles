#!/usr/bin/env python3
"""Derive an iTerm2 colour preset from the tracked Ghostty config.

Ghostty's config is the single source of truth for the terminal palette. iTerm2
cannot read it, so this translates the same values into the .itermcolors plist
iTerm2 imports. Generating rather than hand-copying means the two terminals
cannot drift apart — re-run this after editing .config/ghostty/config.

Usage: generate_itermcolors.py <ghostty-config> <output.itermcolors>
"""
import plistlib
import re
import sys


def hex_to_components(value):
    """#rrggbb -> the 0..1 component dict iTerm2 stores."""
    value = value.strip().lstrip("#")
    r, g, b = (int(value[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    return {
        "Color Space": "sRGB",
        "Red Component": r,
        "Green Component": g,
        "Blue Component": b,
        "Alpha Component": 1.0,
    }


def parse_ghostty(path):
    palette, named = {}, {}
    key_re = re.compile(r"^\s*([a-z0-9-]+)\s*=\s*(.+?)\s*$")
    for line in open(path, encoding="utf-8"):
        if line.lstrip().startswith("#"):
            continue
        m = key_re.match(line)
        if not m:
            continue
        key, val = m.group(1), m.group(2)
        if key == "palette":
            # "palette = 3=#fa8419"
            idx, _, colour = val.partition("=")
            if colour.strip().startswith("#"):
                palette[int(idx)] = colour.strip()
        elif val.startswith("#"):
            named[key] = val
    return palette, named


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    src, dest = sys.argv[1], sys.argv[2]
    palette, named = parse_ghostty(src)

    missing = [i for i in range(16) if i not in palette]
    if missing:
        sys.exit(f"ghostty config is missing palette entries: {missing}")

    out = {f"Ansi {i} Color": hex_to_components(palette[i]) for i in range(16)}

    # iTerm2 splits out a few roles Ghostty names differently. Fall back to
    # sensible palette entries when Ghostty doesn't set one explicitly.
    out["Background Color"] = hex_to_components(named.get("background", palette[0]))
    out["Foreground Color"] = hex_to_components(named.get("foreground", palette[7]))
    out["Bold Color"] = hex_to_components(named.get("foreground", palette[15]))
    out["Cursor Color"] = hex_to_components(named.get("cursor-color", palette[15]))
    out["Cursor Text Color"] = hex_to_components(named.get("background", palette[0]))
    out["Selection Color"] = hex_to_components(named.get("selection-background", palette[8]))
    out["Selected Text Color"] = hex_to_components(
        named.get("selection-foreground", named.get("foreground", palette[7]))
    )
    # Not set by Ghostty; keep the cursor guide subtle rather than iTerm2's blue.
    out["Cursor Guide Color"] = hex_to_components(named.get("selection-background", palette[8]))

    with open(dest, "wb") as fh:
        plistlib.dump(out, fh, sort_keys=True)
    print(f"wrote {dest} ({len(out)} colours from {src})")


if __name__ == "__main__":
    main()
