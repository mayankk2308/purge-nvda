#!/usr/bin/env bash

# purge-nvda.sh
# Author(s): Mayank Kumar (mayankk2308, github.com / mac_editor, egpu.io)
# License: Specified in LICENSE.md.
# Version: 3.0.5

# ----- COMMAND LINE ARGS

# Setup command args
SCRIPT="${BASH_SOURCE}"
OPTION="${1}"
ADDITIONAL_OPT="${2}"
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
SCRIPT_MAJOR_VER="3" && SCRIPT_MINOR_VER="0" && SCRIPT_PATCH_VER="5"
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
PN_STATE="purge-nvda-last-gfx-config"

# Patch status
AMD_PATCH_STATUS=0
NVDA_OPT_PATCH_STATUS=0
NVDA_SUP_PATCH_STATUS=0
PN_LAST_GFX_CONFIG=1
PLIST_PATCHED=0

# PlistBuddy Configuration
PlistBuddy="/usr/libexec/PlistBuddy"
NV_DRV_KEY=":IOKitPersonalities:NVDAStartup:IOPCIMatch"
ORIGINAL_PCI_MATCH_VALUE="0x000010de&0x0000ffff"
# Modern GM/GP Arch(s): 0x13c010de 0x13c210de 0x140110de 0x15f710de 0x15f810de 0x15f910de
# 0x1b0010de 0x1b0610de 0x1b3010de 0x1b3810de 0x1b3810de 0x1b8010de 0x1b8110de 0x1b8410de
# 0x1bb010de 0x1bb310de 0x1c0210de 0x1c0310de 0x1c8110de 0x1c8210de 0x1d0110de
MODERN_NV_GPU_DEVICE_IDS="0x100010de&0xf000ffff"

NO_RB=0
NO_ST=0

# ----- SCRIPT SOFTWARE UPDATE SYSTEM

# Perform software update
perform_software_update() {
  echo -e "${BOLD}Downloading...${NORMAL}"
  curl -q -L -s -o "${TMP_SCRIPT}" "${LATEST_RELEASE_DWLD}"
  [[ "$(cat "${TMP_SCRIPT}")" == "Not Found" ]] && echo -e "Download failed.\n${BOLD}Continuing without updating...${NORMAL}" && sleep 1 && rm "${TMP_SCRIPT}" && return
  echo -e "Download complete.\n${BOLD}Updating...${NORMAL}"
  chmod 700 "${TMP_SCRIPT}" && chmod +x "${TMP_SCRIPT}"
  rm "${SCRIPT}" && mv "${TMP_SCRIPT}" "${SCRIPT}"
  chown "${SUDO_USER}" "${SCRIPT}"
  echo -e "Update complete. ${BOLD}Relaunching...${NORMAL}"
  sleep 1
  "${SCRIPT}"
  exit 0
}

# Prompt for update
prompt_software_update() {
  read -n1 -p "${BOLD}Would you like to update?${NORMAL} [Y/N]: " INPUT
  echo
  [[ "${INPUT}" == "Y" ]] && echo && perform_software_update && return
  [[ "${INPUT}" == "N" ]] && echo -e "\n${BOLD}Proceeding without updating...${NORMAL}" && return
  echo -e "\nInvalid choice. Try again.\n"
  prompt_software_update
}

# Check Github for newer version + prompt update
fetch_latest_release() {
  mkdir -p -m 775 "${LOCAL_BIN}"
  [[ "${BIN_CALL}" == 0 ]] && return
  LATEST_SCRIPT_INFO="$(curl -q -s "https://api.github.com/repos/mayankk2308/purge-nvda/releases/latest")"
  LATEST_RELEASE_VER="$(echo -e "${LATEST_SCRIPT_INFO}" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
  LATEST_RELEASE_DWLD="$(echo -e "${LATEST_SCRIPT_INFO}" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/')"
  LATEST_MAJOR_VER="$(echo -e "${LATEST_RELEASE_VER}" | cut -d '.' -f1)"
  LATEST_MINOR_VER="$(echo -e "${LATEST_RELEASE_VER}" | cut -d '.' -f2)"
  LATEST_PATCH_VER="$(echo -e "${LATEST_RELEASE_VER}" | cut -d '.' -f3)"
  if [[ $LATEST_MAJOR_VER > $SCRIPT_MAJOR_VER || ($LATEST_MAJOR_VER == $SCRIPT_MAJOR_VER && $LATEST_MINOR_VER > $SCRIPT_MINOR_VER) || ($LATEST_MAJOR_VER == $SCRIPT_MAJOR_VER && $LATEST_MINOR_VER == $SCRIPT_MINOR_VER && $LATEST_PATCH_VER > $SCRIPT_PATCH_VER) && "$LATEST_RELEASE_DWLD" ]]
  then
    echo -e "\n>> ${BOLD}Software Update${NORMAL}\n\nSoftware updates are available.\n\nOn Your System    ${BOLD}${SCRIPT_VER}${NORMAL}\nLatest Available  ${BOLD}${LATEST_RELEASE_VER}${NORMAL}\n\nFor the best experience, stick to the latest release.\n"
    prompt_software_update
  fi
}

