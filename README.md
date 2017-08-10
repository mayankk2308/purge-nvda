# Purge-NVDA
A tiny script for Macs that purges the activation of the discrete **NVIDIA** GPUs on **macOS**. This is confirmed to work on the **GeForce 750M 2GB** at the time of release. At the moment, this does not work with **High Sierra B5**, but showed promising results on **Beta 4**. This script is a **work-in-progress** for **High Sierra** support. Once functional on **HSierra**, this will enable **native external graphics support** which was previously not possible on **NVIDIA-based** macs.

## Usage
Please ensure you have a backup of your operating system (or an additional install to browse the modified system's files to revert them manually) before proceeding.

To activate the purge:
```bash
$ sudo ./purge-nvda.sh
```

Your mac will now behave like an iGPU-only device. If you are unable to boot into macOS, boot into recovery, launch **Terminal** and type in the following commands:
```bash
$ sudo nvram fa4ce28d-b62f-4c99-9cc3-6815686e30f9:gpu-power-prefs=%01%00%00%00
$ sudo nvram fa4ce28d-b62f-4c99-9cc3-6815686e30f9:gpu-active=%01%00%00%00
$ sudo nvram fa4ce28d-b62f-4c99-9cc3-6815686e30f9:gpu-policy=%01
```

To restore drivers:
```bash
$ sudo ./purge-nvda.sh restore
```

This option only copies back the relevant kexts it moved initially. Use the **uninstall** option in general.

To update the **NVRAM** only:
```bash
$ sudo ./purge-nvda nvram-only
```

This is useful for **iGPU-only** mode for the next boot only. Rebooting again will restore default behavior.

To completely uninstall changes:
```bash
$ sudo ./purge-nvda uninstall
```

Uninstallation recommended before updating macOS.

## License
This project is available under the **MIT** license.
