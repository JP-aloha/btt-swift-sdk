#
//  btt-inject.sh
//  blue-triangle
//
//  Created by Ashok Singh on 04/05/26.
//

#!/bin/bash
# BlueTriangle SDK - BTTInstrumentor injection script
# Usage:
#   Inject:  bash btt-inject.sh <search_path> <srcroot>
#   Restore: bash btt-inject.sh <search_path> <srcroot> --restore

ARCH=$(uname -m)
SEARCH_PATH=$1
SRC_ROOT=$2
MODE=$3  # empty = inject, --restore = restore

# ── Find bundle ───────────────────────────────────────────
BUNDLE=$(find "$SEARCH_PATH" "$SRC_ROOT/../../../" \
    -maxdepth 8 \
    -name "BTTInstrumentor.artifactbundle" \
    -type d 2>/dev/null | head -1)

if [ -z "$BUNDLE" ]; then
    echo "⚠️ BTTInstrumentor.artifactbundle not found"
    exit 0
fi

# ── Find binary from info.json ────────────────────────────
BINARY=$(python3 -c "
import json
variants = json.load(open('$BUNDLE/info.json'))['artifacts']['BTTInstrumentor']['variants']
match = [v for v in variants if '$ARCH' in v['supportedTriples'][0]]
print('$BUNDLE/' + match[0]['path'])
")

if [ ! -f "$BINARY" ]; then
    echo "⚠️ Binary not found: $BINARY"
    exit 0
fi

# ── Restore any leftover backups ──────────────────────────
# Called before inject — cleans up .bttbackup files left
# from a previous build that crashed or failed mid-way
restore_leftovers() {
    find "$SRC_ROOT" -name "*.swift.bttbackup" \
        ! -path "*/Pods/*" \
        ! -path "*/.build/*" \
        ! -path "*/DerivedData/*" \
        | while read BACKUP; do
            ORIGINAL="${BACKUP%.bttbackup}"
            if [ -f "$BACKUP" ]; then
                cp "$BACKUP" "$ORIGINAL"
                rm "$BACKUP"
                echo "♻️  Restored leftover: $ORIGINAL"
            fi
        done
}

# ── Inject or Restore ─────────────────────────────────────
if [ "$MODE" = "--restore" ]; then
    echo "🔄 BTT Restoring files..."
    find "$SRC_ROOT" -name "*.swift" \
        ! -path "*/Pods/*" \
        ! -path "*/.build/*" \
        ! -path "*/BTTInstrumentor/*" \
        ! -path "*/DerivedData/*" \
        | while read F; do
            "$BINARY" "$F" --restore
        done
    echo "✅ BTT restore complete"
else
    # Safety restore before injecting
    echo "🔍 Checking for leftover backups from previous failed build..."
    restore_leftovers

    echo "🔧 BTT Injecting... (arch: $ARCH)"
    find "$SRC_ROOT" -name "*.swift" \
        ! -path "*/Pods/*" \
        ! -path "*/.build/*" \
        ! -path "*/BTTInstrumentor/*" \
        ! -path "*/DerivedData/*" \
        | while read F; do
            "$BINARY" "$F"
        done
    echo "✅ BTT injection complete"
fi
