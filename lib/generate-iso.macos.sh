#!/bin/sh

usage() {
    echo "Usage: $0 <major.minor> [<output-directory>]"
    echo "Example: $0 10.13 isos"
    exit 1
}

if [ -z "$1" ]; then
    usage
fi

VERSION="$1"

case "$VERSION" in
    10.14)
        VERSION_ALIAS='Mojave'
        OS_ALIAS='macOS'
        ;;
    10.13)
        VERSION_ALIAS='High Sierra'
        OS_ALIAS='macOS'
        ;;
    10.12)
        VERSION_ALIAS='Sierra'
        OS_ALIAS='macOS'
        ;;
    10.11)
        VERSION_ALIAS='El Capitan'
        OS_ALIAS='OS X'
        ;;
    10.10)
        VERSION_ALIAS='Yosemite'
        OS_ALIAS='OS X'
        ;;
    10.9)
        VERSION_ALIAS='Mavericks'
        OS_ALIAS='OS X'
        ;;
    10.8)
        VERSION_ALIAS='Mountain Lion'
        OS_ALIAS='OS X'
        ;;
    10.7)
        VERSION_ALIAS='Lion'
        OS_ALIAS='OS X'
        ;;
    *)
        echo 'Unsupported macOS version.'
        exit 1
        ;;
esac

OUTPUT_DIRECTORY="$2"

if [ -z "$2" ]; then
    OUTPUT_DIRECTORY='.'
fi

mkdir -p "$OUTPUT_DIRECTORY"

INSTALLER_APPLICATION_BASE="Install ${OS_ALIAS} ${VERSION_ALIAS}"
INSTALLER_APPLICATION="/Applications/${INSTALLER_APPLICATION_BASE}.app"
BUILD_MOUNT="/Volumes/build-macos-${VERSION}"
IMAGE_DMG="/tmp/macos-${VERSION}.dmg"
IMAGE_CDR="/tmp/macos-${VERSION}.cdr"
IMAGE_ISO="${OUTPUT_DIRECTORY}/macos-${VERSION}.iso"
SHA_FLAVOR=512
CHECKSUM_ALGORITHM="sha${SHA_FLAVOR}"
IMAGE_ISO_CHECKSUM="${IMAGE_ISO}.${CHECKSUM_ALGORITHM}"

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with root privileges."
    exit 1
fi

cleanup() {
    hdiutil detach -force -quiet "$IMAGE_DMG"
    rm -rf "IMAGE_CDR"
    rm -rf "$IMAGE_DMG"
}

trap cleanup EXIT INT TERM

hdiutil create -o "$IMAGE_DMG" \
    -size 6000m \
    -layout SPUD \
    -fs HFS+J

hdiutil attach "$IMAGE_DMG" \
    -mountpoint "$BUILD_MOUNT"

sudo "${INSTALLER_APPLICATION}/Contents/Resources/createinstallmedia" \
    --volume "$BUILD_MOUNT" \
    --applicationpath "$INSTALLER_APPLICATION" \
    --nointeraction

hdiutil detach "/Volumes/${INSTALLER_APPLICATION_BASE}"

hdiutil convert "$IMAGE_DMG" \
    -format UDTO \
    -o "$IMAGE_CDR"

mv "$IMAGE_CDR" "$IMAGE_ISO"

shasum -a "$SHA_FLAVOR" "$IMAGE_ISO" >"$IMAGE_ISO_CHECKSUM"

chown -R "${SUDO_USER}:${SUDO_GID}" "$OUTPUT_DIRECTORY"
