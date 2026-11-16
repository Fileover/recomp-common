#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 Tommy McLeroy. Part of recomp-common: https://github.com/tmcleroy/recomp-common
#
# tools/flags.sh FLAG_ICONS_DIR
# Makes the launcher's country flags from flag-icons (https://github.com/lipis/flag-icons, MIT; FLAG_ICONS_DIR is its
# npm package unpacked, `npm pack flag-icons`): launcher/flags.png, every ISO country's 4x3 flag at 48x36 in rows of
# 16, by code, and launcher/src/countries.h, the codes and names in that order. Needs ImageMagick (magick) and python3.
set -eu
src=$1
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
python3 -I - "$src/country.json" "$tmp/list" <<'PY'
import json, sys
countries = sorted((c["code"], c["name"]) for c in json.load(open(sys.argv[1], encoding="utf-8")) if c.get("iso"))
with open(sys.argv[2], "w", encoding="utf-8") as out:
    for code, name in countries:
        out.write(f"{code}\t{name}\n")
PY
cut -f1 "$tmp/list" | while read -r code; do
    # (a font for the two flags with words on them, too small to read at this size)
    magick -font "${FLAG_FONT:-/System/Library/Fonts/Supplemental/Arial.ttf}" -background none -density 300 \
        "$src/flags/4x3/$code.svg" -resize '48x36!' -background white -flatten "$tmp/$code.png"
    echo "$tmp/$code.png"
done > "$tmp/files"
magick montage @"$tmp/files" -tile 16x -geometry 48x36+0+0 -background white "$tmp/atlas.png"
magick "$tmp/atlas.png" -strip -depth 8 -dither None -colors 256 -define png:compression-level=9 PNG8:"$root/launcher/flags.png"
python3 -I - "$tmp/list" "$root/launcher/src/countries.h" <<'PY'
import sys
rows = [line.rstrip("\n").split("\t") for line in open(sys.argv[1], encoding="utf-8")]
with open(sys.argv[2], "w", encoding="utf-8") as out:
    out.write("// SPDX-License-Identifier: GPL-3.0-only\n"
              "// Copyright (C) 2026 Tommy McLeroy. Part of recomp-common: https://github.com/tmcleroy/recomp-common\n"
              "// Made by tools/flags.sh from flag-icons (MIT): the countries whose flags are in launcher/flags.png, in its order\n"
              "// (48x36 each, 16 to a row). Don't change it here.\n"
              "#pragma once\n\nnamespace launcher {\n\nstruct CountryFlag {\n    const char* code; // (ISO 3166-1, upper case)\n"
              "    const char* name;\n};\n\n")
    out.write(f"constexpr int kFlagWidth = 48, kFlagHeight = 36, kFlagsAcross = 16, kFlagCount = {len(rows)};\n\n")
    out.write("constexpr CountryFlag kCountryFlags[kFlagCount] = {\n")
    for code, name in rows:
        name = name.replace("\\", "\\\\").replace('"', '\\"')
        out.write(f'    {{"{code.upper()}", "{name}"}},\n')
    out.write("};\n\n} // namespace launcher\n")
PY
echo "flags: $(wc -l < "$tmp/list" | tr -d ' ') countries, launcher/flags.png $(wc -c < "$root/launcher/flags.png" | tr -d ' ') bytes"
