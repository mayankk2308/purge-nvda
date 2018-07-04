![Header](https://raw.githubusercontent.com/mayankk2308/purge-nvda/master/resources/header.png)

![macOS Support](https://img.shields.io/badge/macOS-10.13.4+-orange.svg?style=for-the-badge) ![Github All Releases](https://img.shields.io/github/downloads/mayankk2308/purge-nvda/total.svg?style=for-the-badge)
# Purge-NVDA
A simple script for Macs that purges the activation of the discrete **NVIDIA** GPUs on **macOS** and by extension enables **AMD external graphics** support.

## Requirements
This script requires the following specifications:
* Mac with integrated Intel GPU + discrete **NVIDIA** GPU
* **macOS 10.13.4** or later

For AMD eGPU support please use along with [purge-wrangler.sh](https://github.com/mayankk2308/purge-wrangler/releases).

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
Boot back into macOS, then copy-paste the following into **Terminal**:
```bash
curl -s "https://api.github.com/repos/mayankk2308/purge-nvda/releases/latest" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/' | xargs curl -L -s -0 > purge-nvda.sh && chmod +x purge-nvda.sh && ./purge-nvda.sh && rm purge-nvda.sh
```

Note that you may change to a different valid version in the above command.

Alternatively, download [purge-nvda.sh](https://github.com/mayankk2308/purge-nvda/releases). Then run the following in **Terminal**:
```bash
$ cd Downloads
$ chmod +x purge-nvda.sh
$ ./purge-nvda.sh
```

You will be prompted to enter your account password for **superuser permissions**. On first-time use, the script will auto-install itself as a binary into `/usr/local/bin/`. This enables much simpler future use. To use the script again, just type the following in **Terminal**:
```bash
$ purge-nvda
```

This is supported on **2.0.0** or later. Automatic updates are supported from **2.1.0** or later.

## Options
The script provides users with a variety of options in an attempt to be as user-friendly as possible.

#### 1. Fix AMD eGPUs (`-fa|--fix-amd`)
Disables all NVIDIA GPUs to resolve AMD-NVIDIA framebuffer conflicts when an AMD eGPU is initialized on the system.

#### 2. Optimize NVIDIA eGPUs (`-on|--optimize-nv`)
Disables only the internal NVIDIA GPU to enable OpenCL/GL acceleration and high performance with NVIDIA eGPUs with a combination of NVRAM + NVDA kernel extension patches.

#### 3. Suppress NVIDIA GPUs (`-sn|--suppress-nv`)
Disables all NVIDIA GPUs at macOS-independent machine level - therefore affecting all macOS installations running on the machine. This patch does not modify any system files.

### 4. Set Mux to iGPU (`-mi|--mux-igpu`)
Sets the system graphics multiplexer to the integrated Intel GPU, if available. This preference is after a system boots with its discrete GPU enabled (such that macOS may initialize its framebuffer), thus only lasts for one boot unless appropriate measures to curb dGPU activation are in place.

#### 5. Uninstall (`-u|--uninstall`)
Uninstalls any possible system modifications made by the script.

#### 6. System Status (`-s|--status`)
Shows the status of the currently installed patches on the system.

#### 7. Disable Hibernation (`-dh|--disable-hibernation`)
Disables hibernation mode and automatic power off as these settings may resolve wake-up failures with discrete graphics disabled.

#### 9. Restore Power Settings (`-rp|--restore-power`)
Restores the hibernation mode configurations to recommended settings.

#### 10. Reboot System (`-rb|--reboot`)
Reboots the system after requesting confirmation.

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

## Donate
A *"Thank you"* is enough to make me smile. But due to popular demand:

[![paypal][image-1]][1]

Knock yourself out :)

[image-1]:	https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif
[1]:	https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=mac_editor&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest
