#!/bin/bash

# DISCLAIMER: Use this script responsibly. Always make sure to backup your data before running scripts like this.

# Define function to check if package is installed, and if not, install it
pkg_check_install() {
  if ! pacman -Q | grep -q "^$1 "; then
    echo "Installing $1..."
    pacman -S $1
  fi
}

# Define function to check if file or directory exists
check_exist() {
  if [ ! -e "$1" ]; then
    echo "$1 does not exist. Please double check your input."
    exit 1
  fi
}

# Automate partition checking and mounting
mount_partition() {
  check_exist $1
  mount $1 $2
}

# Prompt for partition information
read -p "Please enter the root partition (e.g., /dev/sda1 or /dev/nvme0n1p1): " root_partition
read -p "Please enter the boot partition (e.g., /dev/sda2 or /dev/nvme0n1p2): " boot_partition

# Mount the partitions
echo "Mounting the partitions..."
mount_partition $root_partition /mnt
mount_partition $boot_partition /mnt/boot

# Mount other necessary filesystems
echo "Mounting other necessary filesystems..."
mount -t proc proc /mnt/proc
mount -t sysfs sys /mnt/sys
mount -o bind /dev /mnt/dev
mount -t devpts pts /mnt/dev/pts

# Check and fix file system errors on root partition
echo "Checking and fixing file system errors on root partition..."
fsck -C -y $root_partition

# chroot into the system
echo "Chroot into the system..."
chroot /mnt

# Sync package databases
echo "Syncing package databases..."
pacman -Syy

# Reinstall all explicitly installed packages
echo "Reinstalling all explicitly installed packages..."
pacman -S --needed $(pacman -Qqe)

# Update system packages
echo "Updating system..."
pacman -Syu

# Check and repair any inconsistencies in the package database
echo "Checking and repairing any inconsistencies in the package database..."
pacman -Dk
pacman -Dkk

# Identify the kernel package name
kernel_package=$(pacman -Q | grep linux | cut -d' ' -f1)

# Reinstall the kernel
echo "Reinstalling the kernel..."
pkg_check_install $kernel_package

# Check if GRUB is installed, if not install it
pkg_check_install grub

# Install GRUB to the right partition
echo "Installing GRUB to the right partition..."
if [[ $root_partition == /dev/nvme* ]]; then
  grub-install --target=x86_64-efi --efi-directory=esp --bootloader-id=GRUB
else
  grub-install --target=i386-pc $root_partition
fi

# Generate GRUB configuration file
grub-mkconfig -o /boot/grub/grub.cfg

# Regenerate initramfs. This is especially useful if the issue is due to a problematic initramfs.
echo "Regenerating initramfs..."
mkinitcpio -P

echo "Done!"
exit
