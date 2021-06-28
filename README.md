# wsl-vpnkit

Because WSL2 and Entreprise Cisco AnyConnect Sercure Mobility Client with 2FA

- Automatic deployement
- Only tested with wsl-ubuntu-xx.04 (but should works with all debian like)
- No admin permissions requiered (windows part)
- No Docker Desktop installation requiered (needed binairies in repo)

From WSL, **after fresh windows boot** and without active Cisco AnyConnect VPN connexion, execute:
```bash
curl https://raw.githubusercontent.com/mbl-35/wsl-vpnkit/main/vpnkit
vpnkit --install-all
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
