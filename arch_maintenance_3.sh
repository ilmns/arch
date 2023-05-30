#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root${NC}"
  exit
fi

# Function to check if a command exists
command_exists () {
  type "$1" &> /dev/null ;
}

# Function to check if necessary packages are installed
check_packages() {
  local packages=( "pv" "lynis" "procps-ng" "inetutils" "pciutils" )
  for package in "${packages[@]}"
  do
    if ! command_exists $package ; then
      echo -e "${YELLOW}$package is not installed, installing...${NC}"
      pacman -S --noconfirm $package
    fi
  done
}

display_menu() {
  echo -e "${GREEN}======================================="
  echo " Arch Linux Audit Script"
  echo -e "=======================================${NC}"
  echo "1. System Update Check"
  echo "2. Check for Outdated Packages"
  echo "3. List Installed Packages"
  echo "4. Check Disk Usage"
  echo "5. Check Grub and Booting"
  echo "6. Audit System Logs"
  echo "7. Audit Users and Groups"
  echo "8. Audit Network Configuration"
  echo "9. Check System Services"
  echo "10. Audit System Hardware"
  echo "11. Audit System Security with Lynis"
  echo "12. System Performance Check"
  echo "13. Filesystem Check and Repair"
  echo "14. Check for Broken Symlinks"
  echo "15. System Cleanup"
  echo "16. Check System Load Average"
  echo "17. Get Computer Specs"
  echo "18. Audit Swap Configuration"
  echo "19. Exit"
  echo -e "${GREEN}=======================================${NC}"
}

# Ensure necessary packages are installed before continuing
check_packages

while true; do
  display_menu
  read -p "Enter the action you want to perform: " action
  case $action in
    1) pacman -Syu | pv -l ;;  # Use pipe viewer to simulate progress bar
    2) checkupdates | pv -l ;;
    3) pacman -Q | pv -l ;;
    4) df -h ;;
    5) grub-mkconfig -o /boot/grub/grub.cfg; systemd-analyze; systemd-analyze blame ;;
    6) journalctl -p 3 -xb ;;
    7) awk -F':' '{ print $1}' /etc/passwd; awk -F':' '{ print $1}' /etc/group ;;
    8) ip addr ;;
    9) systemctl --failed ;;
    10) lscpu; free -h; lsblk ;;
    11) lynis audit system ;;
    12) top ;;
    13) echo "Running fsck, this might take a while..."; touch /forcefsck; reboot ;;
    14) find / -type l -! -exec test -e {} \; -print | pv -l ;; 
    15) paccache -r; journalctl --vacuum-time=3d ;;
    16) uptime ;;
    17) echo "CPU Information:"; lscpu; echo "GPU Information:"; lspci | grep VGA; echo "RAM Information:"; free -h ;;
    18) echo "Swap Summary:"; free -h | grep Swap; echo "Swap Areas:"; swapon -s; echo "Current Swappiness Value:"; cat /proc/sys/vm/swappiness;
      swap_space=`swapon -s | awk '(NR>1) {print $3}'`
      if [[ -z $swap_space ]]; then
        echo -e "${RED}No active swap space found.${NC}"
        read -p "Would you like to utilize swap space? (y/n): " choice
        case $choice in
          y|Y) echo "Creating new swap space..."; 
            read -p "Enter the size for the new swap space (e.g., 1G): " swap_size
            fallocate -l $swap_size /swapfile
            chmod 600 /swapfile
            mkswap /swapfile
            swapon /swapfile
            echo "/swapfile none swap defaults 0 0" >> /etc/fstab
            echo "Setting swappiness to 80."; sysctl vm.swappiness=80
            echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
            ;;
          n|N) echo "Keeping current configuration." ;;
          *) echo "Invalid choice." ;;
        esac
      else
        echo -e "${GREEN}Active swap space found.${NC}"
      fi ;;
    19) echo -e "${GREEN}Exiting the script.${NC}"; exit 0 ;;
    *) echo -e "${RED}Invalid option, please try again.${NC}" ;;
  esac
  read -p "Press [Enter] key to continue..." fackEnterKey
done

