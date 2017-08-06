# Purge-NVDA
A tiny script for Macs that purges the activation of the discrete **NVIDIA** GPUs on **macOS High Sierra** to enable **AMD** external graphics acceleration. This is confirmed to work on the **GeForce 750M 2GB** at the time of release.

## Usage
To activate the purge:
```bash
sudo ./purge-nvda.sh
```

Your mac will only boot with external graphics plugged in (along with an external display). To revert your system:
```bash
sudo ./purge-nvda.sh restore
```

You can now boot normally, untethered from your eGPU.

## License
This project is available under the **MIT** license.
