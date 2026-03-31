#!/bin/bash
set -e

echo "Wykrywanie karty WAN"

WAN_IF=$(ip -o route get 8.8.8.8 | awk '{print $5; exit}')

if [ -z  "$WAN_IF" ]; then
echo "Nie znaleziono karty WAN, sprawdź połączenie z internetem i spróbuj ponownie"
exit 1
fi
echo "Karta WAN = $WAN_IF"
