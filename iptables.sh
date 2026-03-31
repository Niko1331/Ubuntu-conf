#!/bin/bash

set -e
# wykrywanie karty WAN

echo "Wykrywanie karty WAN"
WAN_IF=$(ip -o route get 8.8.8.8 | awk '{print $5; exit}')

if [ -z  "$WAN_IF" ]; then
echo "Nie znaleziono karty WAN, sprawdź połączenie z internetem i spróbuj ponownie"
exit 1
fi
echo "Karta WAN = $WAN_IF"

#wykrywanie karty LAN (po prostu user input)
read -p "Potrzebuje tylko nazwy karty LAN więc podaj nazwę tej karty: " LAN_IF
echo "Karta LAN = $LAN_IF"

# reszta tych komend iptables

sudo iptables --flush
sudo iptables --table nat --flush
sudo iptables --table nat --delete-chain
sudo iptables --delete-chain
sleep 1
sudo iptables --table nat --append POSTROUTING --out-interface $WAN_IF -j MASQUERADE
sudo iptables --append FORWARD --in-interface $LAN_IF -j ACCEPT
sudo iptables-save
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -p
#instalacja pakietu iptables-persistent żeby konfiguracja była na stałę
sudo apt install iptables-persistent -y


