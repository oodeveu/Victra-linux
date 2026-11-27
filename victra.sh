#!/usr/bin/env bash
# run.sh: build and launch Vice-Tay on Linux via GE-Proton (Wine + vkd3d-proton).
#
# Usage:
#   ./run.sh                     build (if needed) and start the game
#   ./run.sh --no-build          start without building
#   ./run.sh build               build only
#   ./run.sh victory <args...>   run victory.exe with arbitrary arguments,
#                                e.g. ./run.sh victory warm --used
#   ./run.sh --check             only verify the configured paths
#   ./run.sh --series-x          use the Series X profile instead of Series S
#
# Required configuration (environment variables, no defaults):
#   VICTORY_REPO       path to the Vice-Tay checkout
#                      e.g. /path/to/Vice-Tay
#   VICTORY_GAME_ROOT  working directory for the game, prefix and caches
#                      e.g. /path/to/game
#   PROTON_DIR         path to a GE-Proton directory (contains the "proton" script)
#                      e.g. ~/.local/share/Steam/compatibilitytools.d/GE-Proton-X
#
# Optional configuration:
#   VICTORY_STAGE         directory holding game_scarlett_master.exe
#                         (default: $VICTORY_GAME_ROOT/victory-win)
#   VICTORY_PREFIX        Wine prefix (default: $VICTORY_GAME_ROOT/victory-prefix)
#   VICTORY_COMPILER_DLL  native d3dcompiler_47.dll (copied next to victory.exe)
#   STEAM_DIR             Steam install dir (default: ~/.local/share/Steam)
#   VICTORY_BUILD         cargo profile: diag (default) or release
#   VICTORY_CONSOLE       series-s (default) or series-x
#   VICTORY_EXTRA         extra settings, e.g. "VICTORY_MAP_THREADS=4 VICTORY_THIN=0"
#   VICTORY_LAUNCH        "wine" runs via runinprefix so stdout reaches the terminal
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
REPO="${VICTORY_REPO:-}"
GAME_ROOT="${VICTORY_GAME_ROOT:-}"
PROTON_DIR="${PROTON_DIR:-}"
STEAM_DIR="${STEAM_DIR:-$HOME/.local/share/Steam}"
PROFILE="${VICTORY_BUILD:-diag}"
CONSOLE="${VICTORY_CONSOLE:-series-s}"
TARGET=x86_64-pc-windows-gnu

mode=play no_build=0 check=0
victory_args=()
while (($#)); do
    case "$1" in
        --no-build) no_build=1 ;;
        --check)    check=1 ;;
        --series-x) CONSOLE=series-x ;;
        build)      mode=build ;;
        victory)    mode=victory; shift; victory_args=("$@"); break ;;
        -h|--help)  sed -n '2,29p' "$0"; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done

# Fail early with a clear message when a required setting is empty.
require() {
    local name="$1" value="$2" example="$3"
    if [[ -z "$value" ]]; then
        echo "$name is not set. Example: $name=$example" >&2
        exit 1
    fi
}
require VICTORY_REPO      "$REPO"       "/path/to/Vice-Tay"
require VICTORY_GAME_ROOT "$GAME_ROOT"  "/path/to/game"
require PROTON_DIR        "$PROTON_DIR" "/path/to/GE-Proton"

STAGE="${VICTORY_STAGE:-$GAME_ROOT/victory-win}"
PREFIX="${VICTORY_PREFIX:-$GAME_ROOT/victory-prefix}"
COMPILER_DLL="${VICTORY_COMPILER_DLL:-}"
CACHE_HOST="$GAME_ROOT/victory-cache"
DATA_HOST="$GAME_ROOT/victory-data"
SHADER_CACHE="$GAME_ROOT/vkd3d-cache"

EXE="$STAGE/game_scarlett_master.exe"
VICTORY_EXE="$REPO/target/$TARGET/$PROFILE/victory.exe"

# Convert a Linux path to a Windows path as seen by Wine (Z: maps to /).
winpath() { printf 'Z:%s' "${1//\//\\}"; }

# ---------------------------------------------------------------------------
# Sanity checks
# ---------------------------------------------------------------------------
[[ -f "$REPO/Cargo.toml" ]]   || { echo "Cargo.toml not found in $REPO" >&2; exit 1; }
[[ -x "$PROTON_DIR/proton" ]] || { echo "No proton script in $PROTON_DIR" >&2; exit 1; }
if [[ "$mode" == play && ! -f "$EXE" ]]; then
    echo "Game executable not found: $EXE" >&2
    echo "Set VICTORY_STAGE to the directory containing game_scarlett_master.exe." >&2
    exit 1
fi
if (( check )); then
    echo "Repo:   $REPO"
    echo "Game:   $EXE"
    echo "Proton: $PROTON_DIR"
    echo "Prefix: $PREFIX"
    echo "OK"
    exit 0
fi

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
if [[ "$mode" == build ]] || { (( ! no_build )) && [[ "$mode" != victory || ! -f "$VICTORY_EXE" ]]; }; then
    [[ -f "$REPO/victory.toml" ]] || cp "$REPO/victory.example.toml" "$REPO/victory.toml"
    cd "$REPO"
    # The toolchain version is pinned in rust-toolchain.toml; the target must be
    # added to that toolchain, so run this from inside the repo.
    rustup target add "$TARGET"
    echo "[BUILD] victory.exe ($PROFILE, $TARGET)"
    cargo build --locked --profile "$PROFILE" -p victory --features diagnostics --target "$TARGET"
    if [[ "$mode" == build ]]; then
        echo "Done: $VICTORY_EXE"
        exit 0
    fi
