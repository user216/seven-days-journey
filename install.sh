#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
EXPORT_DIR="$SCRIPT_DIR/export/android"
VERSION_FILE="$SCRIPT_DIR/VERSION"

# --- Parse arguments ---
LAUNCH=false
DEVICE=""
for arg in "$@"; do
    case "$arg" in
        --launch)  LAUNCH=true ;;
        --device=*) DEVICE="${arg#--device=}" ;;
        --help|-h)
            echo "Usage: ./install.sh [OPTIONS]"
            echo ""
            echo "Installs the built APK on a connected Android device."
            echo ""
            echo "Options:"
            echo "  --launch        Launch the app after install"
            echo "  --device=ID     Target specific device (adb -s ID)"
            echo "  -h, --help      Show this help"
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg (use --help)"
            exit 1
            ;;
    esac
done

# --- Find latest APK ---
APK_PATH=$(ls -t "$EXPORT_DIR"/7DaysJourney-*.apk 2>/dev/null | head -1 || true)
if [ -z "$APK_PATH" ] || [ ! -f "$APK_PATH" ]; then
    echo "ERROR: No APK found in $EXPORT_DIR"
    echo "Run ./build.sh first."
    exit 1
fi

# --- Check adb ---
if ! command -v adb &>/dev/null; then
    echo "ERROR: adb not found in PATH"
    exit 1
fi

# --- Build adb args ---
ADB_ARGS=()
if [ -n "$DEVICE" ]; then
    ADB_ARGS+=(-s "$DEVICE")
fi

# --- Show what we're installing ---
VERSION=$(head -1 "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]' || echo "unknown")
APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
APK_DATE=$(date -r "$APK_PATH" "+%Y-%m-%d %H:%M:%S")
echo "=== Installing 7 Days Journey v${VERSION} (${APK_SIZE}, built ${APK_DATE}) ==="

# --- Install ---
adb "${ADB_ARGS[@]}" install -r "$APK_PATH" 2>&1
echo "Installed."

# --- Launch ---
if [ "$LAUNCH" = true ]; then
    PACKAGE="com.sevendaysjourney.game"
    echo "Launching ${PACKAGE}..."
    adb "${ADB_ARGS[@]}" shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1 2>&1
fi

echo "=== Done ==="