# ----- SYSTEM CONFIGURATION MANAGER

# Check caller
validate_caller() {
  [[ "${1}" == "sh" && ! "${2}" ]] && echo -e "\n${BOLD}Cannot execute${NORMAL}.\nPlease see the README for instructions.\n" && exit $EXEC_ERR
  [[ "$1" != "$SCRIPT" ]] && (OPTION="${3}" && ADDITIONAL_OPT="${4}") || (OPTION="${2}" && ADDITIONAL_OPT="${3}")
  [[ "$SCRIPT" == "$SCRIPT_BIN" || "$SCRIPT" == "purge-wrangler" ]] && BIN_CALL=1
}

# Elevate privileges
elevate_privileges() {
  if [[ `id -u` != 0 ]]
  then
    sudo "$SCRIPT" "${OPTION}" "${ADDITIONAL_OPT}"
    exit 0
  fi
}

# System integrity protection check
check_sip() {
  [[ $(csrutil status | grep -i enabled) ]] && echo -e "\nPlease disable ${BOLD}System Integrity Protection${NORMAL}.\n" && exit $SIP_ON_ERR
}

# macOS Version check
check_macos_version() {
  MACOS_MAJOR_VER="$(echo -e "${MACOS_VER}" | cut -d '.' -f2)"
  MACOS_MINOR_VER="$(echo -e "${MACOS_VER}" | cut -d '.' -f3)"
  [[ ("${MACOS_MAJOR_VER}" < 13) || ("${MACOS_MAJOR_VER}" == 13 && "${MACOS_MINOR_VER}" < 4) ]] && echo -e "\n${BOLD}macOS 10.13.4 or later${NORMAL} required.\n" && exit $MACOS_VER_ERR
}

# Check patch status
check_patch() {
  BOOT_ARGS_DATA="$(nvram boot-args 2>/dev/null)"
  PN_LAST_CONFIG_DATA="$(nvram "${PN_STATE}" 2>/dev/null)"
  [[ "${BOOT_ARGS_DATA}" =~ "nv_disable=1" ]] && AMD_PATCH_STATUS=1
  [[ "${BOOT_ARGS_DATA}" =~ "agc=-1" ]] && NVDA_SUP_PATCH_STATUS=1
  [[ -f "${NVDA_STARTUP_WEB_PLIST}" && "$($PlistBuddy -c "Print ${NV_DRV_KEY}" "${NVDA_STARTUP_WEB_PLIST}" 2>/dev/null)" == "${MODERN_NV_GPU_DEVICE_IDS}" ]] && NVDA_OPT_PATCH_STATUS=1
  [[ "${PN_LAST_CONFIG_DATA}" =~ "${IG_POWER_PREF}" ]] && PN_LAST_GFX_CONFIG=0
}

# Print patch status
check_system_status() {
  FIX_STATES=("Disabled" "Enabled")
  GFX_STATES=("Integrated" "Discrete")
  echo -e "\n>> ${BOLD}System Status${NORMAL}\n"
  echo -e "${BOLD}AMD Fix${NORMAL}                 ${FIX_STATES[${AMD_PATCH_STATUS}]}"
  echo -e "${BOLD}NVDA eGPU Optimization${NORMAL}  ${FIX_STATES[${NVDA_OPT_PATCH_STATUS}]}"
  echo -e "${BOLD}NVDA Suppression${NORMAL}        ${FIX_STATES[${NVDA_SUP_PATCH_STATUS}]}"
  echo -e "${BOLD}Mux Last Intent${NORMAL}         ${GFX_STATES[${PN_LAST_GFX_CONFIG}]}\n"
  echo -e "The ${BOLD}Mux Last Intent${NORMAL} state refers to what the script intended last\ntime, and not necessarily whether the script succeeded or not,\nas the actual mux value is \"consumed\" and cannot be tracked.\nBy default, the intent is ${BOLD}Discrete${NORMAL}.\n"
}

