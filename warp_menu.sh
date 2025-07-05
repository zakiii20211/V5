#!/bin/bash
clear
function udepe(){
clear
echo 
echo -e "\e[0m udp stup install....\e[0m"
sleep 0.7
echo -e "\e[0m Succes...\e[0m"
sleep 0.7
echo
echo -e "\e[0m By khaiVPN..\e[0m"
sleep 0.7
echo
clear
cd
rm -rf /root/udp
mkdir -p /root/udp
# change to time GMT+8
echo "change to time GMT+8"
ln -fs /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime

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
