# ![Header](https://raw.githubusercontent.com/mayankk2308/purge-nvda/master/resources/header.png)
![Script Version](https://img.shields.io/github/release/mayankk2308/purge-nvda.svg?style=for-the-badge) ![macOS Support](https://img.shields.io/badge/macOS-10.13.4+-orange.svg?style=for-the-badge) ![Github All Releases](https://img.shields.io/github/downloads/mayankk2308/purge-nvda/total.svg?style=for-the-badge) [![paypal](https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/PayPal.svg/124px-PayPal.svg.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=Development%20of%20PurgeNVDA&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest)
# PurgeNVDA
**purge-nvda.sh** is required for certain macs to configure the system further for working external GPU support, alongside [purge-wrangler.sh](https://github.com/mayankk2308/purge-wrangler). It may also serve useful for other use cases such as bad discrete GPU chipsets, etc., but is not tested or guaranteed.

## Contents
A quick run-through of what's included in this document:
- [Pre-Requisites](https://github.com/mayankk2308/purge-nvda#pre-requisites)
  - macOS requirements, pre-system configuration specifics, and more.
- [Installation](https://github.com/mayankk2308/purge-nvda#installation)
  - Installing and running the script.
- [Script Options](https://github.com/mayankk2308/purge-nvda#script-options)
  - Available capabilities and options in the script.
- [Recovery](https://github.com/mayankk2308/purge-nvda#recovery)
  - Easy way to recover from an unbootable system using the script.
- [Post-Install](https://github.com/mayankk2308/purge-nvda#post-install)
  - System configuration after script installation and some other things of note.
- [Known Issues](https://github.com/mayankk2308/purge-nvda#known-issues)
  - A table of known issues and side effects of using the script.
- [Troubleshooting](https://github.com/mayankk2308/purge-nvda#troubleshooting)
  - Additional resources and guides for eGPUs.
- [Disclaimer](https://github.com/mayankk2308/purge-nvda#disclaimer)
  - Please read the disclaimer before using this script.
- [License](https://github.com/mayankk2308/purge-nvda#license)
  - By using this script, you consent to the license that the script comes bundled with.
- [Support](https://github.com/mayankk2308/purge-nvda#support)
  - Support the developer if you'd like to.

## Pre-Requisites
In case you are not up-to-date, please read [Apple](https://support.apple.com/en-us/HT208544)'s external GPU documentation first to see what is already supported on macOS. The following is a table that summarizes **system requirements** for using this script:

| Configuration | Requirement | Description |
| :-----------: | :---------: | :---------- |
| **macOS** | 10.13.4+ | Older versions of macOS require different patching mechanisms that this script does not include. Please check [eGPU.io](https://egpu.io) for more information. |
| **System Integrity Protection** | Disabled | By default, this prevents system modifications that the script would like to make, and hence must be disabled. SIP can be disabled as described in this [article](https://developer.apple.com/library/archive/documentation/Security/Conceptual/System_Integrity_Protection_Guide/ConfiguringSystemIntegrityProtection/ConfiguringSystemIntegrityProtection.html).  |
| **Internal GPUs** | Intel + NVIDIA | Presence of **both** an integrated Intel GPU and discrete NVIDIA GPU is required, i.e., **iMacs are not supported**. Script may be run on iMacs for experimentation. |

## Installation
**purge-nvda.sh** auto-manages itself and provides multiple installation and recovery options. Once the **pre-requisites** are satisfied, install the script by running the following in **Terminal**:
```bash
curl -q -s "https://api.github.com/repos/mayankk2308/purge-nvda/releases/latest" | grep '"browser_download_url":' | sed -E 's/.*"([^"]+)".*/\1/' | xargs curl -L -s -0 > purge-nvda.sh && chmod +x purge-nvda.sh && ./purge-nvda.sh && rm purge-nvda.sh
```

For future use, only the following will be required:
```bash
purge-nvda
```

In case the command above does not work, you can re-use the long installation command and fix the issue.

### Some Notes
After using the script, sometimes you may observe that the system is unbootable. In such a case, boot into single user mode as advised in the [pre-requisites](https://github.com/mayankk2308/purge-nvda#pre-requisites) and **set mux to iGPU** to force the mux setting. This needs to be done because in some cases, the setting does not apply (after using option 1, 2, 4, or 5 while in macOS).

## Script Options
PurgeNVDA makes it super-easy to perform actions with an interactive menu, and is recommended for most users. Providing no arguments to the script defaults to the menu.

| Argument | Menu | Description |
| :------: | :--: | :---------- |
| `-fa` or `--fix-amd` | AMD eGPUs | Disables the discrete NVIDIA GPU, sets the gmux to the Intel GPU, allowing any AMD framebuffers to render correctly. Any and all NVIDIA GPUs will be disabled. This patch affects all installations running on the machine and does not modify system files. |
| `-on` or `--optimize-nv` | NVIDIA eGPUs | Disables only the internal NVIDIA GPU and sets the gmux to Intel GPU to enable OpenCL/GL acceleration and high performance with NVIDIA eGPUs with a combination of NVRAM + NVDA kernel extension patches. |
| `-u` or `--uninstall` | Uninstall | Reverts and removes any system modifications made using the script. If unsuccessful, attempt using it in [Single User Mode](https://support.apple.com/en-us/HT201573) (Boot with **⌘ + S**). |
| `-sn` or `--suppress-nv` | Suppress NVIDIA GPUs | Disables all NVIDIA GPUs with fixed  cold gmux - therefore affecting all macOS installations running on the machine. This patch does not modify any system files. |
| `-mi` or `--mux-igpu` | Set Mux to iGPU | Sets the system graphics multiplexer to the integrated Intel GPU, if available. This preference is after a system boots with its discrete GPU enabled (such that macOS may initialize its framebuffer), thus only lasts for one boot unless appropriate measures to curb dGPU activation are in place. |
| `-s` or `--status` | Status | Shows the currently installed patches on the system. Since the mux commands are consumed, mux status will show as inactive/disabled after the chip has been set. |
| `-dh` or `--disable-hibernation` | Disable Hibernation | Disables hibernation mode and automatic power off as these settings may resolve wake-up failures with discrete graphics disabled. |
| `-rp` or `--restore-power` | Restore Power Settings | Restores the hibernation mode configurations to factory settings. |
| `-rb` or `--reboot` | Reboot System | Prompts the user to reboot the system, and instantly does so if after user consent, useful for easy command-line reboots. |

## Recovery
If you are unable to boot into macOS, boot while pressing **⌘ + S**, then enter the following commands:
```bash
mount -uw /
purge-nvda -u
```
This will restore your system to a clean state as documented above.

## Post-Install
After installing the script, all settings as described in [pre-requisites](https://github.com/mayankk2308/purge-wrangler#pre-requisites) must persist. For instance, **system integrity protection** must remain disabled as long as the system is in the *patched* state.

## Known Issues
**purge-nvda.sh** implements solutions that bring with it multiple undesirable side effects. The following table lists issues and their potential impact on daily usage.

| Issue | Workaround | Description |
| :---: | :--------: | :---------- |
| **Unbootable System** | Set Mux to iGPU | Because of the unknown impact of the mux variable in EFI, the patches are sometimes partially applied, thus resulting in an unbootable system. Booting into single user mode and running the workaround re-sets the mux correctly and completes the patch. |
| **Sleep** | None | Use of this patch on applicable macs disables proper sleep completely, including the loss of clamshell sleep modes, that is, the display will not turn off even if the laptop lid is closed. Uninstall recommended for on-the-go use. I cannot investigate further workarounds, but I believe some Hackintosh solutions to enable sleep on iGPU might be applicable. |
| **dGPU Power Draw** | None | Discrete GPU draws power and emits heat even though it is disabled. I do not have an applicable machine to test further, but this script unfortunately does not include workarounds to address this issue. Perhaps some tweaking with power management and GPU control kexts could make a difference. |

## Troubleshooting
Troubleshooting plays an important role in any kind of hack/patch. New OSes and hardware tend to bring with them new problems and challenges. The hardware chart aims to cover all variances of problems with eGPUs so far, but there can be some specific missed edge cases. The following is a list of additional resources rich in information:

| Resource | Description |
| :------: | :---------- |
| [eGPU.io Build Guides](https://egpu.io/build-guides/) | See builds for a variety of systems and eGPUs. If you don't find an exact match, look for similar builds. |
| [eGPU.io Troubleshooting Guide](https://egpu.io/forums/mac-setup/guide-troubleshooting-egpus-on-macos/) | Learn about some basics of eGPUs in macOS and find out what means what. This guide does not cover any Windows/Bootcamp-related efforts. |
| [eGPU.io Community](https://egpu.io/forums/) | The eGPU.io forums are a great place to post concerns and doubts about your setup. Be sure to search the forum before posting as there might be high chance your doubt has already been answered. |
| [eGPU Community on Reddit](https://www.reddit.com/r/eGPU/) | The reddit community is a wonderful place to request additional help for your new setup, and a good place to find fellow eGPU users. |

My username on both communities is [@mac_editor](https://egpu.io/forums/profile/mac_editor). Feel free to mention my username on eGPU.io posts - I get an email notifying me of the same. In any case, with thousands of members, the community is a welcoming place. Don't be shy!

## Disclaimer
This script moves core system files associated with macOS. While any of the potential issues with its application are recoverable, please use this script at your discretion. I will not be liable for any damages to your operating system.

## License
The bundled license allows commercial use and redistribution for any purposes. This software comes without any warranty or guaranteed support. By using the script, you **agree** to adhere to the **MIT** license. For more information, please see the [LICENSE](./LICENSE.md).

## Support
If you loved **purge-nvda.sh**, consider **starring** the repository or if you would like to, donate via **PayPal**:

[![paypal](https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/PayPal.svg/124px-PayPal.svg.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=mayankk2308@gmail.com&lc=US&item_name=Development%20of%20PurgeNVDA&no_note=0&currency_code=USD&bn=PP-DonationsBF:btn_donate_SM.gif:NonHostedGuest)

Thank you for using **purge-nvda.sh**. This project is currently maintained for any discovered bugs/errors.
