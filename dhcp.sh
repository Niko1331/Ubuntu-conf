#!/bin/bash

set -e

read -p "Podaj najpierw nazwę karty LAN żebym mógł wpisać jej nazwę do pliku /etc/default/isc-dhcp-server: " LAN_IF
read -p "Podaj swój adres ip karty LAN: " LAN_IP
read -p "Podaj swoją podsieć czyli adres ip karty LAN ale dopisz 0 na końcu adresu: " SUBNET
read -p "Podaj swój zakres początkowy serwera DHCP: " RANGE_START
read -p "Podaj swój zakres końcowy serwera DHCP: " RANGE_END
read -p "Podaj adres serwera DNS: " DNS_IP

sudo bash -c "cat > /etc/default/isc-dhcp-server" << EOF
INTERFACESv4="$LAN_IF"
INTERFACESv6=""
EOF

echo "Zapisano nazwę karty LAN do pliku /etc/default/isc-dhcp-server"

sudo bash -c "cat > /etc/dhcp/dhcpd.conf" << EOF
default-lease-time 600;
max-lease-time 7200;

subnet $SUBNET netmask 255.255.255.0 {
	range $RANGE_START $RANGE_END;
	option routers $LAN_IP;
	option domain-name-servers $DNS_IP;
}

authoritative;
EOF

echo "Zapisano konfigurację do pliku /etc/dhcp/dhcpd.conf"

sudo systemctl restart isc-dhcp-server
sleep 1
sudo systemctl status isc-dhcp-server
