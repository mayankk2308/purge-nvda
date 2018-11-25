#!/bin/sh

# purge-nvda.sh
# Author(s): Mayank Kumar (mayankk2308, github.com / mac_editor, egpu.io)
# License: Specified in LICENSE.md.
# Version: 3.0.1

# Re-written for scalability and better user interaction.

# ----- COMMAND LINE ARGS

# Setup command args
SCRIPT="${BASH_SOURCE}"
OPTION=""
LATEST_SCRIPT_INFO=""
LATEST_RELEASE_DWLD=""

# ----- ENVIRONMENT

# Enable case-insensitive comparisons
shopt -s nocasematch

# Script binary
LOCAL_BIN="/usr/local/bin"
SCRIPT_BIN="${LOCAL_BIN}/purge-nvda"
TMP_SCRIPT="${LOCAL_BIN}/purge-nvda-new"
BIN_CALL=0
SCRIPT_FILE=""

# Script version
SCRIPT_MAJOR_VER="3" && SCRIPT_MINOR_VER="0" && SCRIPT_PATCH_VER="1"
SCRIPT_VER="${SCRIPT_MAJOR_VER}.${SCRIPT_MINOR_VER}.${SCRIPT_PATCH_VER}"

# User input
INPUT=""

# Text management
BOLD=`tput bold`
NORMAL=`tput sgr0`

# Errors
SIP_ON_ERR=1
MACOS_VER_ERR=2
NO_NV_DG_ERR=3

# System information
MACOS_VER=`sw_vers -productVersion`
MACOS_BUILD=`sw_vers -buildVersion`

# Kext Paths
SYS_EXT="/System/Library/Extensions/"
TP_EXT="/Library/Extensions/"
PLIST_FILE="/Contents/Info.plist"
NVDA_STARTUP_OFFICIAL_PLIST="${SYS_EXT}NVDAStartup.kext${PLIST_FILE}"
NVDA_STARTUP_WEB_PLIST="${TP_EXT}NVDAStartupWeb.kext${PLIST_FILE}"

# NVRAM IG+DG Variables
NV_GUID="FA4CE28D-B62F-4C99-9CC3-6815686E30F9"
IG_POWER_PREF="%01%00%00%00"
DG_POWER_PREF="%00%00%00%00"

# Patch status
AMD_PATCH_STATUS=0
NVDA_OPT_PATCH_STATUS=0
NVDA_SUP_PATCH_STATUS=0
PLIST_PATCHED=0

# PlistBuddy Configuration
PlistBuddy="/usr/libexec/PlistBuddy"
NV_DRV_KEY=":IOKitPersonalities:NVDAStartup:IOPCIMatch"
ORIGINAL_PCI_MATCH_VALUE="0x000010de&0x0000ffff"
# Modern GM/GP Arch(s): 0x13c010de 0x13c210de 0x140110de 0x15f710de 0x15f810de 0x15f910de
# 0x1b0010de 0x1b0610de 0x1b3010de 0x1b3810de 0x1b3810de 0x1b8010de 0x1b8110de 0x1b8410de
# 0x1bb010de 0x1bb310de 0x1c0210de 0x1c0310de 0x1c8110de 0x1c8210de 0x1d0110de
MODERN_NV_GPU_DEVICE_IDS="0x100010de&0xf000ffff"

# ----- SCRIPT SOFTWARE UPDATE SYSTEM

# Perform software update
perform_software_update() {
  echo "${BOLD}Downloading...${NORMAL}"
  curl -L -s -o "${TMP_SCRIPT}" "${LATEST_RELEASE_DWLD}"
  [[ "$(cat "${TMP_SCRIPT}")" == "Not Found" ]] && echo -e "Download failed.\n${BOLD}Continuing without updating...${NORMAL}" && sleep 1 && rm "${TMP_SCRIPT}" && return
  echo "Download complete.\n${BOLD}Updating...${NORMAL}"
  chmod 700 "${TMP_SCRIPT}" && chmod +x "${TMP_SCRIPT}"
  rm "${SCRIPT}" && mv "${TMP_SCRIPT}" "${SCRIPT}"
  chown "${SUDO_USER}" "${SCRIPT}"
  echo "Update complete. ${BOLD}Relaunching...${NORMAL}"
  sleep 1
  "${SCRIPT}"
  exit 0
}

