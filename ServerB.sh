# SIT tunnel to Main
ip tunnel add tun6to4_main mode sit remote 78.135.87.105 ttl 255
ip link set tun6to4_main up
ip addr add fc01::a/64 dev tun6to4_main

# GRE to Main
ip tunnel add gre_main mode ip6gre local fc01::a remote fc01::1
ip addr add 10.10.10.2/30 dev gre_main
ip link set gre_main up

# Optional route (e.g. default via Main)
ip route add default via 10.10.10.1 dev gre_main
