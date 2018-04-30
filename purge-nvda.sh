#!/bin/sh

# purge-nvda.sh
# Author(s): Mayank Kumar (mayankk2308, github.com / mac_editor, egpu.io)
# License: Specified in LICENSE.md.
# Version: 2.0.0

# Re-written for scalability and better user interaction.

# ----- COMMAND LINE ARGS

# Setup command args
SCRIPT="$BASH_SOURCE"
OPTION=""

if [[ "$0" == "sh" ]]
then
  OPTION="$2"
else
  OPTION="$1"
fi

# ----- ENVIRONMENT

# Enable case-insensitive comparisons
shopt -s nocasematch

# Script binary
SCRIPT_BIN="/usr/local/bin/purge-nvda"

# Script version
SCRIPT_VER="2.0.0"

# User input
INPUT=""

# Text management
BOLD=`tput bold`
NORMAL=`tput sgr0`

# Errors
SIP_ON_ERR=1
MACOS_VER_ERR=2
NO_NV_DG_ERR=3

# Arg-Function Map
p=1
s=2
n=3
c=4
u=5
h=6
v=7
b=8
y=9
r=10
q=11

# Input-Function map
IF["$p"]="purge_nv"
IF["$s"]="suppress_nv"
IF["$n"]="update_nvram"
IF["$c"]="check_system_status"
IF["$u"]="uninstall"
IF["$h"]="usage"
IF["$v"]="show_script_version"
IF["$b"]="disable_hibernation"
IF["$y"]="enable_hibernation"
IF["$r"]="initiate_reboot"
IF["$q"]="quit"

# System information
MACOS_VER=`sw_vers -productVersion`
MACOS_BUILD=`sw_vers -buildVersion`

# Kext Paths
SYS_KEXTS="/System/Library/Extensions/"
GEF_KEXTS="${SYS_KEXTS}GeForce"

# Backup Locations
BACKUP_DIR="/Library/Application Support/Purge-NVDA/"

# NVRAM IG+DG Variables
NV_GUID="fa4ce28d-b62f-4c99-9cc3-6815686e30f9"
IG_POWER_PREF="%01%00%00%00"
DG_POWER_PREF="%00%00%00%00"
IG_BOOT_ARG="nv_disable=1"

# Patch status
IG_PATCH_STATUS=""
NV_PATCH_STATUS=""

# ----- SYSTEM CONFIGURATION MANAGER

# Elevate privileges
elevate_privileges()
{
  if [[ `id -u` != 0 ]]
  then
    echo
    sudo "$SCRIPT" "$OPTION"
    exit 0
  fi
}

# System integrity protection check
check_sip()
{
  if [[ `csrutil status | grep -i enabled` ]]
  then
    echo "System Integrity Protection needs to be disabled before proceeding.\n"
    exit $SIP_ON_ERR
  fi
}

# macOS Version check
check_macos_version()
{
  MACOS_MAJOR_VER=`echo $MACOS_VER | cut -d '.' -f2`
  MACOS_MINOR_VER=`echo $MACOS_VER | cut -d '.' -f3`
  if [[ ("$MACOS_MAJOR_VER" < 13) || ("$MACOS_MAJOR_VER" == 13 && "$MACOS_MINOR_VER" < 4) ]]
  then
    echo "\nThis script requires ${BOLD}macOS 10.13.4${NORMAL} or later.\n"
    exit $MACOS_VER_ERR
  fi
}

# Check for discrete NVIDIA GPU
find_nv_dg()
{
  GPU_DATA=`SafeEjectGPU gpus | sed 1,1d`
  while IFS= read -r GPU_NAME && read -r GPU_TYPE
  do
    if [[ "$GPU_NAME" =~ "NVIDIA" && "$GPU_TYPE" =~ "discrete" ]]
    then
      return 0
    fi
  done <<< "$GPU_DATA"
  echo "\nThis mac does not contain a ${BOLD}discrete NVIDIA GPU${NORMAL}. Patch not needed.\n"
  exit "$NO_NV_DG_ERR"
}