# Cumulative system check
perform_sys_check() {
  check_sip
  check_macos_version
  elevate_privileges
  check_patch
  return 0
}

# ----- NVIDIA KEXT MANAGER

# Fix kext permissions and rebuild kextcache
sanitize_system() {
  [[ ${NO_ST} == 1 ]] && return
  echo -e "${BOLD}Sanitizing system...${NORMAL}"
  chown -R root:wheel "${SYS_EXT}NVDAStartup.kext" "${TP_EXT}NVDAStartupWeb.kext" 1>/dev/null 2>&1
  chmod -R 755 "${SYS_EXT}NVDAStartup.kext" "${TP_EXT}NVDAStartupWeb.kext" 1>/dev/null 2>&1
  kextcache -i / 1>/dev/null 2>&1
  echo -e "System sanitized."
}

# Patch NVIDIA drivers
patch_nv_plists() {
  echo -e "${BOLD}Patching NVIDIA driver configuration...${NORMAL}"
  [[ ! -f "${NVDA_STARTUP_WEB_PLIST}" ]] && echo -e "${BOLD}NVIDIA Web Drivers${NORMAL} must already be installed.\n" && return
  $PlistBuddy -c "Set ${NV_DRV_KEY} -" "${NVDA_STARTUP_OFFICIAL_PLIST}" 2>/dev/null
  $PlistBuddy -c "Set ${NV_DRV_KEY} ${MODERN_NV_GPU_DEVICE_IDS}"  "${NVDA_STARTUP_WEB_PLIST}" 2>/dev/null
  echo -e "Configuration patched."
  PLIST_PATCHED=1
  sanitize_system
}

# ----- NVRAM MANAGER

# iGPU-only NVRAM Update
update_nvram() {
  echo -e "${BOLD}Configuring NVRAM...${NORMAL}"
  BOOT_ARG="${1}"
  POWER_PREFS="${2}"
  [[ "${BOOT_ARG}" != "-no-set" ]] && nvram boot-args="${BOOT_ARG}"
  nvram "${NV_GUID}:gpu-power-prefs"="${POWER_PREFS}"
  nvram "${NV_GUID}:gpu-active"="${POWER_PREFS}"
  nvram "${PN_STATE}"="${POWER_PREFS}"
  nvram -s
  sleep 5
  echo -e "NVRAM configured."
}

# Patch execution routine
execute_patch() {
  update_nvram "${1}" "${2}"
  echo -e "\n${BOLD}System ready.${NORMAL} Reboot to apply changes.\n"
  prompt_reboot
}

# ----- RECOVERY SYSTEM

# Revert PLIST configuration
revert_nv_plists() {
  echo -e "${BOLD}Reverting NVIDIA driver configuration...${NORMAL}"
  $PlistBuddy -c "Set ${NV_DRV_KEY} ${ORIGINAL_PCI_MATCH_VALUE}" "${NVDA_STARTUP_OFFICIAL_PLIST}" 1>/dev/null 2>&1
  $PlistBuddy -c "Set ${NV_DRV_KEY} ${ORIGINAL_PCI_MATCH_VALUE}"  "${NVDA_STARTUP_WEB_PLIST}" 1>/dev/null 2>&1
  echo -e "Configuration reverted."
  PLIST_PATCHED=0
  sanitize_system
}

# Uninstall NVRAM changes
uninstall() {
  echo -e "\n${BOLD}>> Uninstall${NORMAL}\n"
  echo -e "${BOLD}Uninstalling...${NORMAL}"
  pmset -a gpuswitch 2 2>/dev/null 1>&2
  revert_nv_plists
  update_nvram "" "${DG_POWER_PREF}"
  echo -e "Uninstallation complete.\n"
  echo -e "${BOLD}System ready.${NORMAL} Reboot to apply changes.\n"
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
  SCRIPT_FILE="$(pwd)/$(echo -e "${SCRIPT}")"
  [[ "${SCRIPT}" == "${0}" ]] && SCRIPT_FILE="$(echo -e "${SCRIPT_FILE}" | cut -c 1-)"
  SCRIPT_SHA="$(shasum -a 512 -b "${SCRIPT_FILE}" | awk '{ print $1 }')"
  BIN_SHA=""
  [[ -s "${SCRIPT_BIN}" ]] && BIN_SHA="$(shasum -a 512 -b "${SCRIPT_BIN}" | awk '{ print $1 }')"
  [[ "${BIN_SHA}" == "${SCRIPT_SHA}" ]] && return
  echo -e "\n>> ${BOLD}System Management${NORMAL}\n\n${BOLD}Installing...${NORMAL}"
  [[ ! -z "${BIN_SHA}" ]] && rm "${SCRIPT_BIN}"
  install_bin
  echo -e "Installation successful. ${BOLD}Proceeding...${NORMAL}\n" && sleep 1
}

