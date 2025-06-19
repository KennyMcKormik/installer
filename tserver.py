from scapy.all import *
import socket

def handle_icmp_packet(packet):
    if not packet.haslayer(ICMP):
        return

    icmp = packet[ICMP]
    if icmp.type != 8:  # Echo Request
        return

    payload = bytes(icmp.payload)

    # Forward to real TCP server (e.g., google.com:80)
    try:
        with socket.create_connection(("127.0.0.1", 443), timeout=2) as s:
            s.sendall(payload)
            response = s.recv(1024)
    except Exception as e:
        response = b"Error: " + str(e).encode()

    # Send ICMP Echo Reply
    reply = IP(dst=packet[IP].src, src=packet[IP].dst)/ICMP(type=0, id=icmp.id, seq=icmp.seq)/Raw(load=response)
    send(reply, verbose=False)
    print(f"ICMP reply sent to {packet[IP].src}")

print("ICMP Tunnel Server started...")
sniff(filter="icmp", prn=handle_icmp_packet)
