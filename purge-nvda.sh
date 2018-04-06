#!/bin/sh
# Script (purge-nvda.sh) by mac_editor @ egpu.io (mayankk2308@gmail.com)
# Version: 1.4.0

# Parameter(s)
operation="$1"

# Backup directory and environment
backup_dir="/Library/Application Support/Purge-NVDA/"
final_message=""

# Check superuser access
check_sudo()
{
  if [[ "$(id -u)" != 0 ]]
  then
    echo "This script requires superuser access. Please run with 'sudo'.\n"
    exit
  fi
}

# Check system integrity protection
check_sys_integrity_protection()
{
  if [[ `csrutil status | grep -i "enabled"` ]]
  then
    echo "
    System Integrity Protection needs to be disabled before proceeding.

    Boot into recovery, launch Terminal and execute: 'csrutil disable'\n"
    exit
  fi
}

# Check macOS version
check_macos_version()
{
  macos_ver=`sw_vers -productVersion`
  if [[ "$macos_ver" == "10.13" ||  "$macos_ver" == "10.13.1" || "$macos_ver" == "10.13.2" || "$macos_ver" == "10.13.3" ]]
  then
    echo "
    This version of macOS will not support external AMD graphics.

    If you wish to only suppress the dGPU - use the 'suppress-only' option.

    Additionally, due to problems with kernel caching, it is recommended to

    run this script in Single User Mode for this version of macOS.\n"
    exit
  fi
}

# Script help
usage()
{
  echo "
  Usage:

    ./purge-nvda.sh [param]

    You can use one of the following parameters:

        No arguments: Suppresses dGPU + supports AMD eGPUs.

        suppress-only: Suppresses dGPU.

        nvram-only: Only updates the NVRAM for iGPU-only mode.

        uninstall: Restores system to pre-purge state.

        help: Displays usage information."
}

# Rebuild kernel cache
invoke_kext_caching()
{
  echo "Rebuilding kext cache..."
  touch /System/Library/Extensions
  kextcache -q -update-volume /
  echo "Complete.\n"
}

# Patch NVRAM
update_nvram()
{
  flag="$1"
  echo "Updating NVRAM..."
  nvram fa4ce28d-b62f-4c99-9cc3-6815686e30f9:gpu-power-prefs=%01%00%00%00
  nvram fa4ce28d-b62f-4c99-9cc3-6815686e30f9:gpu-active=%01%00%00%00
  if [[ "$flag" == "true" ]]
  then
    nvram boot-args="nv_disable=1"
  fi
  final_message="iGPU will be preferred on next boot, and on subsequent boots if dGPU drivers are unavailable.\n"
  echo "Complete.\n"
}

# Unpatch NVRAM
restore_nvram()
{
  echo "Restoring NVRAM..."
  nvram -d fa4ce28d-b62f-4c99-9cc3-6815686e30f9:gpu-power-prefs
  nvram -d fa4ce28d-b62f-4c99-9cc3-6815686e30f9:gpu-active
  nvram boot-args=""
  echo "Complete.\n"
}

# Move NVIDIA drivers to backup directory
move_nvda_drv()
{
  mkdir -p "$backup_dir"
  if [[ "$(ls /System/Library/Extensions/ | grep NVDA)" && "$(ls /System/Library/Extensions/ | grep GeForce)" ]]
  then
    echo "Moving NVIDIA drivers..."
    if [[ "$(ls "$backup_dir")" ]]
    then
      rm -r "$backup_dir"*
    fi
    mv /System/Library/Extensions/NVDA*.kext "$backup_dir"
    mv /System/Library/Extensions/GeForce*.* "$backup_dir"
    echo "Complete.\n"
  else
    echo "Some/all required kexts already moved. No action taken.\n"
    exit
  fi
}

# Restore NVIDIA drivers for macOS use
restore_nvda_drv()
{
  echo "Restoring NVIDIA drivers..."
  rsync -r -u "$backup_dir"* /System/Library/Extensions/
  echo "Complete.\n"
}

# Primary uninstall procedure
uninstall()
{
  restore_nvram
  if [[ -d "$backup_dir" ]]
  then
    restore_nvda_drv
    invoke_kext_caching
    echo "Uninstalling..."
    rm -r "$backup_dir"
    final_message="Uninstallation complete.\n"
  else
    final_message="Kexts were not backed up. NVRAM was restored.\n"
  fi
}

# Reboot sequence
initiate_reboot()
{
  for time in {5..0}
  do
    printf "Restarting in $time s (Recommended)...\r"
    sleep 1
  done
  reboot
}

# Primary purge procedure
proceed_purge()
{
  flag="$1"
  update_nvram "$flag"
  final_message="Your mac will now behave as an iGPU-only device.\n"
  if [[ "$flag" == "false" ]]
  then
    invoke_kext_caching
  fi
}

# Hard checks
check_sudo
check_sys_integrity_protection

# Option management
if [[ "$operation" == "" ]]
then
  check_macos_version
  proceed_purge "true"
elif [[ "$operation" == "suppress-only" ]]
then
  move_nvda_drv
  proceed_purge "false"
elif [[ "$operation" == "nvram-only" ]]
then
  update_nvram
elif [[ "$operation" == "uninstall" ]]
then
  uninstall
elif [[ "$operation" == "help" ]]
then
  usage
  exit
else
  echo "Invalid argument. Use the 'help' option for usage information.\n"
  exit
fi

echo "$final_message"
initiate_reboot