# Check patch status
check_patch()
{
  if [[ `nvram boot-args | grep -i nv_disable=1` ]]
  then
    NV_PATCH_STATUS=1
  else
    NV_PATCH_STATUS=0
  fi
  if [[ `nvram "${NV_GUID}:gpu-power-prefs" | grep -i "${IG_POWER_PREF}"` ]]
  then
    IG_PATCH_STATUS=1
  else
    IG_PATCH_STATUS=0
  fi
}

# Print patch status
check_system_status()
{
  echo "\n>> ${BOLD}System Status${NORMAL}\n"
  if [[ "$NV_PATCH_STATUS" == 0 ]]
  then
    echo "${BOLD}NVIDIA Purge${NORMAL}: Not Detected"
  else
    echo "${BOLD}NVIDIA NVRAM Purge${NORMAL}: Detected"
  fi
  if [[ "$IG_PATCH_STATUS" == 0 ]]
  then
    echo "${BOLD}IGPU Forced${NORMAL}: Not Detected\n"
  else
    echo "${BOLD}IGPU Forced${NORMAL}: Detected\n"
  fi
}

# Cumulative system check
perform_sys_check()
{
  check_sip
  check_macos_version
  find_nv_dg
  elevate_privileges
  check_patch
}

# ----- OS MANAGEMENT

# Reboot sequence/message
prompt_reboot()
{
  echo "${BOLD}System ready.${NORMAL} Restart now to apply changes.\n"
}

# Reboot sequence
initiate_reboot()
{
  echo
  for time in {5..0}
  do
    printf "Restarting in ${BOLD}${time}s${NORMAL}...\r"
    sleep 1
  done
  reboot
}

# Disable hibernation
disable_hibernation()
{
  echo "\n>> ${BOLD}Disable Hibernation${NORMAL}\n"
  echo "${BOLD}Disabling hibernation...${NORMAL}"
  pmset -a autopoweroff 0
  pmset -a standby 0
  pmset -a hibernatemode 0
  echo "Hibernation disabled.\n"
}

# Revert hibernation settings
enable_hibernation()
{
  echo "\n>> ${BOLD}Enable Hibernation${NORMAL}\n"
  echo "${BOLD}Enabling hibernation...${NORMAL}"
  pmset -a autopoweroff 1
  pmset -a standby 1
  pmset -a hibernatemode 3
  echo "Hibernation enabled.\n"
}

# Rebuild kernel cache
invoke_kext_caching()
{
  echo "${BOLD}Rebuilding kext cache...${NORMAL}"
  touch "$SYS_KEXTS"
  kextcache -q -update-volume /
  echo "Rebuild complete."
}

# ----- NVIDIA KEXT MANAGER

# GeForce Kext removal/shift
move_nvda_drv()
{
  mkdir -p "$BACKUP_DIR"
  if [[ "$(ls /System/Library/Extensions/ | grep GeForce)" ]]
  then
    echo "${BOLD}Moving NVIDIA GeForce drivers...${NORMAL}"
    if [[ "$(ls "$BACKUP_DIR")" ]]
    then
      rm -r "$BACKUP_DIR"*
    fi
    mv "$GEF_KEXTS"*.* "$BACKUP_DIR"
    echo "Move complete."
    invoke_kext_caching
  else
    echo "Required kexts already moved. No action taken.\n"
  fi
}

restore_nvda_drv()
{
  if [[ ! -d "${BACKUP_DIR}GeForce.kext" ]]
  then
    return 0
  fi
  echo "${BOLD}Restoring NVIDIA drivers...${NORMAL}"
  rsync -r -u "$BACKUP_DIR"* "$SYS_KEXTS"
  echo "Complete."
}

# ----- NVRAM MANAGER

