#!/bin/bash

# Skrip Pengurusan WARP dengan Menu Ringkas
# Dicipta untuk Debian/Ubuntu

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Pastikan skrip dijalankan sebagai root
if [ "$(id -u)" -ne 0 ]; then
   echo -e "${RED}Skrip ini perlu dijalankan sebagai root. Sila guna 'sudo ./warp_menu.sh'${NC}" 
   exit 1
fi

# Fungsi untuk memasang WARP
install_warp() {
    echo -e "${YELLOW}Menyemak prasyarat...${NC}"
    apt-get update > /dev/null 2>&1
    apt-get install -y curl gpg lsb-release > /dev/null 2>&1
    
    echo -e "${YELLOW}Memasang Cloudflare WARP...${NC}"
    curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor -o /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list
    apt-get update > /dev/null 2>&1
    apt-get install -y cloudflare-warp > /dev/null 2>&1
    
    echo -e "${GREEN}Pemasangan WARP selesai!${NC}"
    echo -e "${YELLOW}Mendaftar WARP (sila terima terma perkhidmatan)...${NC}"
    warp-cli --accept-tos register
    echo -e "${GREEN}WARP telah didaftarkan. Anda kini boleh menghidupkannya.${NC}"
}

# Fungsi untuk menghidupkan WARP
turn_on_warp() {
    echo -e "${YELLOW}Menghidupkan WARP...${NC}"
    warp-cli --accept-tos connect
    warp-cli set-mode proxy
    echo -e "${GREEN}WARP telah dihidupkan (ON) dengan mod proksi.${NC}"
}

# Fungsi untuk mematikan WARP
turn_off_warp() {
    echo -e "${YELLOW}Mematikan WARP...${NC}"
    warp-cli disconnect
    echo -e "${RED}WARP telah dimatikan (OFF).${NC}"
}

# Fungsi untuk menyemak status
check_status() {
    echo -e "${CYAN}--- Status Semasa WARP ---${NC}"
    warp-cli status
}

# Menu utama
while true; do
    echo -e "\n${CYAN}--- Menu Pengurusan WARP IPv6 ---${NC}"
    echo "1. Pasang / Install WARP (Kali pertama sahaja)"
    echo -e "2. ${GREEN}Hidupkan WARP (ON)${NC}"
    echo -e "3. ${RED}Matikan WARP (OFF)${NC}"
    echo "4. Semak Status"
    echo "5. Keluar"
    echo -n "Sila masukkan pilihan anda [1-5]: "
    read choice

    case $choice in
        1)
            install_warp
            ;;
        2)
            turn_on_warp
            ;;
        3)
            turn_off_warp
            ;;
        4)
            check_status
            ;;
        5)
            echo "Keluar dari skrip."
            exit 0
            ;;
        *)
            echo -e "${RED}Pilihan tidak sah. Sila cuba lagi.${NC}"
            ;;
    esac
done
