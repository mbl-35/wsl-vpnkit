#!/bin/bash

set -e

# -- VARS ---

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

GITHUB_REPO=${GITHUB_REPO:-https://github.com/mbl-35/wsl-vpnkit.git}    # Github source repo
VPNKIT_INSTAL_PATH=${VPNKIT_INSTAL_PATH:-/mnt/c/wsl-vpnkit}             # Windows installation (wsl path)
NPIPERELAY_VERSION="0.1.0"

step (){ echo -e "\033[0;32m== $1 ==\033[0m"; }
info (){ echo -e "\033[1;33m=> $1\033[0m"; }


# -- Install Repo --
[ -d $VPNKIT_INSTAL_PATH ] || {
    step "Create windows install dir: $VPNKIT_INSTAL_PATH"
    mkdir -p $VPNKIT_INSTAL_PATH
}

step "Synchronize Repo"
which git >/dev/null || { info "Installing git... "; sudo apt-get install -y git; }
[ -d $VPNKIT_INSTAL_PATH/.git ] && {
    info "Self updating..."
    ( cd $VPNKIT_INSTAL_PATH ; git pull; )
} || {
    info "Cloning $GITHUB_REPO ..."
    ( cd $VPNKIT_INSTAL_PATH ; git clone $GITHUB_REPO .; )
}

# -- Get external files -- 
step "External Dependencies"

[ -f $VPNKIT_INSTAL_PATH/wsl2/sbin/wsl-vpnkit ] && info "sakai135/wsl-vpnkit [OK]" || {
    info "Importing sakai135/wsl-vpnkit ..."
    mkdir -p $VPNKIT_INSTAL_PATH/wsl2/sbin
    wget https://raw.githubusercontent.com/sakai135/wsl-vpnkit/main/wsl-vpnkit \
        -O $VPNKIT_INSTAL_PATH/wsl2/sbin/wsl-vpnkit
}

[ -f $VPNKIT_INSTAL_PATH/win/bin/npiperelay-$NPIPERELAY_VERSION.exe ] && info "jstarks/npiperelay v$NPIPERELAY_VERSION [OK]" || {
    info "Importing jstarks/npiperelay v$NPIPERELAY_VERSION..."
    which unzip >/dev/null || { info "Installing unzip... "; sudo apt-get install -y unzip; }
    ( 
        cd /tmp
        wget https://github.com/jstarks/npiperelay/releases/download/v$NPIPERELAY_VERSION/npiperelay_windows_amd64.zip
        unzip npiperelay_windows_amd64.zip npiperelay.exe
        rm npiperelay_windows_amd64.zip
    )
    mkdir -p $VPNKIT_INSTAL_PATH/win/bin
    mv /tmp/npiperelay.exe $VPNKIT_INSTAL_PATH/win/bin/npiperelay-$NPIPERELAY_VERSION.exe
}

[ -f $VPNKIT_INSTAL_PATH/wsl2/init.d/dns-sync ] && info "matthiassb/dns-sync [OK]" || {
    info "Importing matthiassb DNS-SYNC service..."
    mkdir -p $VPNKIT_INSTAL_PATH/wsl2/init.d
    wget https://gist.githubusercontent.com/matthiassb/9c8162d2564777a70e3ae3cbee7d2e95/raw/56640fbb50ec870d2a2f62b1f188081c29d45337/dns-sync.sh \
        -O $VPNKIT_INSTAL_PATH/wsl2/init.d/dns-sync
}


# -- Install system --
step "Install WSL VPNKIT"

which socat >/dev/null || { info "Installing socat... "; sudo apt-get install -y socat; }

info "Setting /sbin/wsl-vpnkit-tap-vsockd ..."
sudo cp -f $VPNKIT_INSTAL_PATH/wsl2/sbin/vpnkit-tap-vsockd /sbin/wsl-vpnkit-tap-vsockd
sudo chmod +x /sbin/wsl-vpnkit-tap-vsockd
sudo chown root:root /sbin/wsl-vpnkit-tap-vsockd

info "Setting /sbin/wsl-vpnkit ..."
sudo cp -f $VPNKIT_INSTAL_PATH/wsl2/sbin/wsl-vpnkit /sbin/wsl-vpnkit
sudo sed -i 's#npiperelay.exe#/sbin/wsl-vpnkit-npiperelay#' /sbin/wsl-vpnkit
sudo sed -i 's# vpnkit-tap-vsockd# /sbin/wsl-vpnkit-tap-vsockd#' /sbin/wsl-vpnkit
sudo chmod +x /sbin/wsl-vpnkit
sudo chown root:root /sbin/wsl-vpnkit

info "Linking /sbin/wsl-npiperelay ..."
[ -L /sbin/wsl-vpnkit-npiperelay ] && sudo unlink /sbin/wsl-vpnkit-npiperelay
sudo ln -s $VPNKIT_INSTAL_PATH/win/bin/npiperelay-$NPIPERELAY_VERSION.exe /sbin/wsl-vpnkit-npiperelay

info "Setting wsl-vpnkit service ..."
sudo cp -f $VPNKIT_INSTAL_PATH/wsl2/init.d/wsl-vpnkit.service.template /etc/init.d/wsl-vpnkit
vpnkit_path="$(wslpath -m $VPNKIT_INSTAL_PATH/win/bin/vpnkit.exe)"
sudo sed -i 's@{{VPNKIT_PATH}}@'"$vpnkit_path"'@' /etc/init.d/wsl-vpnkit
sudo chmod +x /etc/init.d/wsl-vpnkit

info "Setting wsl-vpnkit sudoers permissions ..."
[ -f /etc/sudoers.d/wsl-vpnkit ] || {
    echo '%sudo   ALL=(ALL) NOPASSWD: /usr/sbin/service wsl-vpnkit *' | sudo tee /etc/sudoers.d/wsl-vpnkit
    sudo chmod 0440 /etc/sudoers.d/wsl-vpnkit
}

info "Autostart wsl-vpnkit in .bashrc ..."
grep -q  'wsl-vpnkit is not running' ~/.bashrc || \
tee -a ~/.bashrc <<EOL
# Autostart wsl-vpnkit
if service wsl-vpnkit status | grep -q 'wsl-vpnkit is not running'; then
   sudo service wsl-vpnkit start
fi
EOL

step "Install WSL SYN-SYNC"
info "Setting dns-sync service ..."
sudo cp -f $VPNKIT_INSTAL_PATH/wsl2/init.d/dns-sync /etc/init.d/dns-sync
sudo chmod +x /etc/init.d/dns-sync

info "Setting dns-sync sudoers permissions ..."
[ -f /etc/sudoers.d/dns-sync ] || {
    echo '%sudo   ALL=(ALL) NOPASSWD: /usr/sbin/service dns-sync *' | sudo tee /etc/sudoers.d/dns-sync
    sudo chmod 0440 /etc/sudoers.d/dns-sync
}

info "Disable WSL from generating and overwriting /etc/resolv.conf ..."
sudo tee /etc/wsl.conf <<EOL
[network]
generateResolvConf = false
EOL

info "Setting default resolv.conf"
[ -L /etc/resolv.conf ] && sudo unlink /etc/resolv.conf
sudo tee /etc/resolv.conf <<EOL
nameserver 1.1.1.1
EOL

info "Autostart dns-sync in .bashrc ..."
# https://gist.github.com/matthiassb/9c8162d2564777a70e3ae3cbee7d2e95#gistcomment-3464922
grep -q  'dns-sync is not running' ~/.bashrc || \
tee -a ~/.bashrc <<EOL
# Autostart dns-sync
if service dns-sync status | grep -q 'dns-sync is not running'; then
   sudo service dns-sync start
fi
EOL


# -- Start Services
step "Start WSL Services"

info "Starting dns-sync service..."
service dns-sync status | grep -q 'dns-sync is not running' || sudo service dns-sync stop
sudo service dns-sync start

info "Starting wsl-vpnkit service..."
service wsl-vpnkit status| grep -q 'wsl-vpnkit is not running' || sudo service wsl-vpnkit stop
sudo service wsl-vpnkit start
    


step "Done"