# Prompt for update
prompt_software_update() {
  read -n1 -p "${BOLD}Would you like to update?${NORMAL} [Y/N]: " INPUT
  echo
  [[ "${INPUT}" == "Y" ]] && echo && perform_software_update && return
  [[ "${INPUT}" == "N" ]] && echo "\n${BOLD}Proceeding without updating...${NORMAL}" && return
  echo "\nInvalid choice. Try again.\n"
  prompt_software_update
}

# Check Github for newer version + prompt update
fetch_latest_release() {
  mkdir -p -m 775 "${LOCAL_BIN}"
  [[ "${BIN_CALL}" == 0 ]] && return
  LATEST_SCRIPT_INFO="$(curl -s "https://api.github.com/repos/mayankk2308/purge-nvda/releases/latest")"
  LATEST_RELEASE_VER="$(echo "${LATEST_SCRIPT_INFO}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
  LATEST_RELEASE_DWLD="$(echo "${LATEST_SCRIPT_INFO}" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/')"
  LATEST_MAJOR_VER="$(echo "${LATEST_RELEASE_VER}" | cut -d '.' -f1)"
  LATEST_MINOR_VER="$(echo "${LATEST_RELEASE_VER}" | cut -d '.' -f2)"
  LATEST_PATCH_VER="$(echo "${LATEST_RELEASE_VER}" | cut -d '.' -f3)"
  if [[ $LATEST_MAJOR_VER > $SCRIPT_MAJOR_VER || ($LATEST_MAJOR_VER == $SCRIPT_MAJOR_VER && $LATEST_MINOR_VER > $SCRIPT_MINOR_VER) || ($LATEST_MAJOR_VER == $SCRIPT_MAJOR_VER && $LATEST_MINOR_VER == $SCRIPT_MINOR_VER && $LATEST_PATCH_VER > $SCRIPT_PATCH_VER) && "$LATEST_RELEASE_DWLD" ]]
  then
    echo "\n>> ${BOLD}Software Update${NORMAL}\n\nA script update (${BOLD}${LATEST_RELEASE_VER}${NORMAL}) is available.\nYou are currently on ${BOLD}${SCRIPT_VER}${NORMAL}.\n"
    prompt_software_update
  fi
}

# ----- SYSTEM CONFIGURATION MANAGER

# Check caller
validate_caller() {
  [[ "$1" == "sh" && ! "$2" ]] && echo "\n${BOLD}Cannot execute${NORMAL}.\nPlease see the README for instructions.\n" && exit $EXEC_ERR
  [[ "$1" != "$SCRIPT" ]] && OPTION="$3" || OPTION="$2"
  [[ "$SCRIPT" == "$SCRIPT_BIN" || "$SCRIPT" == "purge-wrangler" ]] && BIN_CALL=1
}

# Elevate privileges
elevate_privileges() {
  if [[ `id -u` != 0 ]]
  then
    sudo "$SCRIPT" "$OPTION"
    exit 0
  fi
}

# System integrity protection check
check_sip() {
  [[ $(csrutil status | grep -i enabled) ]] && echo "\nPlease disable ${BOLD}System Integrity Protection${NORMAL}.\n" && exit $SIP_ON_ERR
}

# macOS Version check
check_macos_version() {
  MACOS_MAJOR_VER="$(echo "${MACOS_VER}" | cut -d '.' -f2)"
  MACOS_MINOR_VER="$(echo "${MACOS_VER}" | cut -d '.' -f3)"
  [[ ("${MACOS_MAJOR_VER}" < 13) || ("${MACOS_MAJOR_VER}" == 13 && "${MACOS_MINOR_VER}" < 4) ]] && echo "\n${BOLD}macOS 10.13.4 or later${NORMAL} required.\n" && exit $MACOS_VER_ERR
}

# Check for discrete NVIDIA GPU
find_nv_dg() {
  GPU_VENDOR="$(ioreg -n GFX0@0 | grep \"vendor-id\" | cut -d "=" -f2 | sed 's/ <//' | sed 's/>//' | cut -c1-4)"
  [[ "${GPU_VENDOR}" != "de10" ]] && echo "\nThis script only supports macs with ${BOLD}discrete NVIDIA GPUs${NORMAL}.\n" && exit
}

# Check patch status
check_patch() {
  BOOT_ARGS_DATA="$(nvram boot-args 2>/dev/null)"
  [[ "${BOOT_ARGS_DATA}" =~ "nv_disable=1" ]] && AMD_PATCH_STATUS=1
  [[ "${BOOT_ARGS_DATA}" =~ "agc=-1" ]] && NVDA_SUP_PATCH_STATUS=1
  [[ -f "${NVDA_STARTUP_WEB_PLIST}" && "$($PlistBuddy -c "Print ${NV_DRV_KEY}" "${NVDA_STARTUP_WEB_PLIST}" 2>/dev/null)" == "${MODERN_NV_GPU_DEVICE_IDS}" ]] && NVDA_OPT_PATCH_STATUS=1
}

# Print patch status
check_system_status() {
  FIX_STATES=("Disabled" "Enabled")
  echo "\n>> ${BOLD}System Status${NORMAL}\n"
  echo "${BOLD}AMD Fix${NORMAL}: ${FIX_STATES[$AMD_PATCH_STATUS]}"
  echo "${BOLD}NVDA eGPU Optimization${NORMAL}: ${FIX_STATES[$NVDA_OPT_PATCH_STATUS]}"
  echo "${BOLD}NVDA Suppression${NORMAL}: ${FIX_STATES[$NVDA_SUP_PATCH_STATUS]}\n"
}

# Cumulative system check
perform_sys_check() {
  check_sip
  check_macos_version
  elevate_privileges
  check_patch
  find_nv_dg
  return 0
}

# ----- OS MANAGEMENT

# Disable hibernation
disable_hibernation() {
  echo "\n>> ${BOLD}Disable Hibernation${NORMAL}\n"
  echo "${BOLD}Disabling hibernation...${NORMAL}"
  pmset -a autopoweroff 0 standby 0 hibernatemode 0
  echo "Hibernation disabled.\n"
}

# Revert hibernation settings
restore_power_settings() {
  echo "\n>> ${BOLD}Restore Power Settings${NORMAL}\n"
  echo "${BOLD}Restoring power settings...${NORMAL}"
  pmset restoredefaults
  echo "Restore complete.\n"
}

# ----- NVIDIA KEXT MANAGER

# Fix kext permissions and rebuild kextcache
sanitize_system() {
  echo "${BOLD}Sanitizing system...${NORMAL}"
  chown -R root:wheel "${SYS_EXT}NVDAStartup.kext" "${TP_EXT}NVDAStartupWeb.kext" 1>/dev/null 2>&1
  chmod -R 755 "${SYS_EXT}NVDAStartup.kext" "${TP_EXT}NVDAStartupWeb.kext" 1>/dev/null 2>&1
  kextcache -i / 1>/dev/null 2>&1
  echo "System sanitized."
}

patch_nv_plists() {
  echo "${BOLD}Patching NVIDIA driver configuration...${NORMAL}"
  [[ ! -f "${NVDA_STARTUP_WEB_PLIST}" ]] && echo "${BOLD}NVIDIA Web Drivers${NORMAL} must already be installed.\n" && return
  $PlistBuddy -c "Set ${NV_DRV_KEY} -" "${NVDA_STARTUP_OFFICIAL_PLIST}" 2>/dev/null
  $PlistBuddy -c "Set ${NV_DRV_KEY} ${MODERN_NV_GPU_DEVICE_IDS}"  "${NVDA_STARTUP_WEB_PLIST}" 2>/dev/null
  echo "Configuration patched."
  PLIST_PATCHED=1
  sanitize_system
}

