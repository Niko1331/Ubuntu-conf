#!/bin/bash

set -e

##### Początek DHCP

WAN_IF=$(ip -o route get 8.8.8.8 | awk '{print $5}')
if [ -z $WAN_IF ]; then
echo "Nie znaleziono karty WAN, sprawdź połączenie z internetem i spróbuj ponownie"
exit 1
fi
echo "Karta WAN = $WAN_IF"
read -p "Podaj najpierw nazwę karty LAN żebym mógł wpisać jej nazwę do pliku /etc/default/isc-dhcp-server: " LAN_IF
read -p "Podaj swój adres ip karty LAN: " LAN_IP
read -p "Podaj adres serwera DNS: " DNS_IP
SUBNET=$(echo $LAN_IP | awk -F'.' '{print $1"."$2"."$3".0"}')
RANGE_START=$(echo $LAN_IP | awk -F'.' '{print $1"."$2"."$3".100"}')
RANGE_END=$(echo $LAN_IP | awk -F'.' '{print $1"."$2"."$3".150"}')

sudo bash -c "cat > /etc/default/isc-dhcp-server" << EOF
INTERFACESv4="$LAN_IF"
INTERFACESv6=""
EOF
echo " "
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
echo " "
sudo systemctl restart isc-dhcp-server
sleep 1
sudo systemctl status isc-dhcp-server

##### Koniec DHCP

echo "DHCP zrobione, teraz robię NAT i routing"

#### Początek iptables, NAT i routingu

echo "Czyszczenie starych zasad i łańcuchów"
sleep 1
sudo iptables --flush
sudo iptables --table nat --flush
sudo iptables --table nat --delete-chain
sudo iptables --delete-chain
echo "Wyczyszczono! Teraz stosowanie nowych zasad"
sleep 1
sudo iptables --table nat --append POSTROUTING --out-interface $WAN_IF -j MASQUERADE
sudo iptables --append FORWARD --in-interface $LAN_IF -j ACCEPT
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -p /etc/sysctl.conf
sudo iptables-save
echo "Zasady zastosowane! Instaluje teraz pakiet żeby konfiguracja była na stałe"
sleep 3
#instalacja pakietu iptables-persistent żeby konfiguracja była na stałe
sudo apt install iptables-persistent -y

##### Koniec iptables, NAT i routingu
echo " "
echo "NAT i routing zrobiony, teraz robię DNS"

##### Początek DNS

# instalacja pakietów DNS

echo "Instaluje pakiety związane z serwerem DNS"

sudo apt install -y bind9 bind9utils bind9-doc dnsutils
echo " "
read -p "Podaj mi nazwę twojej domeny (na przykład damian.local): " DOMAIN
read -p "Podaj mi nazwę domeny twojego serwera (na przykład serwer.damian.local): " SERVER_DOMAIN
read -p "Podaj mi nazwę domeny klienta (na przykład klient1.damian.local, wymagane jest wpisanie na początku klient1): " CLIENT_DOMAIN
read -p "Podaj mi adres IP stacji roboczej: " CLIENT_IP
ARPA=$(echo $LAN_IP | awk -F'.' '{print $3"."$2"."$1".in-addr.arpa"}')
SERVER_ONLY=$(echo $SERVER_DOMAIN | awk -F'.' '{print $1}')
CLIENT=$(echo $CLIENT_DOMAIN | awk -F'.' '{print $1}')
SHOST=$(echo $LAN_IP | awk -F'.' '{print $4}')
KHOST=$(echo $CLIENT_IP | awk -F'.' '{print $4}')

sudo touch /etc/bind/forward.$DOMAIN.db
sudo touch /etc/bind/reverse.$DOMAIN.db

echo "Dodaję twój adres IP do pliku /etc/bind/named.conf.options"
sleep 1
sudo bash -c "cat > /etc/bind/named.conf.options" << EOF
options {
	directory "/var/cache/bind";
	forwarders {
	        $LAN_IP;
	};
	dnssec-validation auto;

	listen-on-v6 { any; };
};
EOF

