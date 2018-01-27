#!/bin/sh
# Script (purge-nvda.sh) by mac_editor @ egpu.io (mayankk2308@gmail.com)
# Version: 1.2.3

# Usage:
# sudo ./purge-nvda.sh -> moves NVDA kexts to prevent NVDA GPU activation and enables AMD eGPU support
# sudo ./purge-nvda.sh suppress-only -> Same as without arguments sans AMD eGPU support
# sudo ./purge-nvda.sh nvram-restore -> restores NVRAM
# sudo ./purge-nvda.sh nvram-only -> update only NVRAM
# sudo ./purge-nvda.sh uninstall -> restores NVDA kexts, resets NVRAM, and removes backup traces

operation="$1"
backup_dir="/Library/Application Support/Purge-NVDA/"
final_message=""

check_sudo()
{
    if [[ "$(id -u)" != 0 ]]
    then
      echo "This script requires superuser access. Please run with 'sudo'.\n"
      exit
    fi
}

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

usage()
{
    echo "
    Usage:

        ./purge-nvda.sh [param]

    You can use one of the following parameters:

        No arguments: Suppresses dGPU + supports AMD eGPUs.

        suppress-only: Only suppresses dGPU.

        nvram-only: Updates the NVRAM for iGPU-only mode.

        nvram-restore: Restores the NVRAM to how it was before.

        uninstall: Restores system to pre-purge state.

        help: Displays usage information."
}

invoke_kext_caching()
{
    echo "Rebuilding kext cache..."
    touch /System/Library/Extensions
    kextcache -q -update-volume /
    echo "Complete.\n"
}

update_nvram()
{
    echo "Updating NVRAM..."
    nvram fa4ce28d-b62f-4c99-9cc3-6815686e30f9:gpu-power-prefs=%01%00%00%00
    nvram fa4ce28d-b62f-4c99-9cc3-6815686e30f9:gpu-active=%01%00%00%00
    final_message="iGPU will be preferred on next boot, and on subsequent boots if dGPU drivers are unavailable.\n"
    echo "Complete.\n"
}

restore_nvram()
{
    echo "Restoring NVRAM..."
    nvram -d fa4ce28d-b62f-4c99-9cc3-6815686e30f9:gpu-power-prefs
    nvram -d fa4ce28d-b62f-4c99-9cc3-6815686e30f9:gpu-active
    echo "Complete.\n"
}

move_nvda_drv()
{
    flag="$1"
    mkdir -p "$backup_dir"
    if [[ "$(ls /System/Library/Extensions/ | grep NVDA)" && "$(ls /System/Library/Extensions/ | grep GeForce)" ]]
    then
      echo "Moving NVIDIA drivers..."
      if [[ "$(ls "$backup_dir")" ]]
      then
        rm -r "$backup_dir"*
      fi
      if [[ "$flag" == "true" ]]
      then
          mv /System/Library/Extensions/NVDA*.kext "$backup_dir"
      fi
      mv /System/Library/Extensions/GeForce*.* "$backup_dir"
      echo "Complete.\n"
    else
        echo "Some/all required kexts already moved. No action taken.\n"
        exit
    fi
}

restore_nvda_drv()
{
    echo "Restoring NVIDIA drivers..."
    rsync -r -u "$backup_dir"* /System/Library/Extensions/
    echo "Complete.\n"
}

uninstall()
{
    if [[ -d "$backup_dir" ]]
    then
        restore_nvram
        restore_nvda_drv
        invoke_kext_caching
        echo "Uninstalling..."
        rm -r "$backup_dir"
        final_message="Uninstallation complete.\n"
    else
        echo "Could not find valid installation. No action taken.\n"
        exit
    fi
}

initiate_reboot()
{
    for time in {5..0}
    do
        printf "Restarting in $time s | Ctrl + C to cancel...\r"
        sleep 1
    done
    reboot
}

proceed_exec()
{
    update_nvram
    final_message="Your mac will now behave as an iGPU-only device.\n"
    invoke_kext_caching
}

check_sudo
check_sys_integrity_protection
if [[ "$operation" == "" ]]
then
    move_nvda_drv "true"
    proceed_exec
elif [[ "$operation" == "suppress-only" ]]
then
    move_nvda_drv "false"
    proceed_exec
elif [[ "$operation" == "nvram-only" ]]
then
    update_nvram
elif [[ "$operation" == "nvram-restore" ]]
then
    restore_nvram
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
