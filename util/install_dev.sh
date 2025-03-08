#!/bin/bash

ADDON_NAME="GroupAchievementMonitor"

FULL_PATH=$(realpath $0)
DIR_PATH=$(dirname $FULL_PATH)
SOURCE_DIRECTORY="$DIR_PATH/../src"

TARGET_ELDER_SCROLLS_DIRECTORY="$HOME/Documents/Elder Scrolls Online/live"
TARGET_ADDON_DIRECTORY="$TARGET_ELDER_SCROLLS_DIRECTORY/AddOns"
TARGET_ADDON_MAIN_DIRECTORY="$TARGET_ELDER_SCROLLS_DIRECTORY/AddOns_main"
TARGET_ADDON_DEV_DIRECTORY="$TARGET_ELDER_SCROLLS_DIRECTORY/AddOns_dev"

MAIN_KEY_FILE="main.txt"
DEV_KEY_FILE="dev.txt"

if [ ! -f "$TARGET_ADDON_DIRECTORY/$MAIN_KEY_FILE" ] && [ ! -f "$TARGET_ADDON_DIRECTORY/$DEV_KEY_FILE" ] ; then
    echo "No key file found to identify the AddOn collection type."
    exit 1
fi
if [ ! -f "$TARGET_ADDON_MAIN_DIRECTORY/$MAIN_KEY_FILE" ] ; then
    echo "No main key file found in $TARGET_ADDON_MAIN_DIRECTORY."
    exit 1
fi
if [ ! -f "$TARGET_ADDON_DEV_DIRECTORY/$DEV_KEY_FILE" ] ; then
    echo "No main key file found in $TARGET_ADDON_DEV_DIRECTORY."
    exit 1
fi

if [ -f "$TARGET_ADDON_DIRECTORY/$MAIN_KEY_FILE" ]; then
    echo "Main AddOns still in use. Creating backup in $TARGET_ADDON_MAIN_DIRECTORY."
    rm -rf "$TARGET_ADDON_MAIN_DIRECTORY"
    cp -a "$TARGET_ADDON_DIRECTORY" "$TARGET_ADDON_MAIN_DIRECTORY"
fi

echo "Copying Group Achievement Monitor AddOn into $TARGET_ADDON_DEV_DIRECTORY."
rm -rf "$TARGET_ADDON_DEV_DIRECTORY/$ADDON_NAME"
cp -a "$SOURCE_DIRECTORY" "$TARGET_ADDON_DEV_DIRECTORY/$ADDON_NAME"

echo "Copying Dev AddOns into $TARGET_ADDON_DIRECTORY."
rm -rf "$TARGET_ADDON_DIRECTORY"
cp -a "$TARGET_ADDON_DEV_DIRECTORY" "$TARGET_ADDON_DIRECTORY"

echo "Dev AddOns installed."