# ----- USER INTERFACE

# Prompt reboot
prompt_reboot() {
  [[ ${NO_RB} == 1 ]] && return
  read -n1 -p "${BOLD}Reboot now${NORMAL}? [Y/N]: " INPUT
  if [[ "${INPUT}" == "Y" ]]
  then
    echo -e "\n\n${BOLD}Rebooting...${NORMAL}"
    reboot 1>/dev/null 2>&1
  elif [[ "${INPUT}" == "N" ]]
  then
    echo -e "\n\nReboot aborted.\n"
  else
    echo -e "\n\nInvalid selection.\n"
    prompt_reboot
  fi
}

# Request donation
donate() {
  open "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=Development%20of%20PurgeNVDA&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest"
  echo -e "\nSee your ${BOLD}web browser${NORMAL}.\n"
}

# Ask for main menu
ask_menu() {
  read -n1 -p "${BOLD}Back to menu?${NORMAL} [Y/N]: " INPUT
  echo
  [[ "${INPUT}" == "Y" ]] && clear && echo -e "\n>> ${BOLD}PurgeNVDA (${SCRIPT_VER})${NORMAL}" && perform_sys_check && provide_menu_selection && return
  [[ "${INPUT}" == "N" ]] && echo && exit
  echo -e "\nInvalid choice. Try again.\n"
  ask_menu
}

# Menu
provide_menu_selection() {
  echo -e "
   ${BOLD}>> eGPU Optimizations${NORMAL}    ${BOLD}>> System Management${NORMAL}
   ${BOLD}1.${NORMAL} AMD eGPUs             ${BOLD}4.${NORMAL} Status
   ${BOLD}2.${NORMAL} NVIDIA eGPUs          ${BOLD}5.${NORMAL} Suppress NVIDIA GPUs
   ${BOLD}3.${NORMAL} Uninstall             ${BOLD}6.${NORMAL} Set Mux to iGPU

   ${BOLD}D.${NORMAL} Donate
   ${BOLD}0.${NORMAL} Quit
  "
  read -n1 -p "${BOLD}What next?${NORMAL} [0-8|D]: " INPUT
  echo
  if [[ ! -z "${INPUT}" ]]
  then
    process_args "${INPUT}"
  else
    echo && exit
  fi
  ask_menu
}

# Process supplemental args
process_sup_args() {
  [[ ${ADDITIONAL_OPT} == *"no-rb"* ]] && NO_RB=1
  [[ ${ADDITIONAL_OPT} == *"no-st"* ]] && NO_ST=1
}

# Process user input
process_args() {
  case "${1}" in
    -fa|--fix-amd|1)
    echo -e "\n>> ${BOLD}AMD eGPUs${NORMAL}\n"
    execute_patch "nv_disable=1" "${IG_POWER_PREF}";;
    -on|--optimize-nv|2)
    echo -e "\n>> ${BOLD}NVIDIA eGPUs${NORMAL}\n"
    patch_nv_plists
    [[ $PLIST_PATCHED == 0 ]] && ask_menu && return
    execute_patch "" "${IG_POWER_PREF}";;
    -u|--uninstall|3)
    uninstall
    prompt_reboot;;
    -s|--status|4)
    check_system_status;;
    -sn|--suppress-nv|5)
    echo -e "\n>> ${BOLD}Suppress NVIDIA GPUs${NORMAL}\n"
    execute_patch "agc=-1" "${IG_POWER_PREF}";;
    -mi|--mux-igpu|6)
    echo -e "\n>> ${BOLD}Set Mux to iGPU${NORMAL}\n"
    execute_patch "-no-set" "${IG_POWER_PREF}";;
    -d|--donate|d|D)
    donate;;
    0)
    echo && exit;;
    "")
    fetch_latest_release
    first_time_setup
    clear && echo -e ">> ${BOLD}PurgeNVDA (${SCRIPT_VER})${NORMAL}"
    provide_menu_selection;;
    *)
    echo -e "\nInvalid option.\n";;
  esac
}

# ----- SCRIPT DRIVER

# Primary execution routine
begin() {
  validate_caller "${1}" "${2}" "${3}"
  perform_sys_check
  process_sup_args
  process_args "${2}"
}
begin "${0}" "${1}" "${2}"