# ----- NVRAM MANAGER

# iGPU-only NVRAM Update
update_nvram() {
  echo "${BOLD}Configuring NVRAM...${NORMAL}"
  BOOT_ARG="${1}"
  POWER_PREFS="${2}"
  [[ "${BOOT_ARG}" != "-no-set" ]] && nvram boot-args="${BOOT_ARG}"
  nvram "${NV_GUID}:gpu-power-prefs"="${POWER_PREFS}"
  nvram "${NV_GUID}:gpu-active"="${POWER_PREFS}"
  nvram -s
  sleep 5
  echo "NVRAM configured."
}

# ----- RECOVERY SYSTEM

revert_nv_plists() {
  echo "${BOLD}Reverting NVIDIA driver configuration...${NORMAL}"
  $PlistBuddy -c "Set ${NV_DRV_KEY} ${ORIGINAL_PCI_MATCH_VALUE}" "${NVDA_STARTUP_OFFICIAL_PLIST}" 1>/dev/null 2>&1
  $PlistBuddy -c "Set ${NV_DRV_KEY} ${ORIGINAL_PCI_MATCH_VALUE}"  "${NVDA_STARTUP_WEB_PLIST}" 1>/dev/null 2>&1
  echo "Configuration reverted."
  PLIST_PATCHED=0
  sanitize_system
}

uninstall() {
  echo "\n${BOLD}>> Uninstall${NORMAL}\n"
  echo "${BOLD}Uninstalling...${NORMAL}"
  pmset -a gpuswitch 2 2>/dev/null 1>&2
  revert_nv_plists
  update_nvram "" "${DG_POWER_PREF}"
  echo "Uninstallation complete.\n"
  echo "${BOLD}System ready.${NORMAL} Reboot to apply changes.\n"
}

# ----- BINARY MANAGER

# Bin management procedure
install_bin() {
  rsync "${SCRIPT_FILE}" "${SCRIPT_BIN}"
  chown "${SUDO_USER}" "${SCRIPT_BIN}"
  chmod 700 "${SCRIPT_BIN}" && chmod a+x "${SCRIPT_BIN}"
}

# Bin first-time setup
first_time_setup() {
  [[ $BIN_CALL == 1 ]] && return
  SCRIPT_FILE="$(pwd)/$(echo "${SCRIPT}")"
  [[ "${SCRIPT}" == "${0}" ]] && SCRIPT_FILE="$(echo "${SCRIPT_FILE}" | cut -c 1-)"
  SCRIPT_SHA="$(shasum -a 512 -b "${SCRIPT_FILE}" | awk '{ print $1 }')"
  BIN_SHA=""
  [[ -s "${SCRIPT_BIN}" ]] && BIN_SHA="$(shasum -a 512 -b "${SCRIPT_BIN}" | awk '{ print $1 }')"
  [[ "${BIN_SHA}" == "${SCRIPT_SHA}" ]] && return
  echo "\n>> ${BOLD}System Management${NORMAL}\n\n${BOLD}Installing...${NORMAL}"
  [[ ! -z "${BIN_SHA}" ]] && rm "${SCRIPT_BIN}"
  install_bin
  echo "Installation successful. ${BOLD}Proceeding...${NORMAL}\n" && sleep 1
}

# ----- USER INTERFACE

# Ask for main menu
ask_menu() {
  read -n1 -p "${BOLD}Back to menu?${NORMAL} [Y/N]: " INPUT
  echo
  [[ "${INPUT}" == "Y" ]] && clear && echo "\n>> ${BOLD}PurgeNVDA (${SCRIPT_VER})${NORMAL}" && perform_sys_check && provide_menu_selection && return
  [[ "${INPUT}" == "N" ]] && echo && exit
  echo "\nInvalid choice. Try again.\n"
  ask_menu
}

