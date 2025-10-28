#!/usr/bin/env bash
set -euo pipefail
ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
PROJECT="$ROOT/TorchPatterns.xcodeproj"
SCHEME="TorchPatterns"
APP_BUNDLE_ID="com.example.torchpatterns"
DERIVED="$ROOT/.build"

say() { printf "[+] %s\n" "$*"; }
warn() { printf "[!] %s\n" "$*"; }
fail() { printf "[x] %s\n" "$*"; exit 1; }

# 1) Preconditions
command -v xcodebuild >/dev/null || fail "Xcode command line tools not found"
command -v xcodegen >/dev/null || fail "xcodegen not found (brew install xcodegen)"

# 2) Team detection
TEAM_ID="${TEAM_ID:-}"
ACDB="$HOME/Library/Developer/Xcode/Accounts.db"
if [[ -z "$TEAM_ID" && -f "$ACDB" ]]; then
  TEAM_ID=$(sqlite3 "$ACDB" "SELECT ZTEAMID FROM ZTEAM LIMIT 1;" 2>/dev/null || true)
fi
if [[ -z "$TEAM_ID" ]]; then
  warn "No TEAM_ID found. Sign into Xcode (Settings > Accounts) and set TEAM_ID env var."
fi

# 3) Ensure project exists and has team set if available
if [[ ! -d "$ROOT/TorchPatterns" ]]; then
  fail "Sources not found at $ROOT/TorchPatterns."
fi
if [[ -f "$ROOT/project.yml" && -n "$TEAM_ID" ]]; then
  say "Injecting team $TEAM_ID into project.yml"
  # Replace DEVELOPMENT_TEAM: "" with the value
  perl -0777 -i -pe "s/DEVELOPMENT_TEAM:\s*\"\"/DEVELOPMENT_TEAM: \"$TEAM_ID\"/" "$ROOT/project.yml"
fi

say "Generating Xcode project"
( cd "$ROOT" && xcodegen generate >/dev/null )

# 4) Detect connected device IDs
say "Detecting connected iPhones"
CORE_ID=""
BUILD_UDID=""
if xcrun devicectl list devices -j >/dev/null 2>&1; then
  DEV_JSON=$(xcrun devicectl list devices -j 2>/dev/null || true)
  CORE_ID=$(echo "$DEV_JSON" | /usr/bin/python3 - <<'PY'
import sys, json
try:
    j=json.load(sys.stdin)
    for d in j.get('result', {}).get('devices', []):
        plat=d.get('platform') or {}
        if plat.get('identifier','').startswith('com.apple.platform.iphoneos') and d.get('connectionState') in ('connected','available'):
            print(d.get('identifier')); break
except Exception:
    pass
PY
  )
fi
if [[ -z "$CORE_ID" ]]; then
  # Fallback: parse plaintext output and pick first available paired iPhone
  OUT=$(xcrun devicectl list devices 2>/dev/null || true)
  CORE_ID=$(echo "$OUT" | awk '/available/ && /iPhone/ {for(i=1;i<=NF;i++){if($i ~ /^[A-F0-9]{8}(-[A-F0-9]{4}){3}-[A-F0-9]{12}$/){print $i; exit}}}')
fi
if [[ -z "$CORE_ID" ]]; then
  fail "No connected iPhone detected. Unlock device, Trust this Computer, enable Developer Mode (Settings > Privacy & Security)."
fi
say "Using CoreDevice ID: $CORE_ID"

# Determine xcodebuild destination UDID from showdestinations (different from CoreDevice ID)
DESTS=$( /usr/bin/xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showdestinations 2>/dev/null || true )
BUILD_UDID=$(printf "%s" "$DESTS" | sed -n 's/.*platform:iOS[^}]*id:\([A-F0-9-]*\).*/\1/p' | head -n1)
if [[ -z "$BUILD_UDID" ]]; then
  warn "Could not determine xcodebuild device UDID from -showdestinations. Falling back to Any iOS Device."
  DEST_OPT="platform=iOS"
else
  DEST_OPT="id=$BUILD_UDID"
fi

# 5) Build for iPhoneOS
say "Building ($SCHEME) for device"
/usr/bin/xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "$DEST_OPT" \
  -derivedDataPath "$DERIVED" \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  build || true

APP_PATH="$DERIVED/Build/Products/Debug-iphoneos/TorchPatterns.app"
[[ -d "$APP_PATH" ]] || fail "Build did not produce app at $APP_PATH"

# 6) Install and launch
say "Installing app to device"
# Prefer hardware UDID for devicectl device commands
HW_UDID=$(xcrun devicectl device info details --device "$CORE_ID" 2>/dev/null | awk '/• udid:/ {print $3; exit}')
[ -z "$HW_UDID" ] && HW_UDID="$CORE_ID"
xcrun devicectl device install app --device "$HW_UDID" "$APP_PATH"

say "Launching app"
xcrun devicectl device process launch --device "$HW_UDID" "$APP_BUNDLE_ID" --activate || warn "If launch fails, unlock device and trust developer in Settings > General > VPN & Device Management."

say "Done."
