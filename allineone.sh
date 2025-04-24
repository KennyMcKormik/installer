#!/bin/bash

CONFIG_FILE="/root/tunnel_config.txt"
LOCAL_SCRIPT="/root/tunnel.local"

clear  # پاک کردن صفحه قبل از اجرا

function get_local_ipv4 {
    hostname -I | awk '{print $1}'  # گرفتن اولین آی‌پی ورژن 4 سرور
}

function setup_tunnel_iran {
    local_ip=$(get_local_ipv4)
    echo -e "Enter your Iran IPv4 (this server's IP) [\e[32m$local_ip\e[0m]: "
    read -e -i "$local_ip" ipiran  # مقدار پیش‌فرض سبز رنگ و قابل ویرایش
    read -p "Enter your Kharej IPv4 (remote server's IP): " ipkharej
    
    echo "Iran Server - Configuring tunnel..."
    echo "ipiran=$ipiran" > $CONFIG_FILE
    echo "ipkharej=$ipkharej" >> $CONFIG_FILE
    echo "server_type=Iran" >> $CONFIG_FILE

    cat > $LOCAL_SCRIPT <<EOL
#!/bin/bash
ip tunnel add tun6to4 mode sit ttl 254 remote $ipkharej
ip link set dev tun6to4 up
ip addr add fc01::2/64 dev tun6to4
sleep 3
ip tunnel add gre1 mode ip6gre remote fc01::1 local fc01::2
ip link set gre1 up
ip addr add 10.10.5.2/30 dev gre1
sleep 3
ip route add default via 10.10.5.1 table 4
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD  -j ACCEPT
sudo sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1
echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
sysctl -w net.ipv6.conf.tun6to4.forwarding=1
sysctl -w net.ipv6.conf.gre1.forwarding=1
ip6tables -F
ip6tables -X
ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT
sysctl -p
EOL
    chmod +x $LOCAL_SCRIPT
    setup_cron
    bash $LOCAL_SCRIPT  # اجرای اولیه پس از پیکربندی
}

function setup_tunnel_kharej {
    read -p "Enter your Iran IPv4 (remote server's IP): " ipiran
    
    echo "Kharej Server - Configuring tunnel..."
    echo "ipiran=$ipiran" > $CONFIG_FILE
    echo "server_type=Kharej" >> $CONFIG_FILE

    cat > $LOCAL_SCRIPT <<EOL
#!/bin/bash
ip tunnel add tun6to4 mode sit ttl 254 remote $ipiran
ip link set dev tun6to4 up
ip addr add fc01::1/64 dev tun6to4
sleep 3
ip tunnel add gre1 mode ip6gre remote fc01::2 local fc01::1
ip link set gre1 up
ip addr add 10.10.5.1/30 dev gre1
sleep 3
ip route add default via 10.10.5.2 table 4
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD  -j ACCEPT
sudo sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1
echo "net.ipv4.ip_forward=1" > /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
sysctl -w net.ipv6.conf.tun6to4.forwarding=1
sysctl -w net.ipv6.conf.gre1.forwarding=1
ip6tables -F
ip6tables -X
ip6tables -P INPUT ACCEPT
ip6tables -P FORWARD ACCEPT
ip6tables -P OUTPUT ACCEPT
sysctl -p
EOL
    chmod +x $LOCAL_SCRIPT
    setup_cron
    bash $LOCAL_SCRIPT  # اجرای اولیه پس از پیکربندی
}

function setup_cron {
    crontab -l | grep -v "$LOCAL_SCRIPT" | crontab -
    (crontab -l 2>/dev/null; echo "@reboot $LOCAL_SCRIPT") | crontab -
    echo "Tunnel setup complete. It will restart automatically after reboot."
}

function remove_tunnel {
    echo "Removing tunnel setup..."
    rm -f $CONFIG_FILE $LOCAL_SCRIPT
    crontab -l | grep -v "$LOCAL_SCRIPT" | crontab -
    echo "Tunnel removed."
    reboot  # ری‌استارت سرور بعد از حذف تونل
}

if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    echo "Detected existing configuration ($server_type Server)"
    echo "1. Remove Tunnel"
    read -p "Choose an option: " option
    case $option in
        1) remove_tunnel ;;
        *) echo "Invalid option" ;;
    esac
    exit 0
fi

echo "Which server are you on?"
echo "1. Iran"
echo "2. Kharej"
read -p "Select: " server_choice

case $server_choice in
    1) setup_tunnel_iran ;;
    2) setup_tunnel_kharej ;;
    *) echo "Invalid selection" ;;
esac
