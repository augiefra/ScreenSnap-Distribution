#!/bin/bash
#
# Batch process screenshots for App Store Connect
# Usage: ./batch_appstore_screenshots.sh <input_directory> [size]
#

INPUT_DIR="${1:-../onboarding}"
SIZE="${2:-1440x900}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "📸 Processing screenshots from: $INPUT_DIR"
echo "📐 Target size: $SIZE"
echo ""

# Counter
count=0

# Process all PNG files
for img in "$INPUT_DIR"/*.png; do
    if [ -f "$img" ]; then
        echo "Processing: $(basename "$img")"
        python3 "$SCRIPT_DIR/create_appstore_screenshots.py" "$img" "$SIZE"
        ((count++))
        echo ""
    fi
done

echo "✅ Processed $count images"
echo "📁 Output location: $INPUT_DIR"
