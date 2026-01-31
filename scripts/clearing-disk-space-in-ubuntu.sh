#!/bin/bash
# Run:.
# chmod +x clearing-disk-space-in-ubuntu.sh
# sudo ./clearing-disk-space-in-ubuntu.sh

# Clearing Disk Space in Ubuntu
# Script version: 1.0
# DevDotNet.ORG <anton@devdotnet.org> MIT License

set -e #Exit immediately if a comman returns a non-zero status

# **************** definition of variables ****************
declare ARCH_OS=$(uname -m) #aarch64, armv7l, x86_64 or riscv64

echo "Let's start cleaning the Ubuntu system..."

# Save free space before cleaning (in megabytes)
FREE_BEFORE=$(df / | awk 'NR==2 {print $4}')
FREE_BEFORE_MB=$((FREE_BEFORE / 1024))

# Removing Old Linux Kernels
echo "1. Removing Old Linux Kernels..."
sudo apt-get purge -y $(dpkg -l 'linux-*' | sed '/^ii/!d;/'"$(uname -r | sed "s/\(.*\)-\([^0-9]\+\)/\1/")"'/d;s/^[^ ]* [^ ]* \([^ ]*\).*/\1/;/[0-9]/!d' | head -n -1)

# Removing unused old versions of packages
echo "2. Removing unused old versions of packages..."
dpkg -l | awk '/^rc/ {print $2}' | xargs sudo dpkg --purge &>/dev/null || echo "No packages to remove"

# Remove unused packages and clear the package cache
echo "3. Remove unused packages and clear the package cache..."
sudo apt --purge autoremove -y \
&& sudo apt clean && sudo apt autoclean -y \
&& sudo rm -rf /var/lib/{cache,log}/ \
&& sudo rm -rf /tmp/* /var/tmp/* \
&& sudo rm -rf /var/cache/fontconfig/ \
&& sudo rm -rf /var/cache/apt/ \
&& sudo rm -rf /var/cache/man/

# Updating the GRUB bootloader
echo "4. Updating the GRUB/U-BOOT bootloader..."
# Select
case $ARCH_OS in

  aarch64)
    sudo apt autoremove -y && sudo update-initramfs -u -k all
    ;;

  armv7l)
    sudo apt autoremove -y && sudo update-initramfs -u -k all
    ;;

  x86_64)
    sudo apt autoremove -y && sudo update-grub && sudo update-grub2
    ;;

  riscv64)
    echo "There is no option for RISC-V (riscv64)"
    ;; 

  *)
    echo "No option"
    ;;
esac

# Clearing system logs and deleting logs
echo "5. Clearing system logs and deleting logs..."
sudo journalctl --vacuum-time=3d
sudo journalctl --vacuum-size=10M
find /var/log/ -name "*.*" -type f -exec sudo rm -f {} \;
find /var/log/ -name "*" -type f -exec sudo rm -f {} \;
sudo systemctl restart rsyslog &>/dev/null || echo "No need to restart rsyslog service"

# Removing Old Snap Applications
echo "6. Removing Old Snap Applications..."
if command -v snap >/dev/null 2>&1; then
    echo "Snap is installed on the system."
    snap list --all | awk '/disabled/{print $1, $3}' |
    while read snapname revision; do
        echo "Removing a snap: '$snapname' , revision: '$revision'"
        sudo snap remove "$snapname" --revision="$revision"
    done
else
    echo "Snap is NOT installed on the system."
fi

# Saving free space after cleaning
FREE_AFTER=$(df / | awk 'NR==2 {print $4}')
FREE_AFTER_MB=$((FREE_AFTER / 1024))

# Difference
FREED_MB=$((FREE_AFTER_MB - FREE_BEFORE_MB))

# Completed
echo "-------------------------------------"
echo "Cleanup completed on '$(hostname)'"
echo "Date $(date '+%d-%m-%Y %H:%M')"
echo "Freed: ${FREED_MB} MB"
echo "-------------------------------------"

# exit
exit 0