# Menu
provide_menu_selection() {
  echo "
   ${BOLD}>> eGPU Support${NORMAL}          ${BOLD}>> System Management${NORMAL}
   ${BOLD}1.${NORMAL} AMD eGPUs             ${BOLD}6.${NORMAL} Status
   ${BOLD}2.${NORMAL} NVIDIA eGPUs          ${BOLD}7.${NORMAL} Disable Hibernation
   ${BOLD}3.${NORMAL} Uninstall             ${BOLD}8.${NORMAL} Restore Power Settings

   ${BOLD}>> Additional Tools${NORMAL}
   ${BOLD}4.${NORMAL} Suppress NVIDIA GPUs
   ${BOLD}5.${NORMAL} Set Mux to iGPU

   ${BOLD}9.${NORMAL} Reboot System
   ${BOLD}0.${NORMAL} Quit
  "
  read -n1 -p "${BOLD}What next?${NORMAL} [0-9]: " INPUT
  echo
  if [[ ! -z "${INPUT}" ]]
  then
    process_args "${INPUT}"
  else
    echo && exit
  fi
  ask_menu
}

# Process user input
process_args() {
  case "${1}" in
    -fa|--fix-amd|1)
    echo "\n>> ${BOLD}AMD eGPUs${NORMAL}\n"
    update_nvram "nv_disable=1" "${IG_POWER_PREF}"
    echo "\n${BOLD}System ready.${NORMAL} Reboot to apply changes.\n";;
    -on|--optimize-nv|2)
    echo "\n>> ${BOLD}NVIDIA eGPUs${NORMAL}\n"
    patch_nv_plists
    [[ $PLIST_PATCHED == 0 ]] && ask_menu && return
    update_nvram "" "${IG_POWER_PREF}"
    echo "\n${BOLD}System ready.${NORMAL} Reboot to apply changes.\n";;
    -u|--uninstall|3)
    uninstall;;
    -sn|--suppress-nv|4)
    echo "\n>> ${BOLD}Suppress NVIDIA GPUs${NORMAL}\n"
    update_nvram "agc=-1" "${IG_POWER_PREF}"
    echo "\n${BOLD}System ready.${NORMAL} Reboot to apply changes.\n";;
    -mi|--mux-igpu|5)
    echo "\n>> ${BOLD}Set Mux to iGPU${NORMAL}\n"
    update_nvram "-no-set" "${IG_POWER_PREF}"
    echo "\n${BOLD}System ready.${NORMAL} Reboot to apply changes.\n";;
    -s|--status|6)
    check_system_status;;
    -dh|--disable-hibernation|7)
    disable_hibernation;;
    -rp|--restore-power|8)
    restore_power_settings;;
    -rb|--reboot|9)
    echo "\n>> ${BOLD}Reboot System${NORMAL}\n"
    read -n1 -p "${BOLD}Reboot${NORMAL} now? [Y/N]: " INPUT
    echo
    [[ "${INPUT}" == "Y" ]] && echo "\n${BOLD}Rebooting...${NORMAL}" && reboot && sleep 10
    [[ "${INPUT}" == "N" ]] && echo "\nReboot aborted.\n" && ask_menu;;
    0)
    echo && exit;;
    "")
    fetch_latest_release
    first_time_setup
    clear && echo ">> ${BOLD}PurgeNVDA (${SCRIPT_VER})${NORMAL}"
    provide_menu_selection;;
    *)
    echo "\nInvalid option.\n";;
  esac
}

# ----- SCRIPT DRIVER

# Primary execution routine
begin() {
  validate_caller "${1}" "${2}"
  perform_sys_check
  process_args "${2}"
}

begin "${0}" "${1}"
