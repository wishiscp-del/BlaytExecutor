#!/bin/bash
clear
set -e

REPO="wishiscp-del/BlaytExecutor"
TAG="v1.0.0"
BASE_URL="https://github.com/${REPO}/releases/download/${TAG}"
VERSION="1.0.0"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -e "${CYAN}Blayt Executor Installer v${VERSION}${RESET}"
echo ""

DMG_FILE="BlaytUniversal.dmg"
DOWNLOAD_URL="${BASE_URL}/${DMG_FILE}"

if ! sudo -v 2>/dev/null; then
  echo -e "${RED}Error: Run with sudo${RESET}"
  exit 1
fi

echo "Downloading..."
HTTP_STATUS=$(curl -L --progress-bar -w "%{http_code}" -o "/tmp/${DMG_FILE}" "$DOWNLOAD_URL")

if [ "$HTTP_STATUS" != "200" ]; then
  echo -e "${RED}Download failed (HTTP $HTTP_STATUS)${RESET}"
  exit 1
fi

echo "Downloaded file info:"
ls -lh "/tmp/${DMG_FILE}"
file "/tmp/${DMG_FILE}"

# Check if it's really a DMG
if ! file "/tmp/${DMG_FILE}" | grep -qi "dmg\|disk image"; then
  echo -e "${RED}Error: File is not a valid DMG!${RESET}"
  echo "It might be an HTML error page. Check the release assets."
  exit 1
fi

echo ""
echo "Mounting DMG..."
MOUNT_DIR=$(hdiutil attach "/tmp/${DMG_FILE}" -nobrowse -noautoopen -quiet | tail -1 | awk -F'\t' '{print $NF}')

if [ -z "$MOUNT_DIR" ] || [ ! -d "$MOUNT_DIR" ]; then
  echo -e "${RED}Failed to mount DMG.${RESET}"
  echo "Trying to force mount with more info..."
  hdiutil attach "/tmp/${DMG_FILE}" -nobrowse -noautoopen -verbose
  exit 1
fi

echo "Mounted at: $MOUNT_DIR"
ls "$MOUNT_DIR"

echo "Installing..."
sudo rm -rf /Applications/Blayt.app
sudo cp -R "$MOUNT_DIR"/*.app /Applications/

sudo xattr -rd com.apple.quarantine /Applications/Blayt.app 2>/dev/null || true

hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null
rm -f "/tmp/${DMG_FILE}"

echo -e "${GREEN}✅ Installation finished successfully!${RESET}"