fi
[[ -f "$VICTORY_EXE" ]] || { echo "Not found: $VICTORY_EXE" >&2; exit 1; }

# Wine's built-in d3dcompiler can reject helper shaders; use a native DLL if provided.
if [[ -n "$COMPILER_DLL" && -f "$COMPILER_DLL" ]]; then
    cp -f "$COMPILER_DLL" "$(dirname "$VICTORY_EXE")/d3dcompiler_47.dll"
else
    echo "Note: no native d3dcompiler_47.dll (set VICTORY_COMPILER_DLL); Wine may reject helper shaders." >&2
fi

# ---------------------------------------------------------------------------
# Environment
# ---------------------------------------------------------------------------
mkdir -p "$PREFIX" "$CACHE_HOST" "$DATA_HOST" "$SHADER_CACHE"

export VICTORY_GAME_DIR="$(winpath "$STAGE")"
export VICTORY_CACHE_DIR="$(winpath "$CACHE_HOST")"
export VICTORY_DATA_DIR="$(winpath "$DATA_HOST")"

export STEAM_COMPAT_DATA_PATH="$PREFIX"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_DIR"
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:+${WINEDLLOVERRIDES};}d3dcompiler_47=n"

# Logging is quiet by default: thousands of lines per second slow the game down.
# For diagnostics:
#   WINEDEBUG=err+all VICTORY_LOG=info ./run.sh --no-build
export WINEDEBUG="${WINEDEBUG:--all}"
export VKD3D_DEBUG="${VKD3D_DEBUG:-none}"
export VICTORY_LOG="${VICTORY_LOG:-warn}"
export VICTORY_LOG_FILE="${VICTORY_LOG_FILE:-$HOME/.local/share/victory.log}"
export VKD3D_SHADER_CACHE_PATH="${VKD3D_SHADER_CACHE_PATH:-$SHADER_CACHE}"

# Pass VKD3D_CONFIG= (empty) to disable descriptor_heap mode, e.g. to debug SIGILL.
export VKD3D_CONFIG="${VKD3D_CONFIG-descriptor_heap}"
[[ -n "$VKD3D_CONFIG" ]] || unset VKD3D_CONFIG
# Disabling VK_NV_raw_access_chains makes copies very slow (~0.2 fps), so make
# sure it is not inherited from the environment.
unset VKD3D_DISABLE_EXTENSIONS

# Worker thread counts scale with the number of CPU cores (minimum 2 each).
n=$(nproc)
thin=$((  n/3 < 2 ? 2 : n/3 ))   # command list translation
under=$(( n/4 < 2 ? 2 : n/4 ))
land=$((  n/5 < 2 ? 2 : n/5 ))   # copy-back work

# VICTORY_* settings, based on the Vice-Tay scripts/play.ps1 defaults.
settings=(
    VICTORY_TEXTURE_NO_WAIT=1 VICTORY_RELAY=2 VICTORY_WIDE_BACK=1
    VICTORY_CARD_REHASH_RUNS=0      # 1 re-uploaded textures repeatedly and left models at low detail
    VICTORY_JOIN_COPIES=1 VICTORY_INDIRECT_WINDOW=1 VICTORY_RELAY_COPY=1
    VICTORY_CARD_STEPS=2 VICTORY_TITLE_PRIORITIES=0
    VICTORY_SHOW_AFTER=1 VICTORY_AMBIENT=0.8 VICTORY_D3D12_DRED=light
    VICTORY_MAP_THREADS=1 VICTORY_CARD_AWAKE=1
    VICTORY_THIN=1 VICTORY_JOIN_PARTS=8 VICTORY_UPLOAD_AHEAD=1
    VICTORY_INDIRECT_BATCH=2
    VICTORY_THIN_THREADS="$thin" VICTORY_UNDER_THREADS="$under" VICTORY_LAND_THREADS="$land"
    VICTORY_LATE_WAIT=0             # Wine/vkd3d shows stale black buffers when presents are sent ahead
    VICTORY_PANEL=1                 # on-screen counters
)
# Extra overrides, e.g.: VICTORY_EXTRA="VICTORY_MAP_THREADS=4 VICTORY_THIN=0" ./run.sh
for kv in "${settings[@]}" ${VICTORY_EXTRA:-}; do export "$kv"; done

launch=("$PROTON_DIR/proton")
if [[ "${VICTORY_LAUNCH:-proton}" == wine ]]; then
    launch+=(runinprefix)   # skips the steam.exe wrapper so stdout reaches the terminal
else
    launch+=(run)
fi

# ---------------------------------------------------------------------------
# Start
# ---------------------------------------------------------------------------
cd "$REPO"

if [[ "$mode" == victory ]]; then
    exec "${launch[@]}" "$VICTORY_EXE" "${victory_args[@]}"
fi

echo "Console: $CONSOLE"
echo "Game:    $(winpath "$EXE")"
echo "Log:     $VICTORY_LOG_FILE"
exec "${launch[@]}" "$VICTORY_EXE" run "$(winpath "$EXE")" --execute --console "$CONSOLE"
