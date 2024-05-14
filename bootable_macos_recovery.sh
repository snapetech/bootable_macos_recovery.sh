#!/bin/bash

# Ensure required dependencies are installed
sudo dnf update -y
sudo dnf install -y python3 python3-pip git hfsplus-tools dmg2img p7zip

# Check if the installer DMG file is present
if [[ ! -f "InstallMacOSX.dmg" ]]; then
  echo "Error: macOS installer DMG file not found. Exiting."
  exit 1
fi

# Convert the dmg to an iso file
dmg2img -i InstallMacOSX.dmg -o macos_installer.iso

# Check if the ISO file was created
if [[ ! -f "macos_installer.iso" ]]; then
  echo "Error: Failed to create macOS installer ISO file. Exiting."
  exit 1
fi

# Extract the ISO file
mkdir macos_installer_extracted
7z x macos_installer.iso -omacos_installer_extracted

# Verify the extracted directory
if [[ ! -d "macos_installer_extracted/System/Library/CoreServices" ]]; then
  echo "Error: macOS installer files not found in the extracted directory. Exiting."
  exit 1
fi

# Identify the USB drive (replace /dev/sdX with the actual device)
USB_DRIVE="/dev/sdX"

# Unmount the USB drive if it is already mounted
sudo umount ${USB_DRIVE}*

# Create a new partition table on the USB drive
sudo parted ${USB_DRIVE} mklabel gpt

# Create a single partition and format it as HFS+
sudo parted -s ${USB_DRIVE} mkpart primary hfs+ 0% 100%
sudo mkfs.hfsplus -v "macOSInstaller" ${USB_DRIVE}1

# Mount the USB drive
sudo mkdir -p /mnt/usb_drive
sudo mount ${USB_DRIVE}1 /mnt/usb_drive

# Copy the macOS installer files to the USB drive
sudo rsync -avh macos_installer_extracted/ /mnt/usb_drive/

# Unmount the USB drive
sudo umount /mnt/usb_drive

echo "Bootable macOS USB drive created successfully!"
