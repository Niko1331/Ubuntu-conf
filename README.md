
							**Automatyczna konfiguracja serwera ubuntu**

Wszystkie pliki włącz jako root czyli użyj sudo bash nazwapliku.sh

Plik WAN.sh i LAN.sh są po to żeby wykryć która karta to WAN a która to LAN, 
Plik iptables.sh wykryje nazwę karty WAN ale trzeba wpisać ręcznie nazwę karty LAN a potem użyje je w komendach iptables,
Plik dhcp.sh najpierw się spyta o:
- Nazwę karty LAN żeby zrobić zmiany w pliku /etc/default/isc-dhcp-server
- Adres IP karty LAN
- Podsieć IP (Adres IP z zerem na końcu)
- Zakres początkowy i zakres końcowy do dzierżawy DHCP
Po tym wszystkim zapisze Adres IP, podsieć i oba zakresy do pliku /etc/dhcp/dhcpd.conf
