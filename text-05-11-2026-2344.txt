#!/bin/bash
clear
set -e

# ─── Configuration ─────────────────────────────────────────────────────────
REPO="wishiscp-del/BlaytExecutor"
TAG="v1.0.0"
BASE_URL="https://github.com/${REPO}/releases/download/${TAG}"
VERSION="1.0.0"

# ─── Colors ────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# ─── Banner ────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}  ██████╗ ██╗      █████╗ ██╗   ██╗████████╗"
echo -e "  ██╔══██╗██║     ██╔══██╗╚██╗ ██╔╝╚══██╔══╝"
echo -e "  ██████╔╝██║     ███████║ ╚████╔╝    ██║   "
echo -e "  ██╔══██╗██║     ██╔══██║  ╚██╔╝     ██║   "
echo -e "  ██████╔╝███████╗██║  ██║   ██║      ██║   "
echo -e "  ╚═════╝ ╚══════╝╚═╝  ╚═╝   ╚═╝      ╚═╝   ${RESET}"
echo ""
echo -e "${CYAN}──────────────────────────────────────────────${RESET}"
echo -e "   Blayt Executor Installer  v${VERSION}"
echo -e "   Installs to: /Applications"
echo -e "   Requires:    Administrator (sudo)"
echo -e "   GitHub: github.com/${REPO}"
echo -e "${CYAN}──────────────────────────────────────────────${RESET}"
echo ""

# ─── macOS check ───────────────────────────────────────────────────────────
if [ "$(uname)" != "Darwin" ]; then
  echo -e "${RED}Error: Blayt Executor is macOS only.${RESET}"
  exit 1
fi

# ─── macOS version check ───────────────────────────────────────────────────
MAC_VER=$(sw_vers -productVersion)
MAC_MAJOR=$(echo "$MAC_VER" | cut -d. -f1)
if [ "$MAC_MAJOR" -lt 13 ]; then
  echo -e "${YELLOW}Warning: Blayt may not work correctly on macOS $MAC_VER."
  echo -e "         macOS 13 (Ventura) or later is recommended.${RESET}"
  echo ""
fi

# ─── Architecture detection ────────────────────────────────────────────────
ARCH=$(uname -m)

if [ "$ARCH" = "arm64" ]; then
  DMG_FILE="BlaytArm.dmg"
  ARCH_LABEL="Apple Silicon (ARM)"
elif [ "$ARCH" = "x86_64" ]; then
  DMG_FILE="BlaytIntel.dmg"
  ARCH_LABEL="Intel"
else
  DMG_FILE="BlaytUniversal.dmg"
  ARCH_LABEL="Universal (fallback)"
fi

DOWNLOAD_URL="${BASE_URL}/${DMG_FILE}"

echo -e "Detected architecture : ${CYAN}$ARCH ($ARCH_LABEL)${RESET}"
echo -e "Downloading           : ${CYAN}$DMG_FILE${RESET}"
echo ""

# ─── Check sudo access upfront ────────────────────────────────────────────
if ! sudo -v 2>/dev/null; then
  echo -e "${RED}Error: This installer requires administrator privileges."
  echo -e "       Run with sudo, or use userinst.sh for a user-level install.${RESET}"
  exit 1
fi

# ─── Download ──────────────────────────────────────────────────────────────
echo "Downloading Blayt Executor..."
HTTP_STATUS=$(curl -L --progress-bar -w "%{http_code}" -o "/tmp/${DMG_FILE}" "$DOWNLOAD_URL")

if [ "$HTTP_STATUS" != "200" ]; then
  echo ""
  echo -e "${RED}Error: Download failed (HTTP $HTTP_STATUS)."
  echo -e "       The release may not have been published yet."
  echo -e "       Check: https://github.com/${REPO}/releases${RESET}"
  rm -f "/tmp/${DMG_FILE}"
  exit 1
fi

# Verify the downloaded file is not an HTML error page
FILE_TYPE=$(file -b "/tmp/${DMG_FILE}")
if echo "$FILE_TYPE" | grep -qi "html\|ascii text\|utf-8 unicode text"; then
  echo ""
  echo -e "${RED}Error: Download returned an HTML page instead of a DMG."
  echo -e "       The release asset may be missing."
  echo -e "       Check: https://github.com/${REPO}/releases${RESET}"
  rm -f "/tmp/${DMG_FILE}"
  exit 1
fi

# ─── Mount ─────────────────────────────────────────────────────────────────
echo ""
echo "Mounting DMG..."
MOUNT_DIR=$(hdiutil attach "/tmp/${DMG_FILE}" -nobrowse -noautoopen | tail -1 | awk -F'\t' '{print $NF}')

if [ -z "$MOUNT_DIR" ]; then
  echo -e "${RED}Error: Failed to mount DMG.${RESET}"
  exit 1
fi

# ─── Remove old install ────────────────────────────────────────────────────
echo "Removing old Blayt.app (if any)..."
sudo rm -rf /Applications/Blayt.app

# ─── Install ───────────────────────────────────────────────────────────────
echo "Installing Blayt to /Applications..."
sudo cp -R "$MOUNT_DIR"/*.app /Applications/

# ─── Quarantine removal ────────────────────────────────────────────────────
echo "Removing macOS quarantine flag..."
sudo xattr -rd com.apple.quarantine /Applications/Blayt.app 2>/dev/null || true

# ─── Cleanup ───────────────────────────────────────────────────────────────
echo "Cleaning up..."
hdiutil detach "$MOUNT_DIR" -quiet
rm -f "/tmp/${DMG_FILE}"

# ─── Done ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}──────────────────────────────────────────────${RESET}"
echo -e "${GREEN}   Done! Blayt Executor is in /Applications.${RESET}"
echo -e "${GREEN}   Open it from Launchpad or /Applications.${RESET}"
echo -e "${GREEN}──────────────────────────────────────────────${RESET}"
echo ""
