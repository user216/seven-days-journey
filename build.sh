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
BUILD_WEB=false
for arg in "$@"; do
    case "$arg" in
        --release)    RELEASE=true ;;
        --web)        BUILD_WEB=true ;;
        --bump-major) BUMP="major" ;;
        --bump-minor) BUMP="minor" ;;
        --bump-patch) BUMP="patch" ;;
        --help|-h)
            echo "Usage: ./build.sh [OPTIONS]"
            echo ""
            echo "Builds the APK (default) or Web export. Use install.sh to deploy APK to device."
            echo ""
            echo "Options:"
            echo "  --release       Build release (signed) instead of debug"
            echo "  --web           Build Web (HTML5) export instead of Android APK"
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

# --- Run tests before build ---
echo "Running tests..."
"$GODOT" --headless --script tests/test_runner.gd 2>&1 | tail -5
RUNNER_EXIT=$?
if [ $RUNNER_EXIT -ne 0 ]; then
    echo "ERROR: Unit tests failed (exit code $RUNNER_EXIT). Build aborted."
    exit 1
fi
"$GODOT" --headless --script tests/test_e2e.gd 2>&1 | tail -5
E2E_EXIT=$?
if [ $E2E_EXIT -ne 0 ]; then
    echo "ERROR: E2E tests failed (exit code $E2E_EXIT). Build aborted."
    exit 1
fi
echo "All tests passed."

# --- Export ---
if [ "$BUILD_WEB" = true ]; then
    # --- Web (HTML5) export ---
    WEB_EXPORT_DIR="$PROJECT_DIR/export/web"
    mkdir -p "$WEB_EXPORT_DIR"
    if [ "$RELEASE" = true ]; then
        echo "Exporting release Web build..."
        "$GODOT" --headless --export-release "Web" "$WEB_EXPORT_DIR/index.html" 2>&1 | tail -5
    else
        echo "Exporting debug Web build..."
        "$GODOT" --headless --export-debug "Web" "$WEB_EXPORT_DIR/index.html" 2>&1 | tail -5
    fi

    if [ ! -f "$WEB_EXPORT_DIR/index.wasm" ]; then
        echo "ERROR: Web export failed — index.wasm not found"
        exit 1
    fi

    # --- Post-build: apply index.html customizations ---
    # Godot regenerates index.html from its template on every export,
    # so we patch it with sattvic theme and Telegram Mini App support.
    INDEX="$WEB_EXPORT_DIR/index.html"
    echo "Applying index.html customizations..."
    # Sattvic body styling
    sed -i 's|color: white;|color: #3d3929;|' "$INDEX"
    sed -i "s|background-color: black;|background-color: #fefcf3;|" "$INDEX"
    sed -i '/touch-action: none;/a\\tfont-family: '"'"'Noto Sans'"'"', '"'"'Droid Sans'"'"', Arial, sans-serif;' "$INDEX"
    # Status overlay background
    sed -i 's|background-color: #242424;|background-color: #fefcf3;|' "$INDEX"
    # Progress bar styling
    sed -i '/margin: 0 auto;/{
        /status-progress/!b
        a\\taccent-color: #7da344;\n\theight: 8px;\n\tborder-radius: 4px;
    }' "$INDEX"
    # Notice styling (sattvic warm instead of dark red)
    sed -i 's|background-color: #5b3943;|background-color: #f5f0e1;|' "$INDEX"
    sed -i 's|border: 1px solid #9b3943;|border: 1px solid #c4a96a;|' "$INDEX"
    sed -i 's|color: #e0e0e0;|color: #3d3929;|' "$INDEX"
    # Disable COOP/COEP enforcement (threads off, breaks Telegram iframe)
    sed -i 's|"ensureCrossOriginIsolationHeaders":true|"ensureCrossOriginIsolationHeaders":false|' "$INDEX"
    # Inject Telegram WebApp SDK
    sed -i '/<\/head>/i\<script src="https://telegram.org/js/telegram-web-app.js"><\/script>\n<script>\nif (window.Telegram \&\& window.Telegram.WebApp) {\n\twindow.Telegram.WebApp.ready();\n\twindow.Telegram.WebApp.expand();\n}\n<\/script>' "$INDEX"
    echo "index.html customizations applied."

    WASM_SIZE=$(du -h "$WEB_EXPORT_DIR/index.wasm" | cut -f1)
    echo ""
    echo "=== Web export complete: $WEB_EXPORT_DIR/ (WASM: $WASM_SIZE) v${VERSION} ==="
    echo "Serve with: python serve_web.py"
else
    # --- Android APK export ---
    TIMESTAMP=$(date +%s)
    APK_PATH="${EXPORT_DIR}/${APK_NAME}-v${VERSION}-${TIMESTAMP}.apk"
    if [ "$RELEASE" = true ]; then
        echo "Exporting release APK..."
        "$GODOT" --headless --export-release "Android" "$APK_PATH" 2>&1 | tail -5
    else
        echo "Exporting debug APK..."
        "$GODOT" --headless --export-debug "Android" "$APK_PATH" 2>&1 | tail -5
    fi

    if [ ! -f "$APK_PATH" ]; then
        echo "ERROR: APK not found at $APK_PATH"
        exit 1
    fi
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo ""
    echo "=== Built: $APK_PATH ($APK_SIZE) v${VERSION} ==="
    echo "Run ./install.sh to deploy to device."
fi
