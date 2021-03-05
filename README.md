# wsl-vpnkit

Because WSL2 and Entreprise Cisco AnyConnect Sercure Mobility Client with 2FA

- Automatic deployement
- Only tested with wsl-ubuntu-20.04 (but should works with all debian like)
- No admin permissions requiered
- No Docker Desktop installation requiered (needed binairies in repo)

From WSL, without active Cisco AnyConnect VPN connexion, execute:
```bash
curl https://raw.githubusercontent.com/mbl-35/wsl-vpnkit/main/install.sh | bash
```

Or clone:

```bash
git clone https://github.com/mbl-35/wsl-vpnkit.git
cd wsl-vpnkit
chmod u+x install.sh
./install.sh
```

## Files

```
    - win/bin/
        - npiperelay-0.1.0.exe  (downloded from jstarks/npiperelay)
        - vpnkit.exe            (extracted from Docker Desktop)
    - wsl2/
        - init.d/
            - wsl-vpnkit.service.template
            - dns-sync          (from matthiassb gist)
        - sbin/
            - vpnkit-tap-vsockd (extracted from Docker Desktop)
            - wsl-vpnkit        (downloded from jsakai135/wsl-vpnkit)
```

> Note: Windows Binaries have been directly extracted from Docker Desktop (method explain by sakai135)

## Thanks to:

- sakai135: Original [wsl-vpnkit](https://github.com/sakai135/wsl-vpnkit) script
- jstarks: [npiperelay](https://github.com/jstarks/npiperelay)
- matthiassb: Synchronizes /etc/resolv.conf in WSL with Windows DNS - [gist](https://gist.github.com/matthiassb/9c8162d2564777a70e3ae3cbee7d2e95)
