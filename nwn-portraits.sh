#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
    echo "Usage: $0 image-file" >&2
    exit 1
}

die() {
    echo "Error: $*" >&2
    exit 1
}

[[ $# -eq 1 ]] || usage

INPUT=$1
[[ -f "$INPUT" && -r "$INPUT" ]] ||
    die "input file does not exist or is not readable: $INPUT"

for cmd in magick zip; do
    command -v "$cmd" >/dev/null 2>&1 ||
        die "'$cmd' is not installed. Install with: sudo xbps-install -S ImageMagick zip"
done

FILENAME=${INPUT##*/}
BASENAME=${FILENAME%.*}

[[ -n "$BASENAME" && "$BASENAME" != "$FILENAME" ]] ||
    die "error BAD FILENAME"

(( ${#BASENAME} <= 15 )) ||
    die "error NAME > 15 CHARS"

variants=(
    'H 256x400 256x512'
    'L 128x200 128x256'
    'M 64x100 64x128'
    'S 32x50 32x64'
    'T 16x25 16x32'
)

TEMP_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEMP_DIR"' EXIT

for variant in "${variants[@]}"; do
    read -r suffix size canvas <<< "$variant"
    target="$TEMP_DIR/${BASENAME}${suffix}.tga"

    magick "$INPUT" \
        -resize "${size}^" \
        -gravity north \
        -background black \
        -extent "$canvas" \
        -compress None \
        "$target"

    printf 'Wrote %s\n' "${target##*/}"
done

ZIP_FILE="$PWD/${BASENAME}.zip"

(
    cd "$TEMP_DIR"
    zip -q "$ZIP_FILE.tmp" ./*.tga
)

mv -f -- "$ZIP_FILE.tmp" "$ZIP_FILE"

printf '\nSuccess! Created portrait archive:\n%s\n\n' "$ZIP_FILE"
zip -sf "$ZIP_FILE"
