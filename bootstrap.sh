#!/usr/bin/env bash
# Surfbots Dev Platform public bootstrap. Download, inspect, then run.
set -euo pipefail

PUBLIC_REPOSITORY="${SURFBOTS_PUBLIC_REPOSITORY:-franknaw/surfbots-code-intelligence}"
DEFAULT_VERSION_URL="https://raw.githubusercontent.com/${PUBLIC_REPOSITORY}/main/VERSION"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/surfbots-dev-platform"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}/surfbots-dev-platform"
INSTALL_ROOT="${SURFBOTS_INSTALL_ROOT:-${DATA_HOME}/platform}"
LOG_DIR="${STATE_HOME}/logs"
LOG_FILE="${LOG_DIR}/bootstrap-$(date +%Y%m%dT%H%M%S).log"

mkdir -p "$DATA_HOME" "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

fail() { printf '[ERROR] %s\nLog: %s\n' "$*" "$LOG_FILE" >&2; exit 1; }
usage() { printf 'Usage: %s [--version vX.Y.Z] [--profile local-lightweight|local-quality]\n' "$0"; }

VERSION=""
PROFILE="${SURFBOTS_INFERENCE_PROFILE:-}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="${2:-}"; shift 2 ;;
    --profile) PROFILE="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Unknown argument: $1" ;;
  esac
done
command -v curl >/dev/null 2>&1 || fail "curl is required to download a verified release."
command -v sha256sum >/dev/null 2>&1 || fail "sha256sum is required for mandatory archive verification."
command -v tar >/dev/null 2>&1 || fail "tar is required to extract the verified release."

if [[ -z "$VERSION" ]]; then
  VERSION="$(curl -fsSL "$DEFAULT_VERSION_URL")" || fail "Could not download current release version."
fi
[[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Invalid requested release version: $VERSION"
case "${PROFILE:-local-lightweight}" in
  local-lightweight|local-quality) ;;
  *) fail "Unsupported inference profile: ${PROFILE}" ;;
esac
RELEASE_TAG="${SURFBOTS_RELEASE_TAG:-${VERSION}-local-bootstrap}"
ARCHIVE="surfbots-dev-platform-${VERSION}.tar.gz"
CHECKSUM="surfbots-dev-platform-${VERSION}.sha256"
RELEASE_URL="https://github.com/${PUBLIC_REPOSITORY}/releases/download/${RELEASE_TAG}"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

curl -fsSL "$RELEASE_URL/$ARCHIVE" -o "$TEMP_DIR/$ARCHIVE" || fail "Could not download release archive $RELEASE_TAG."
curl -fsSL "$RELEASE_URL/$CHECKSUM" -o "$TEMP_DIR/$CHECKSUM" || fail "Could not download release checksum $RELEASE_TAG."
(
  cd "$TEMP_DIR"
  sha256sum --check "$CHECKSUM"
) || fail "Checksum verification failed; the archive was not extracted."

EXTRACTED="$TEMP_DIR/surfbots-dev-platform-${VERSION}"
tar -xzf "$TEMP_DIR/$ARCHIVE" -C "$TEMP_DIR" || fail "Could not extract verified archive."
[[ -x "$EXTRACTED/scripts/install-runtime.sh" ]] || fail "Verified archive does not contain the runtime installer."

rm -rf "$INSTALL_ROOT.new"
mkdir -p "$(dirname "$INSTALL_ROOT")"
cp -a "$EXTRACTED" "$INSTALL_ROOT.new"
rm -rf "$INSTALL_ROOT"
mv "$INSTALL_ROOT.new" "$INSTALL_ROOT"
exec "$INSTALL_ROOT/scripts/install-runtime.sh" --profile "${PROFILE:-local-lightweight}"
