# Utilities

To make the process of Addon development easier, this directory contains scripts to automatically install and uninstall the current state of development in the live AddOn directory of Elder Scrolls Online.

## Prerequisites

For now the directory structure in `~/Documents/Elder Scrolls Online/live/` needs to follow a certain schema.
Besides the usual `AddOns` you need to create the folders `AddOns_main` which acts as a place for backing up your usual AddOns, and `AddOns_dev` which contains all AddOns for development and debugging as well as this AddOn in its current state.

To track which AddOn setup is active the empty files you need to create the empty files `main.txt` and `dev.txt` in their respective directories. The usual `AddOns` also needs the respective file.

- live
  - AddOns
    - `main.txt` or `dev.txt`, depending on your current setup.
  - AddOns_main
    - Your usual AddOns
    - `main.txt`
  - AddOns_dev
    - `GroupAchievementMonitor`
    - AddOns for development
    - `dev.txt`

## Install

To install the current state of development you can run the following in the terminal from the root folder.

`sudo sh util/install_dev.sh`

## Uninstall

To uninstall the current state of development and reinstall your usual AddOns you can run the following in the terminal from the root folder.

`sudo sh util/uninstall_dev.sh`