# iGPU-only NVRAM Update
update_nvram()
{
  echo "\n${BOLD}>> Force Single iGPU Boot${NORMAL}\n"
  echo "${BOLD}Updating NVRAM...${NORMAL}"
  nvram "${NV_GUID}:gpu-power-prefs"="$DG_POWER_PREF"
  echo "Update complete.\n"
}

# Restore NVRAM to previous state
restore_nvram()
{
  echo "${BOLD}Restoring NVRAM...${NORMAL}"
  nvram boot-args=""
  nvram "${NV_GUID}:gpu-power-prefs"="$DG_POWER_PREF"
  echo "Restore complete."
}

# Complete NVRAM kextless NVIDIA purge
purge_nv()
{
  echo "\n${BOLD}>> Enable AMD eGPUs${NORMAL}\n"
  echo "${BOLD}Patching NVRAM...${NORMAL}"
  nvram boot-args="${IG_BOOT_ARG}"
  nvram "${NV_GUID}:gpu-power-prefs"="$IG_POWER_PREF"
  echo "Patch complete.\n"
}

# NVIDIA GPU Suppress-Only
suppress_nv()
{
  echo "\n${BOLD}>> Suppress NVIDIA GPUs${NORMAL}\n"
  echo "${BOLD}Patching NVRAM...${NORMAL}"
  nvram "${NV_GUID}:gpu-power-prefs"="$IG_POWER_PREF"
  move_nvda_drv
  echo "Patch complete.\n"
}

# ----- RECOVERY SYSTEM

uninstall()
{
  echo "\n${BOLD}>> Uninstall${NORMAL}\n"
  echo "${BOLD}Uninstalling...${NORMAL}"
  restore_nvram
  if [[ -d "$BACKUP_DIR" ]]
  then
    restore_nvda_drv
    invoke_kext_caching
    rm -r "$BACKUP_DIR"
  fi
  echo "Uninstallation complete.\n"
}

# ----- BINARY MANAGER

# Bin management procedure
install_bin()
{
  rsync "$SCRIPT_FILE" "$SCRIPT_BIN"
  chown $(whoami):everyone "$SCRIPT_BIN"
  chmod 700 "$SCRIPT_BIN"
  chflags nouchg "$SCRIPT_BIN"
  chmod a+x "$SCRIPT_BIN"
}

# Bin first-time setup
first_time_setup()
{
  if [[ "$SCRIPT" == "$SCRIPT_BIN" || "$SCRIPT" == "purge-nvda" ]]
  then
    return 0
  fi
  PREPEND="$(pwd)/"
  if [[ `echo "$SCRIPT" | grep -i /dev`  ]]
  then
    PREPEND=""
  fi
  SCRIPT_FILE="${PREPEND}$(echo "$SCRIPT")"
  if [[ "$SCRIPT" == "$0" ]]
  then
    SCRIPT_FILE="$(echo "$SCRIPT_FILE" | cut -c 1-)"
  fi
  SCRIPT_SHA=`shasum -a 512 -b "$SCRIPT_FILE" | awk '{ print $1 }'`
  if [[ ! -s "$SCRIPT_BIN" ]]
  then
    echo "\n>> ${BOLD}System Management${NORMAL}\n"
    echo "${BOLD}Creating binary...${NORMAL}"
    install_bin
    echo "Binary installed. ${BOLD}'purge-nvda'${NORMAL} command now available. ${BOLD}Proceeding...${NORMAL}"
    sleep 2
    return 0
  fi
  BIN_SHA=`shasum -a 512 -b "$SCRIPT_BIN" | awk '{ print $1 }'`
  if [[ "$BIN_SHA" != "$SCRIPT_SHA" ]]
  then
    echo "\n>> ${BOLD}System Management${NORMAL}\n"
    echo "${BOLD}Updating binary...${NORMAL}"
    rm "$SCRIPT_BIN"
    install_bin
    echo "Binary updated. ${BOLD}Proceeding...${NORMAL}"
    sleep 2
  fi
}

