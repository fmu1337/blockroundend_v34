#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
WORK="$ROOT/dist/work"
SP_SRC="$ROOT/addons/sourcemod/scripting/noroundend.sp"
GD="$ROOT/addons/sourcemod/gamedata/noroundend.games.txt"
SP="$WORK/noroundend.sp"

rm -rf "$DIST"
mkdir -p "$WORK" "$DIST"

# 32-bit spcomp (SM 1.4.2)
sudo dpkg --add-architecture i386 >/dev/null 2>&1 || true
sudo apt-get update -qq >/dev/null 2>&1 || true
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq lib32stdc++6 lib32z1 unzip >/dev/null 2>&1 || true

resolve_version() {
  if [[ "${GITHUB_REF:-}" =~ refs/tags/v?([0-9]+\.[0-9]+\.[0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
    return
  fi

  local subj
  subj="$(git -C "$ROOT" log -1 --pretty=%s 2>/dev/null || true)"
  if [[ "$subj" =~ (^|[^0-9])v?([0-9]+\.[0-9]+\.[0-9]+)([^0-9]|$) ]]; then
    echo "${BASH_REMATCH[2]}"
    return
  fi

  local fallback
  fallback="$(grep -oE '#define PLUGIN_VERSION "[^"]+"' "$SP_SRC" | head -1 | cut -d'"' -f2 || true)"
  if [[ -n "$fallback" && "$fallback" != "0.0.0-dev" ]]; then
    echo "$fallback"
    return
  fi

  echo "0.0.0-dev"
}

VERSION="$(resolve_version)"
echo "Plugin version: $VERSION"

sed -E "s/#define PLUGIN_VERSION \".*\"/#define PLUGIN_VERSION \"$VERSION\"/" \
  "$SP_SRC" > "$SP"

# One build with oldest compatible compiler (SM 1.4.2) — runs on 1.4 … 1.13
echo "==> SM 1.4.2 (spcomp)"
COMP142="$ROOT/tools/compilers/sm1.4.2-linux"
chmod +x "$COMP142/spcomp"
"$COMP142/spcomp" "$SP" -i"$COMP142/include" -o"$WORK/noroundend.smx"

STAGE="$WORK/pack"
ZIPNAME="noroundend-${VERSION}.zip"
rm -rf "$STAGE"
mkdir -p "$STAGE/addons/sourcemod/plugins" "$STAGE/addons/sourcemod/gamedata"
cp "$WORK/noroundend.smx" "$STAGE/addons/sourcemod/plugins/noroundend.smx"
cp "$GD" "$STAGE/addons/sourcemod/gamedata/noroundend.games.txt"
cp "$ROOT/README.md" "$STAGE/README.md"

(
  cd "$STAGE"
  zip -r "$DIST/$ZIPNAME" README.md addons
)

echo "OK: $DIST/$ZIPNAME"
ls -la "$DIST/$ZIPNAME"
