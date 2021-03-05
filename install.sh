#!/bin/bash

set -e

# -- VARS ---

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

GITHUB_REPO=${GITHUB_REPO:-https://github.com/mbl-35/wsl-vpnkit.git}    # Github source repo
VPNKIT_INSTAL_PATH=${VPNKIT_INSTAL_PATH:-/mnt/c/wsl-vpnkit}             # Windows installation (wsl path)
VPNKIT_PATH="$(wslpath -m $VPNKIT_INSTAL_PATH/win/bin/vpnkit.exe)"
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

info "Setting /sbin/vpnkit-tap-vsockd ..."
sudo cp -f $VPNKIT_INSTAL_PATH/wsl2/sbin/vpnkit-tap-vsockd /sbin/vpnkit-tap-vsockd
sudo chmod +x /sbin/vpnkit-tap-vsockd
sudo chown root:root /sbin/vpnkit-tap-vsockd

info "Setting /sbin/wsl-vpnkit ..."
sudo cp -f $VPNKIT_INSTAL_PATH/wsl2/sbin/wsl-vpnkit /sbin/wsl-vpnkit
sudo chmod +x /sbin/wsl-vpnkit
sudo chown root:root /sbin/wsl-vpnkit

info "Linking npiperelay ..."
[ -L /usr/local/bin/npiperelay.exe ] && sudo unlink /usr/local/bin/npiperelay.exe
sudo ln -s $VPNKIT_INSTAL_PATH/npiperelay.exe /usr/local/bin/npiperelay.exe

info "Setting wsl-vpnkit service ..."
sudo cp -f $VPNKIT_INSTAL_PATH/wsl2/init.d/wsl-vpnkit.service.template /etc/init.d/wsl-vpnkit
sudo sed -i 's@{{VPNKIT_PATH}}@'"$VPNKIT_PATH"'@' /etc/init.d/wsl-vpnkit
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
chmod +x /etc/init.d/dns-sync

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
service dns-sync status| grep -q 'dns-sync is not running' && \
    sudo service dns-sync start || \
    sudo service dns-sync restart

info "Starting wsl-vpnkit service..."
service wsl-vpnkit status| grep -q 'wsl-vpnkit is not running' && \
    sudo service wsl-vpnkit start || \
    sudo service wsl-vpnkit restart
step "Done"


# VPNKIT_PATH=$VPNKIT_INSTAL_PATH/vpnkit.exe



# info "Install dependencies"
# sudo apt install -y unzip socat

# [ -d "$VPNKIT_INSTAL_PATH" ] || {
#     info "Create windows install dir: $VPNKIT_INSTAL_PATH"
#     mkdir -p "$VPNKIT_INSTAL_PATH"
# }

# [ -f "$VPNKIT_PATH" ]  || {
#     [ -f "$DIR/bin/vpnkit.exe" ] && {
#         info "Install vpnkit.exe from local git repo..."
#         cp $DIR/bin/vpnkit.exe "$VPNKIT_PATH"
#     } || {
#         info "Install vpnkit.exe..."
#         wget $GITHUB_RAW_BASE/bin/vpnkit.exe -o "$VPNKIT_PATH"
#     }
# } 

# [ -f /sbin/vpnkit-tap-vsockd] || {
#     [ -f "$DIR/bin/vpnkit-tap-vsockd" ] && {
#         info "Install vpnkit-tap-vsockd from local git repo..."
#         sudo cp "$DIR/bin/vpnkit-tap-vsockd" /sbin/vpnkit-tap-vsockd
#     } || {
#         info "Install vpnkit-tap-vsockd..."
#         wget $GITHUB_RAW_BASE/bin/vpnkit-tap-vsockd
#         sudo mv vpnkit-tap-vsockd /sbin/vpnkit-tap-vsockd
#     }
#     chmod +x /sbin/vpnkit-tap-vsockd && \    
#     sudo chown root:root /sbin/vpnkit-tap-vsockd
# }

# [ -f /sbin/wsl-vpnkit ] || {
#     info "Install sakai135 wsl-script..."
#     wget https://raw.githubusercontent.com/sakai135/wsl-vpnkit/main/wsl-vpnkit && \
#         chmod +x wsl-vpnkit && \
#         sudo mv vpnkit-tap-vsockd /sbin/wsl-vpnkit && \
#         sudo chown root:root /sbin/wsl-vpnkit
# }

# [ -f /usr/local/bin/npiperelay.exe ] || {
#     info "Install npiperelay.exe..."
#     wget https://github.com/jstarks/npiperelay/releases/download/v0.1.0/npiperelay_windows_amd64.zip && \
#     unzip npiperelay_windows_amd64.zip npiperelay.exe && \
#     rm npiperelay_windows_amd64.zip && \
#     mv npiperelay.exe $VPNKIT_INSTAL_PATH/
#     sudo ln -s $VPNKIT_INSTAL_PATH/npiperelay.exe /usr/local/bin/npiperelay.exe
# }


# [ -f /etc/init.d/dns-sync ] || {
#     info "Install matthiassb DNS-SYNC service..."
#     wget https://gist.githubusercontent.com/matthiassb/9c8162d2564777a70e3ae3cbee7d2e95/raw/56640fbb50ec870d2a2f62b1f188081c29d45337/dns-sync.sh
#     chmod +x dns-sync.sh
#     sudo mv dns-sync.sh /etc/init.d/dns-sync
#     sudo unlink /etc/resolv.conf
#     sudo service dns-sync start
# }

# [ -f /etc/sudoers.d/dns-sync ] || {
#     info "Allow DNS-SYNC service control to anyone..."
#     info '%sudo   ALL=(ALL) NOPASSWD: /usr/sbin/service dns-sync *' | sudo tee /etc/sudoers.d/dns-sync
#     sudo chmod 0440 /etc/sudoers.d/dns-sync
# }

# # Autostart services (https://gist.github.com/matthiassb/9c8162d2564777a70e3ae3cbee7d2e95#gistcomment-3464922)
# => info dans le .bashrc de l'utilisateur
# if service dns-sync status| grep -q 'dns-sync is not running'; then
#    sudo service dns-sync start
# fi

# => créer un service pour wsl-vpnkit
# => permettre à tous de controler ce service

# info "Disable WSL from generating and overwriting /etc/resolv.conf"
# sudo tee /etc/wsl.conf <<EOL
# [network]
# generateResolvConf = false
# EOL