# ----- USER INTERFACE

# Exit script
quit()
{
  echo "\n${BOLD}Later then${NORMAL}. Buh bye!\n"
  exit 0
}

# Print script version
show_script_version()
{
  echo "\nScript at ${BOLD}${SCRIPT_VER}${NORMAL}.\n"
}

# Print command line options
usage()
{
  echo "\n>> ${BOLD}Command Line Shortcuts${NORMAL}\n"
  echo " purge-nvda ${BOLD}-[p s n c b y v h r q]${NORMAL}"
  echo "
    ${BOLD}-p${NORMAL}: Enable AMD eGPUs
    ${BOLD}-s${NORMAL}: Suppress NVIDIA GPUs
    ${BOLD}-n${NORMAL}: Force Single iGPU Boot
    ${BOLD}-c${NORMAL}: System Status
    ${BOLD}-u${NORMAL}: Uninstall
    ${BOLD}-h${NORMAL}: Command-Line Shortcuts
    ${BOLD}-v${NORMAL}: Script Version
    ${BOLD}-b${NORMAL}: Disable Hibernation
    ${BOLD}-y${NORMAL}: Enable Hibernation
    ${BOLD}-r${NORMAL}: Reboot
    ${BOLD}-q${NORMAL}: Quit
    "
}

# Input processing
process_input()
{
  ARG="$1"
  if [[ ! $ARG =~ ^[0-9]+$ || $ARG -le 0 || $ARG -ge 12 ]]
  then
    echo "\nInvalid option. Try again."
    provide_menu_selection
    return
  fi
  "${IF[${ARG}]}"
}

# Menu bypass
process_arg_bypass()
{
  if [[ "$OPTION" ]]
  then
    OPTION=`echo $OPTION | head -c 2 | tail -c 1`
    eval OPTION="${!OPTION}"
    process_input "$OPTION"
    exit 0
  fi
}

# Ask for main menu
ask_menu()
{
  read -p "${BOLD}Back to menu?${NORMAL} [Y/N]: " INPUT
  if [[ "$INPUT" == "Y" || "$INPUT" == "y" ]]
  then
    perform_sys_check
    echo "\n>> ${BOLD}PurgeNVDA ($SCRIPT_VER)${NORMAL}"
    provide_menu_selection
  fi
  echo
  exit 0
}

# Menu
provide_menu_selection()
{
  echo "
   ${BOLD}>> Patching System${NORMAL}               ${BOLD}>> System Status & Recovery${NORMAL}
   ${BOLD}1.${NORMAL}  Enable AMD eGPUs             ${BOLD}4.${NORMAL}  System Status
   ${BOLD}2.${NORMAL}  Suppress NVIDIA GPUs         ${BOLD}5.${NORMAL}  Uninstall
   ${BOLD}3.${NORMAL}  Force Single iGPU Boot

   ${BOLD}>> Additional Options${NORMAL}            ${BOLD}>> System Sleep Configuration${NORMAL}
   ${BOLD}6.${NORMAL}  Command-Line Shortcuts       ${BOLD}8.${NORMAL}  Disable Hibernation
   ${BOLD}7.${NORMAL}  Script Version               ${BOLD}9.${NORMAL}  Enable Hibernation

   ${BOLD}10.${NORMAL} Reboot System
   ${BOLD}11.${NORMAL} Quit
  "
  read -p "${BOLD}What next?${NORMAL} [1-11]: " INPUT
  process_input "$INPUT"
  ask_menu
}

# ----- SCRIPT DRIVER

# Primary execution routine
begin()
{
  first_time_setup
  perform_sys_check
  process_arg_bypass
  clear
  echo ">> ${BOLD}PurgeNVDA ($SCRIPT_VER)${NORMAL}"
  provide_menu_selection
}

begin
