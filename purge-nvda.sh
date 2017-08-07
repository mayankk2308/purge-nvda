#!/bin/sh
# Script (purge-nvda.sh) by mac_editor @ egpu.io (mayankk2308@gmail.com)
# Usage:
# sudo ./purge-nvda.sh -> moves NVDA kexts to prevent NVDA GPU activation
# sudo ./purge-nvda.sh restore -> moves NVDA kexts back while keeping a backup - does not override newer versions.

operation="$1"
backup_dir="/Library/Application Support/Purge-NVDA/"
final_message=""
mkdir -p "$backup_dir"

if [[ "$operation" == "" ]]
then
  if [[ "$(ls /System/Library/Extensions/ | grep NVDA)" ]]
  then
    echo "Moving NVIDIA drivers..."
    if [[ "$(ls "$backup_dir")" ]]
    then
      rm -r "$backup_dir"*
    fi
    mv /System/Library/Extensions/NVDA*.kext "$backup_dir"
    final_message="Complete. Power on Mac with eGPU plugged in only."
  else
  final_message="Kexts already moved. No action required."
  fi
elif [[ "$operation" == "restore" ]]
then
  echo "Restoring NVIDIA drivers..."
  rsync -r -u "$backup_dir"* /System/Library/Extensions/
  final_message="Complete. Restart to reinstate default High Sierra behavior."
fi

echo "Invoke kext caching..."
touch /System/Library/Extensions
echo "$final_message"
