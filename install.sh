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
echo -e "${CYAN} ██████╗ ██╗ █████╗ ██╗ ██╗████████╗"
echo -e " ██╔══██╗██║ ██╔══██╗╚██╗ ██╔╝╚══██╔══╝"
echo -e " ██████╔╝██║ ███████║ ╚████╔╝ ██║ "
echo -e " ██╔══██╗██║ ██╔══██║ ╚██╔╝ ██║ "
echo -e " ██████╔╝███████╗██║ ██║ ██║ ██║ "
echo -e " ╚═════╝ ╚══════╝╚═╝ ╚═╝ ╚═╝ ╚═╝ ${RESET}"
echo ""
echo -e "${CYAN}──────────────────────────────────────────────${RESET}"
echo -e " Blayt Executor Installer v${VERSION}"
echo -e " Installs to: /Applications"
echo -e " GitHub: github.com/${REPO}"
echo -e "${CYAN}──────────────────────────────────────────────${RESET}"
echo ""

# macOS check
if [ "$(uname)" != "Darwin" ]; then
  echo -e "${RED}Error: Blayt Executor is macOS only.${RESET}"
  exit 1
fi

# Use Universal for simplicity (you only uploaded this one)
DMG_FILE="BlaytUniversal.dmg"
DOWNLOAD_URL="${BASE_URL}/${DMG_FILE}"

echo -e "Downloading : ${CYAN}$DMG_FILE${RESET}"
echo ""

# Check sudo
if ! sudo -v 2>/dev/null; then
  echo -e "${RED}Error: This installer requires administrator privileges.${RESET}"
  exit 1
fi

# ─── Download ──────────────────────────────────────────────────────────────
echo "Downloading Blayt Executor..."
HTTP_STATUS=$(curl -L --progress-bar -w "%{http_code}" -o "/tmp/${DMG_FILE}" "$DOWNLOAD_URL")

if [ "$HTTP_STATUS" != "200" ]; then
  echo ""
  echo -e "${RED}Error: Download failed (HTTP $HTTP_STATUS).${RESET}"
  echo -e "Check: https://github.com/${REPO}/releases/tag/${TAG}${RESET}"
  rm -f "/tmp/${DMG_FILE}"
  exit 1
fi

# Verify it's a real DMG, not HTML
FILE_TYPE=$(file -b "/tmp/${DMG_FILE}")
if echo "$FILE_TYPE" | grep -qi "html\|ascii text\|unicode text"; then
  echo ""
  echo -e "${RED}Error: Downloaded HTML instead of DMG (404 page).${RESET}"
  rm -f "/tmp/${DMG_FILE}"
  exit 1
fi

# ─── Mount ─────────────────────────────────────────────────────────────────
echo ""
echo "Mounting DMG..."
MOUNT_DIR=$(hdiutil attach "/tmp/${DMG_FILE}" -nobrowse -noautoopen -quiet | tail -1 | awk -F'\t' '{print $NF}')

if [ -z "$MOUNT_DIR" ] || [ ! -d "$MOUNT_DIR" ]; then
  echo -e "${RED}Error: Failed to mount DMG.${RESET}"
  exit 1
fi

# ─── Install ───────────────────────────────────────────────────────────────
echo "Removing old version..."
sudo rm -
