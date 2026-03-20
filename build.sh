#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
GODOT="${GODOT_BIN:-/tmp/godot461/Godot_v4.6.1-stable_linux.x86_64}"
VERSION_FILE="$PROJECT_DIR/VERSION"
EXPORT_PRESETS="$PROJECT_DIR/export_presets.cfg"
EXPORT_DIR="$PROJECT_DIR/export/android"
APK_NAME="7DaysJourney"

# --- Parse arguments ---
RELEASE=false
BUMP=""
for arg in "$@"; do
    case "$arg" in
        --release)    RELEASE=true ;;
        --bump-major) BUMP="major" ;;
        --bump-minor) BUMP="minor" ;;
        --bump-patch) BUMP="patch" ;;
        --help|-h)
            echo "Usage: ./build.sh [OPTIONS]"
            echo ""
            echo "Builds the APK. Use install.sh to deploy to device."
            echo ""
            echo "Options:"
            echo "  --release       Build release (signed) APK instead of debug"
            echo "  --bump-major    Bump major version before build (X.0.0)"
            echo "  --bump-minor    Bump minor version before build (0.X.0)"
            echo "  --bump-patch    Bump patch version before build (0.0.X)"
            echo "  -h, --help      Show this help"
            echo ""
            echo "Environment:"
            echo "  GODOT_BIN       Path to Godot binary (default: /tmp/godot461/Godot_v4.6.1-stable_linux.x86_64)"
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg (use --help)"
            exit 1
            ;;
    esac
done

# --- Check Godot binary ---
if [ ! -f "$GODOT" ]; then
    echo "ERROR: Godot binary not found at: $GODOT"
    echo "Set GODOT_BIN environment variable to the correct path."
    exit 1
fi

# --- Read and optionally bump version ---
if [ ! -f "$VERSION_FILE" ]; then
    echo "0.1.0" > "$VERSION_FILE"
fi
VERSION=$(head -1 "$VERSION_FILE" | tr -d '[:space:]')
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

if [ -n "$BUMP" ]; then
    case "$BUMP" in
        major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
        minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
        patch) PATCH=$((PATCH + 1)) ;;
    esac
    VERSION="${MAJOR}.${MINOR}.${PATCH}"
    echo "$VERSION" > "$VERSION_FILE"
    echo "Version bumped to $VERSION"
fi

# --- Compute version code (major*10000 + minor*100 + patch) ---
VERSION_CODE=$(( MAJOR * 10000 + MINOR * 100 + PATCH ))

echo "=== Building 7 Days Journey v${VERSION} (code ${VERSION_CODE}) ==="

# --- Update export_presets.cfg ---
sed -i "s|^version/code=.*|version/code=${VERSION_CODE}|" "$EXPORT_PRESETS"
sed -i "s|^version/name=.*|version/name=\"${VERSION}\"|" "$EXPORT_PRESETS"
echo "Updated export_presets.cfg"

# --- Ensure export directory exists ---
mkdir -p "$EXPORT_DIR"

# --- Import project ---
echo "Importing project..."
cd "$PROJECT_DIR"
"$GODOT" --headless --import 2>&1 | tail -3

# --- Export APK ---
TIMESTAMP=$(date +%s)
APK_PATH="${EXPORT_DIR}/${APK_NAME}-v${VERSION}-${TIMESTAMP}.apk"
if [ "$RELEASE" = true ]; then
    echo "Exporting release APK..."
    "$GODOT" --headless --export-release "Android" "$APK_PATH" 2>&1 | tail -5
else
    echo "Exporting debug APK..."
    "$GODOT" --headless --export-debug "Android" "$APK_PATH" 2>&1 | tail -5
fi

# --- Verify ---
if [ ! -f "$APK_PATH" ]; then
    echo "ERROR: APK not found at $APK_PATH"
    exit 1
fi
APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo ""
echo "=== Built: $APK_PATH ($APK_SIZE) v${VERSION} ==="
echo "Run ./install.sh to deploy to device."
