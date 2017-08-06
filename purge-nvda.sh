#!/bin/sh
# Script (purge-nvda.sh) by mac_editor @ egpu.io (mayankk2308@gmail.com)

operation="$1"
backup_dir="/Library/Application Support/Purge-NVDA/"
final_message="No changes made."
mkdir -p "$backup_dir"

if [[ "$operation" == "" ]]
then
  echo "Moving NVIDIA drivers..."
  mv /System/Library/Extensions/NVDA*.kext "$backup_dir"
  final_message="Complete. Power on Mac with eGPU plugged in only."
elif [[ "$operation" == "restore" ]]
then
  if [[ "$(ls "$backup_dir")" ]]
  then
    echo "Restoring NVIDIA drivers..."
    mv "$backup_dir"* /System/Library/Extensions/
    final_message="Complete. Restart to reinstate default High Sierra behavior."
  fi
fi

echo "Invoke kext caching..."
touch /System/Library/Extensions
echo "$final_message"
