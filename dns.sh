#!/bin/bash

# instalacja pakietów

echo "Instaluje pakiety związane z serwerem DNS"
sudo apt install -y bind9 bind9utils bind9-doc dnsutils

read -p "Podaj mi adres IP twojego serwera (Adres IP karty LAN): " LAN_IP
read -p "Podaj mi nazwę twojej domeny (na przykład damian.local): " DOMAIN
read -p "Podaj mi nazwę domeny twojego serwera (na przykład serwer.damian.local): " SERVER_DOMAIN
read -p "Podaj mi nazwę domeny klienta (na przykład klient1.damian.local, wymagane jest wpisanie na początku klient1): " CLIENT_DOMAIN
read -p "Podaj mi adres IP stacji roboczej: " CLIENT_IP

ARPA=$(echo $LAN_IP | awk -F'.' '{print $3"."$2"."$1".in-addr.arpa"}')
SERVER_ONLY=$(echo $SERVER_DOMAIN | awk -F'.' '{print $1}')
CLIENT=$(echo $CLIENT_DOMAIN | awk -F'.' '{print $1}')
SHOST=$(echo $LAN_IP | awk -F'.' '{print $4}')
KHOST=$(echo $CLIENT_IP | awk -F'.' '{print $4}')

sudo cp /etc/bind/db.local /etc/bind/forward.$DOMAIN.db
sudo cp /etc/bind/db.127 /etc/bind/reverse.$DOMAIN.db

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
sleep 1
sudo bash -c "cat > /etc/bind/named.conf.local" << EOF
zone "$DOMAIN" IN {
	type master;
	file "/etc/bind/forward.$DOMAIN.db";

	allow-update {none;};
	allow-transfer {$LAN_IP;};
	allow-notify {$LAN_IP;};
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
sudo bash -c "cat > /etc/bind/forward.$DOMAIN.db" << EOF
; BIND data file for local loopback interace
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
sudo named-checkconf
sleep 1
sudo named-checkzone $DOMAIN forward.$DOMAIN.db
sleep 1
sudo named-checkzone $ARPA reverse.$DOMAIN.db

echo "Robię zmiany w /etc/resolv.conf"
sudo bash -c "cat > /etc/resolv.conf" << EOF

nameserver $LAN_IP
options edns0 trust-ad
search $DOMAIN
EOF

echo "Zapisano dane do pliku /etc/resolv.conf! Cały DNS zrobiony"
