#!/bin/sh

# load configuration
. /mnt/c/wsl-tools/vpnkit/wsl-vpnkit/wsl-vpnkit.conf

IP_ROUTE=
RESOLV_CONF=

relay () {
    local OS_CODENAME="$(lsb_release --codename | cut -f2)"
    local OPTIONS="fork,umask=007"

    # option umask not working on ubuntu-14...
    case "$OS_CODENAME" in
        trusty) OPTIONS="fork" ;;
    esac

    socat UNIX-LISTEN:$SOCKET_PATH,$OPTIONS EXEC:"$VPNKIT_NPIPERELAY_PATH -ep -s $PIPE_PATH",nofork
}

vpnkit () {
    WIN_PIPE_PATH=$(echo $PIPE_PATH | sed -e 's:/:\\:g')
    CMD='"$VPNKIT_PATH" \
        --ethernet $WIN_PIPE_PATH \
        --listen-backlog $VPNKIT_BACKLOG \
        --gateway-ip $VPNKIT_GATEWAY_IP \
        --host-ip $VPNKIT_HOST_IP \
        --lowest-ip $VPNKIT_LOWEST_IP \
        --highest-ip $VPNKIT_HIGHEST_IP \
    '
    if [ "$VPNKIT_HTTP_CONFIG" ]; then
        CMD="$CMD"' --http "$VPNKIT_HTTP_CONFIG"'
    fi
    if [ "$VPNKIT_GATEWAY_FORWARD_CONFIG" ]; then
        CMD="$CMD"' --gateway-forwards "$VPNKIT_GATEWAY_FORWARD_CONFIG"'
    fi
    if [ "$VPNKIT_DEBUG" ]; then
        CMD="$CMD"' --debug'
    fi
    eval "$CMD"
}

tap () {
    /mnt/c/wsl-tools/vpnkit/docker-desktop/vpnkit-tap-vsockd --tap $TAP_NAME --path $SOCKET_PATH
}

ipconfig () {
    ip a add $VPNKIT_LOWEST_IP/255.255.255.0 dev $TAP_NAME
    ip link set dev $TAP_NAME up
    IP_ROUTE=$(ip route | grep default)
    ip route del $IP_ROUTE
    ip route add default via $VPNKIT_GATEWAY_IP dev $TAP_NAME
    RESOLV_CONF=$(cat /etc/resolv.conf)
    echo "nameserver $VPNKIT_GATEWAY_IP" > /etc/resolv.conf
}

close () {
    ip link set dev $TAP_NAME down
    ip route add 
    echo "$RESOLV_CONF" > /etc/resolv.conf
    # prevent wsl-vpnkit.sock: Address already in use
    [ -S $SOCKET_PATH ] && rm -f $SOCKET_PATH
    kill 0
}

if [ ${EUID:-$(id -u)} -ne 0 ]; then
    echo "Please run this script as root"
    exit 1
fi

relay &
sleep 3
vpnkit &
sleep 3
tap &
sleep 3
ipconfig

trap close exit
trap exit int term
wait
