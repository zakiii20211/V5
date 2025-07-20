#!/bin/bash

# =================================================================
# Skrip untuk Menghidupkan/Mematikan AdGuard DNS
# Menggunakan systemd-resolved (untuk Linux moden)
#
# Penggunaan:
# sudo ./adguard-toggle.sh on      -> Untuk mengaktifkan AdGuard DNS
# sudo ./adguard-toggle.sh off     -> Untuk mematikan AdGuard DNS
# sudo ./adguard-toggle.sh status  -> Untuk menyemak status semasa
# =================================================================

# ---- Konfigurasi ----
ADGUARD_DNS_1="94.140.14.14"
ADGUARD_DNS_2="94.140.15.15"
CONFIG_FILE="/etc/systemd/resolved.conf"
BACKUP_FILE="/etc/systemd/resolved.conf.bak.adguard-toggle"

# ---- Warna untuk output ----
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Fungsi ---

# Fungsi untuk menunjukkan cara guna skrip
show_usage() {
    echo "Penggunaan: sudo $0 {on|off|status}"
    echo "  ${GREEN}on${NC}     : Aktifkan AdGuard DNS untuk sekat iklan."
    echo "  ${RED}off${NC}    : Matikan AdGuard DNS (kembali ke tetapan automatik/DHCP)."
    echo "  ${YELLOW}status${NC} : Semak status DNS semasa."
    exit 1
}

# Fungsi untuk menyemak status AdGuard DNS
check_status() {
    echo -e "${YELLOW}Menyemak status...${NC}"
    # Semak jika baris DNS AdGuard wujud dan tidak dikomen dalam fail konfigurasi
    if grep -q "^DNS=$ADGUARD_DNS_1 $ADGUARD_DNS_2" "$CONFIG_FILE"; then
        echo -e "Status Konfigurasi: ${GREEN}AdGuard DNS sedang AKTIF.${NC}"
    else
        echo -e "Status Konfigurasi: ${RED}AdGuard DNS sedang TIDAK AKTIF.${NC}"
    fi

    echo "---"
    echo "Server DNS yang sedang digunakan oleh sistem:"
    # Guna resolvectl untuk melihat DNS semasa
    resolvectl status | grep "DNS Server" | sed "s/DNS Server/ ->/g"
    echo ""
}

# Fungsi untuk mengaktifkan AdGuard DNS
enable_adguard() {
    echo "Mengaktifkan AdGuard DNS..."
    # Semak jika sudah aktif
    if grep -q "^DNS=$ADGUARD_DNS_1 $ADGUARD_DNS_2" "$CONFIG_FILE"; then
        echo -e "${GREEN}AdGuard DNS sudah pun aktif. Tiada perubahan dibuat.${NC}"
        exit 0
    fi

    # Buat sandaran fail asal jika belum ada
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "Membuat sandaran (backup) konfigurasi asal di $BACKUP_FILE..."
        cp "$CONFIG_FILE" "$BACKUP_FILE"
    fi

    # Guna sed untuk mengubah suai fail. Lebih selamat daripada menulis semula keseluruhan fail.
    # Jika baris DNS wujud tapi dikomen, buang komen.
    if grep -q "^#DNS=" "$CONFIG_FILE"; then
        sed -i "s/^#DNS=.*/DNS=$ADGUARD_DNS_1 $ADGUARD_DNS_2/" "$CONFIG_FILE"
    # Jika tiada baris DNS, tambahkannya di bawah [Resolve]
    else
        sed -i "/\[Resolve\]/a DNS=$ADGUARD_DNS_1 $ADGUARD_DNS_2" "$CONFIG_FILE"
    fi

    # Mulakan semula servis
    echo "Memulakan semula perkhidmatan systemd-resolved..."
    systemctl restart systemd-resolved
    sleep 1 # Beri masa untuk servis dimulakan semula
    
    echo -e "${GREEN}Berjaya! AdGuard DNS telah diaktifkan.${NC}"
    check_status
}

# Fungsi untuk mematikan AdGuard DNS
disable_adguard() {
    echo "Mematikan AdGuard DNS..."
    # Semak jika ia memang aktif
    if ! grep -q "^DNS=$ADGUARD_DNS_1 $ADGUARD_DNS_2" "$CONFIG_FILE"; then
        echo -e "${RED}AdGuard DNS sememangnya tidak aktif. Tiada perubahan dibuat.${NC}"
        exit 0
    fi

    # Komenkan baris DNS untuk mematikan tetapan manual
    # Ini akan menyebabkan systemd-resolved menggunakan DNS dari DHCP
    echo "Mengembalikan tetapan DNS kepada automatik..."
    sed -i "s/^DNS=$ADGUARD_DNS_1 $ADGUARD_DNS_2/#DNS=/" "$CONFIG_FILE"

    # Mulakan semula servis
    echo "Memulakan semula perkhidmatan systemd-resolved..."
    systemctl restart systemd-resolved
    sleep 1

    echo -e "${RED}Berjaya! AdGuard DNS telah dimatikan.${NC}"
    check_status
}

# --- Logik Utama ---

# 1. Pastikan skrip dijalankan sebagai root (sudo)
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Ralat: Skrip ini perlu dijalankan sebagai root. Sila guna 'sudo'.${NC}"
  show_usage
fi

# 2. Pastikan ada argumen diberikan
if [ -z "$1" ]; then
    echo -e "${RED}Ralat: Sila berikan arahan (on, off, atau status).${NC}"
    show_usage
fi

# 3. Laksanakan fungsi berdasarkan argumen
case "$1" in
    on)
        enable_adguard
        ;;
    off)
        disable_adguard
        ;;
    status)
        check_status
        ;;
    *)
        echo -e "${RED}Ralat: Argumen tidak sah '$1'.${NC}"
        show_usage
        ;;
esac

exit 0