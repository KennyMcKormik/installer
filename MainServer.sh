# IPv6 tunnels from Main to A and B
ip tunnel add tun6to4_a mode sit remote 62.60.222.118 ttl 255
ip link set tun6to4_a up
ip addr add fc01::1/64 dev tun6to4_a

ip tunnel add tun6to4_b mode sit remote 185.126.203.76 ttl 255
ip link set tun6to4_b up
ip addr add fc01::2/64 dev tun6to4_b

# GRE to A
ip tunnel add gre_a mode ip6gre local fc01::1 remote fc01::a
ip addr add 10.10.10.1/30 dev gre_a
ip link set gre_a up

# GRE to B
ip tunnel add gre_b mode ip6gre local fc01::2 remote fc01::b
ip addr add 10.10.11.1/30 dev gre_b
ip link set gre_b up

# Enable forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
