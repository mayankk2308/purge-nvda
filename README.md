![Github All Releases](https://img.shields.io/github/downloads/mayankk2308/purge-nvda/total.svg?style=for-the-badge)
# Purge-NVDA
A simple script for Macs that purges the activation of the discrete **NVIDIA** GPUs on **macOS** and by extension enables **AMD external graphics** support.

## Requirements
This script requires the following specifications:
* Mac with integrated Intel GPU + discrete **NVIDIA** GPU
* **macOS Mavericks** or later

For AMD eGPU support please use **macOS 10.13.4 or later** along with [purge-wrangler.sh](https://github.com/mayankk2308/purge-wrangler/releases).

It is recommended that you have a backup of the system. Testing was done on a **Mid-2014 MacBook Pro w/ GeForce GT 750M**.

## Usage
Please follow these steps:

### Step 1
Disable **system integrity protection** for macOS using **Terminal** in **Recovery**:
```bash
$ csrutil disable
$ reboot
```

### Step 2
Boot back into macOS and copy-paste the following into **Terminal**:
```bash
curl -s https://github.com/mayankk2308/purge-nvda/releases/download/2.0.0/purge-nvda.sh;chmod +x purge-nvda.sh;./purge-nvda.sh;rm purge-nvda.sh
```

You will be prompted to enter your account password for **superuser permissions**. On first-time use, the script will auto-install itself as a binary into `/usr/local/bin/`. This enables much simpler future use - simply type in `purge-nvda` in Terminal. You can also download a different release if you like, by changing **2.0.0** in the command above to the version of your choice. Note that versions prior to **2.0.0** do not have auto-install capability.

## Options
The script provides users with a variety of options in an attempt to be as user-friendly as possible.

### 1. Enable AMD eGPUs
Disables the NVIDIA GPU using the **kextless** NVRAM patch, allowing acceleration of foreign AMD framebuffers, and therefore AMD eGPUs.

### 2. Suppress NVIDIA GPUs
Disables the NVIDIA GPU using **kext-based** framebuffer deactivation, which mounts the GPU but never allows instantiation and use for render or compute. This is recommended if eGPUs are not involved and iGPU-only behavior for other reasons is needed.

### 3. Force Single iGPU Boot
Patches NVRAM to force only one macOS session with iGPU use only. A subsequent boot will have an active discrete NVIDIA GPU.

### 4. System Status
Checks for the applied patches and provides system state information.

### 5. Uninstall
Uninstalls any applied modifications made using the script or binary. This will not uninstall the script/binary itself.

### 6. Command-Line Shortcuts
Prints a list of single-letter options that may be passed to the script or binary to completely forgo the command-line user interface and directly perform actions.

### 7. Script Version
Prints the version of the script/binary.

### 8. Disable Hibernation
Disables hibernation mode and automatic power off as these settings may resolve wake-up failures with discrete graphics disabled.

### 9. Enable Hibernation
Restores the hibernation mode configurations to recommended settings.

### 10. Reboot System
Reboots the system with a countdown.

## Troubleshooting
If you are unable to boot into macOS, boot into Single User Mode (**CMD + S** on boot) and type in the following commands:
```bash
$ mount -uw /
$ purge-nvda
```

Uninstall the script modifications and reboot.

## References
Due credit goes to the MacRumors members (esp. **@nsgr**) for the **NVRAM** settings that make this possible without requiring a separate **ArchLinux** installation to manually manage these values.

## Disclaimer
This script moves core system files associated with macOS. While any of the potential issues with its application are recoverable, please use this script at your discretion. I will not be liable for any damages to your operating system.

## License
This project is available under the **MIT** license. See the license file for more information.
