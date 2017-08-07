# Purge-NVDA
A tiny script for Macs that purges the activation of the discrete **NVIDIA** GPUs on **macOS High Sierra** to enable **AMD** external graphics acceleration. This is confirmed to work on the **GeForce 750M 2GB** at the time of release. At the moment, this does not work with **High Sierra B5**.

## Usage
To activate the purge:
```bash
sudo ./purge-nvda.sh
```

Your mac will behave like an iGPU-only device with external graphics plugged in (along with an external display). To revert your system:
```bash
sudo ./purge-nvda.sh restore
```

To update the **NVRAM** only:
```bash
sudo ./purge-nvda nvram-only
```

To completely uninstall changes:
```bash
sudo ./purge-nvda uninstall
```

## License
This project is available under the **MIT** license.