echo "Zapisano dane do pliku /etc/bind/named.conf.options!"
echo "Teraz zapisuję dane w pliku /etc/bind/named.conf.local"
echo " "
sleep 1
sudo bash -c "cat > /etc/bind/named.conf.local" << EOF
zone "$DOMAIN" IN {
	type master;
	file "/etc/bind/forward.$DOMAIN.db";

	allow-update {none;};

	allow-transfer {$LAN_IP;};
	also-notify {$LAN_IP;};
};

zone "$ARPA" IN {
	type master;
	file "/etc/bind/reverse.$DOMAIN.db";

	allow-update {none;};
	allow-transfer {$LAN_IP;};
	also-notify {$LAN_IP;};
};
EOF
echo "Zapisano dane do pliku /etc/bind/named.conf.local!"
echo "Teraz zapisuję dane do pliku forward.$DOMAIN.db"
echo " "
sudo bash -c "cat > /etc/bind/forward.$DOMAIN.db" << EOF
;
; BIND data file for local loopback interface
;
\$TTL	604800
@	IN	SOA	$SERVER_DOMAIN. root.$SERVER_DOMAIN. (
			      3		; serial
			 604800		; refresh
			  86400		; retry
			2419200		; expire
			 604800 )	; negative cache TTL
;
@	IN	NS	localhost.
@	IN	A	127.0.0.1
@	IN	AAAA	::1

;Informacje o serwerach DNS
@	IN	NS	$SERVER_DOMAIN.

;Adres IP serwera DNS
$SERVER_ONLY	IN	A	$LAN_IP

;Rekordy A - Domena na adres IP
$CLIENT	IN	A	$CLIENT_IP

;Rekordy CNAME - Domena na domenę
alKli1	IN	CNAME	$CLIENT_DOMAIN.

EOF

echo "Zapisano dane do pliku /etc/bind/forward.$DOMAIN.db!"
echo "Teraz zapisuję dane do pliku reverse.$DOMAIN.db"
echo " "
sudo bash -c "cat > /etc/bind/reverse.$DOMAIN.db" << EOF
; BIND reverse data file for local loopback interface
\$TTL	604800
@	IN	SOA	$DOMAIN. root.$DOMAIN. (
			    2	; serial
		       604800	; refresh
			86400	; retry
		      2419200	; expire
		       604800 ) ; negative cache TTL
;
@	IN	NS	localhost.
1.0.0	IN	PTR	localhost.

;Informacje o serwerach DNS
@	IN	NS	$SERVER_DOMAIN.
$SERVER_ONLY	IN	A	$LAN_IP

;Przeszukiwanie wsteczne dla serwera DNS
$SHOST	IN	PTR	$SERVER_DOMAIN.

;Rekordy PTR - Adres IP na domenę
$KHOST	IN	PTR	$CLIENT_DOMAIN.

EOF

echo "Zapisano dane do pliku /etc/bind/reverse.$DOMAIN.db!"
echo "Robię zmiany w /etc/resolv.conf"
echo " "
sudo bash -c "cat > /etc/resolv.conf" << EOF

nameserver $LAN_IP
options edns0 trust-ad
search $DOMAIN
EOF

echo "Zapisano dane do pliku /etc/resolv.conf!"
echo "Teraz sprawdzam konfigurację serwera DNS"
echo " "
sudo named-checkconf
ZONEOK=$(sudo named-checkzone $DOMAIN /etc/bind/forward.$DOMAIN.db | tail -1)
if [[ "$ZONEOK" != *"OK" ]]; then
echo "Konfiguracja nie działa i się nie powiodła, wychodzenie ze skryptu"
exit 1
else
echo "Pierwsza konfiguracja działa, przechodzę do następnej"
echo " "
fi
sleep 1
ARPAZONE=$(sudo named-checkzone $ARPA /etc/bind/reverse.$DOMAIN.db | tail -1)
if [[ "$ARPAZONE" != *"OK"* ]]; then
echo "Konfiguracja nie działa dobrze i się nie powiodła, wychodzenie ze skryptu"
exit 1
else
echo "Wszystkie konfiguracje zadziałały! Cały serwer DNS zrobiony, zrób jeszcze komendę dig $DOMAIN , nslookup $DOMAIN , dig $SERVER_DOMAIN i nslookup $SERVER_DOMAIN żeby sprawdzić czy działa"
echo " "
fi

echo "Wszystko zrobione! DHCP, NAT i routing, DNS też"
##### Koniec DNS
