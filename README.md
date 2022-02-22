# **DEPRECATED** - no longer actively maintained

WSL-VPNKIT instance creation procedure of the original [sakai135/wsl-vpnkit](https://github.com/sakai135/wsl-vpnkit) repo is now simpler and more robust...
 
You can :
- manual install it by (needs network acces from windows):
  - download the latest `wsl-vpnkit.tar.gz` release at https://github.com/sakai135/wsl-vpnkit/releases,
  - import this wsl2 instance with command: `wsl --import wsl-vpnkit <windows-wsl-storage> c:\Users\<yourname>\Downloads\wsl-vpnkit.tar.gz`
  - starts the kit `wsl -d wsl-vpnkit service wsl-vpnkit-start`
- use my [wsl-vpnkit-tray](https://github.com/mbl-35/wsl-vpnkit-tray) to start/stop (autostart) the wsl2 `wsl-vpnkit` named instance ..
- when started, you will have network access from your others wsl2 instances


If you use [scoop](https://github.com/ScoopInstaller/Scoop), it can be more simple to install both wsl-vpnkit and wsl-vpnkit-tray, using my 
[scoop-srsrns](https://github.com/mbl-35/scoop-srsrns) buckets:
```powershell
PS> scoop bucket add srsrns https://raw.githubusercontent.com/mbl-35/scoop-srsrns
PS> scoop update
PS> scoop install wsl-vpnkit wsl-vpnkit-tray
```
---


# wsl-vpnkit

Because WSL2 and Entreprise Cisco AnyConnect Sercure Mobility Client with 2FA

- Automatic deployement
- Only tested with wsl-ubuntu-xx.04 (but should works with all debian like)
- No admin permissions requiered (windows part)
- No Docker Desktop installation requiered (needed binairies in repo)

From WSL, **after fresh windows boot** and without active Cisco AnyConnect VPN connexion, execute:
```bash
wget https://raw.githubusercontent.com/mbl-35/wsl-vpnkit/main/vpnkit
chmod u+x vpnkit
./vpnkit --install-all
```

Or clone:

```bash
git clone https://github.com/mbl-35/wsl-vpnkit.git
cd wsl-vpnkit
chmod u+x vpnkit
./vpnkit --install-all
```

> Note: Windows binaries have been directly extracted from Docker Desktop version 2.3.0.3(45519) - method explain by sakai135

## Thanks to:

- sakai135: Original [wsl-vpnkit](https://github.com/sakai135/wsl-vpnkit) script
- jstarks: [npiperelay](https://github.com/jstarks/npiperelay)
- matthiassb: Synchronizes /etc/resolv.conf in WSL with Windows DNS - [gist](https://gist.github.com/matthiassb/9c8162d2564777a70e3ae3cbee7d2e95)
