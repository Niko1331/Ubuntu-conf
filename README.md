# Automatyczna konfiguracja serwera ubuntu

**Wszystkie pliki włącz jako root** czyli użyj

```bash
sudo bash nazwa.sh
```

# Kolejność uruchamiania

- ### Plik WAN.sh jest opcjonalny, jest tylko do sprawdzenia nazwy karty sieciowej która ma dostęp do internetu
- ### Najpierw uruchom dhcp.sh używając
```bash
sudo bash dhcp.sh
```
- ### Potem uruchom plik iptables.sh używając
```bash
sudo bash iptables.sh
```
- ### Potem sprawdź czy serwer DHCP działa poprawnie i czy jest internet na stacji roboczej

- ### Potem uruchom plik dns.sh używając
```bash
sudo bash dns.sh
```

### Plik iptables.sh wykryje nazwę karty WAN ale trzeba wpisać ręcznie nazwę karty LAN a potem użyje je w komendach iptables
### Plik dhcp.sh najpierw się spyta o:
- *Nazwę karty LAN żeby zrobić zmiany w pliku /etc/default/isc-dhcp-server i poinformuje że udało się zapisać to tego pliku*

- *Adres IP karty LAN*

- *Podsieć IP (Adres IP z zerem na końcu)*

- *Zakres początkowy i zakres końcowy do dzierżawy DHCP.*

- *Po tym wszystkim zapisze Adres IP, podsieć i oba zakresy do pliku /etc/dhcp/dhcpd.conf i poinformuje że udało się zapisać to tego pliku*

### Plik dns.sh robi cały serwer DNS i się spyta o:
- *Adres IP karty LAN i Adres IP stacji roboczej*

- *Domenę DNS, Domenę serwera, Domenę klienta*
