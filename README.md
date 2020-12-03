# BASH script for install a new BBB server with:

- prepair the server (update, set hostname, set timezone,...)
- Connect to DarsPlus private cloud
- Install OpenConnect and create the service to connection to private cloud
- Mount the NFS partition
- Install BBB
- Apply setting to BBB
- Install exporter for Grafana

# Attention !!!

## this script made for personal usege, with very specific configuration. Never, Ever run this in your BBB server.

### Usage

```
git clone https://github.com/smrezvani/darsplus-bbb-config.git && cd darsplus-bbb-config
chmod +x new-server.sh
./new-server.sh
```

### And you know the rest... :P
