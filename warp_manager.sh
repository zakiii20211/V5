#!/bin/bash

# ======================================================================================
#  PENGELOLA WARP & BYPASS MIKROTIK - "ALL-IN-ONE" EDITION
# ======================================================================================
#  Versi: 4.0
#  Fitur:
#  - Menu interaktif berbasis nomor.
#  - Instalasi & Uninstalasi WARP.
#  - Mengatur WARP sebagai default gateway (IPv4/IPv6/Dual).
#  - Manajemen bypass domain (tambah/hapus/lihat).
#  - Setup "Zero-Edit" dengan penyimpanan konfigurasi.
# ======================================================================================

# --- Variabel & Konfigurasi ---
CONFIG_FILE="warp_manager.conf"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Fungsi-fungsi Inti (Setup, Load, SSH) ---

# Cek dependensi
check_dependencies() {
    for cmd in sshpass wgcf jq; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}KESALAHAN: Program '$cmd' tidak ditemukan. Harap instal terlebih dahulu.${NC}"
            exit 1
        fi
    done
}

# Setup pertama kali
run_first_time_setup() {
    echo -e "${CYAN}======================================================${NC}"
    echo -e "${CYAN} Selamat Datang! Konfigurasi Awal Diperlukan. ${NC}"
    echo -e "${CYAN}======================================================${NC}"
    read -p "128.199.187.139: " MIKROTIK_IP
    read -p "khai: " MIKROTIK_USER
    read -s -p "khai767Rul123: " MIKROTIK_PASS
    echo ""

    echo -e "\n${YELLOW}--> Menjalankan 'wgcf' untuk membuat profil WARP...${NC}"
    if wgcf register --accept-tos && wgcf generate; then
        echo -e "${GREEN}Profil WARP berhasil dibuat.${NC}"
    else
        echo -e "${RED}KESALAHAN: Gagal membuat profil WARP.${NC}"; exit 1;
    fi

    echo -e "${YELLOW}--> Mengekstrak kunci dari profil...${NC}"
    WARP_PRIVATE_KEY=$(grep 'PrivateKey' wgcf-profile.conf | awk '{print $3}')
    WARP_ADDRESSES=$(grep 'Address' wgcf-profile.conf | awk -F '= ' '{print $2}')
    WARP_ADDRESS_V4=$(echo "$WARP_ADDRESSES" | cut -d ',' -f 1)
    WARP_ADDRESS_V6=$(echo "$WARP_ADDRESSES" | cut -d ',' -f 2 | sed 's/ //g')

    if [[ -z "$WARP_PRIVATE_KEY" || -z "$WARP_ADDRESS_V4" ]]; then
        echo -e "${RED}KESALAHAN: Gagal mengekstrak kunci.${NC}"; exit 1;
    fi

    echo -e "${YELLOW}--> Menyimpan konfigurasi ke '$CONFIG_FILE'...${NC}"
    cat > "$CONFIG_FILE" <<EOL
{
  "MIKROTIK_IP": "${MIKROTIK_IP}",
  "MIKROTIK_USER": "${MIKROTIK_USER}",
  "MIKROTIK_PASS": "${MIKROTIK_PASS}",
  "WARP_PRIVATE_KEY": "${WARP_PRIVATE_KEY}",
  "WARP_ADDRESS_V4": "${WARP_ADDRESS_V4}",
  "WARP_ADDRESS_V6": "${WARP_ADDRESS_V6}"
}
EOL
    echo -e "\n${GREEN}Setup Selesai! Jalankan skrip ini lagi untuk menampilkan menu.${NC}"
    exit 0
}

# Muat konfigurasi
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then run_first_time_setup; fi
    MIKROTIK_IP=$(jq -r .MIKROTIK_IP "$CONFIG_FILE")
    MIKROTIK_USER=$(jq -r .MIKROTIK_USER "$CONFIG_FILE")
    MIKROTIK_PASS=$(jq -r .MIKROTIK_PASS "$CONFIG_FILE")
    WARP_PRIVATE_KEY=$(jq -r .WARP_PRIVATE_KEY "$CONFIG_FILE")
    WARP_ADDRESS_V4=$(jq -r .WARP_ADDRESS_V4 "$CONFIG_FILE")
    WARP_ADDRESS_V6=$(jq -r .WARP_ADDRESS_V6 "$CONFIG_FILE")
}

# Kirim perintah SSH
run_ssh() {
    sshpass -p "${MIKROTIK_PASS}" ssh -p 22 -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${MIKROTIK_USER}@${MIKROTIK_IP}" "$1"
}


# --- Fungsi-fungsi Menu ---

# 1. Install WARP
install_warp() {
    echo -e "${YELLOW}>>> Menginstal WARP ke Mikrotik...${NC}"
    read -r -d '' ROS_SCRIPT <<EOF
{
    :log warning "===== MEMULAI INSTALASI WARP v4.0 ====="
    :local warpPrivateKey "%WARP_PRIVATE_KEY%"
    :local warpAddressV4 "%WARP_ADDRESS_V4%"
    :local warpAddressV6 "%WARP_ADDRESS_V6%"
    :local commonComment "WARP-v4-Manager"
    :local warpInterfaceName "wg-warp"

    :log info "[SETUP] Membersihkan konfigurasi lama..."
    /interface wireguard remove [find comment=\$commonComment]
    /ip route remove [find comment=\$commonComment]
    /ipv6 route remove [find comment=\$commonComment]
    /ip firewall mangle remove [find comment~"Bypass-WARP"]

    :log info "[SETUP] Membuat interface WireGuard..."
    /interface wireguard add name=\$warpInterfaceName private-key=\$warpPrivateKey listen-port=1337 mtu=1280 comment=\$commonComment
    /interface wireguard peers add interface=\$warpInterfaceName public-key="bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=" endpoint-address=[:resolve 162.159.193.5] endpoint-port=2408 allowed-address=0.0.0.0/0,::/0 persistent-keepalive=25s comment=\$commonComment

    :log info "[SETUP] Menambahkan alamat IP..."
    /ip address add address=\$warpAddressV4 interface=\$warpInterfaceName comment=\$commonComment
    /ipv6 address add address=\$warpAddressV6 interface=\$warpInterfaceName comment=\$commonComment
    
    :log info "[SETUP] Membuat Address List untuk bypass..."
    /ip firewall address-list add list="Bypass-Domains" comment="Bypass-WARP-List"

    :log warning "===== INSTALASI WARP SELESAI! ====="
}
EOF
    ROS_SCRIPT="${ROS_SCRIPT//%WARP_PRIVATE_KEY%/$WARP_PRIVATE_KEY}"
    ROS_SCRIPT="${ROS_SCRIPT//%WARP_ADDRESS_V4%/$WARP_ADDRESS_V4}"
    ROS_SCRIPT="${ROS_SCRIPT//%WARP_ADDRESS_V6%/$WARP_ADDRESS_V6}"
    run_ssh "$ROS_SCRIPT"
    echo -e "${GREEN}>>> Instalasi WARP selesai.${NC}"
}

# 2. Status WARP
status_warp() {
    echo -e "${YELLOW}>>> Memeriksa Status WARP & Konfigurasi...${NC}"
    run_ssh '
      :put "--- Status Koneksi WireGuard (WARP) ---";
      /interface wireguard peers print;
      :put "\n--- Status Default Route ---";
      :local ipv4gw [/ip route get [find dst-address=0.0.0.0/0 and routing-mark=main and active] gateway];
      :local ipv6gw [/ipv6 route get [find dst-address=::/0 and routing-mark=main and active] gateway];
      :put ("Gateway IPv4 Utama: " . ($ipv4gw . " (" . [/interface get $ipv4gw name] . ")"));
      :put ("Gateway IPv6 Utama: " . ($ipv6gw . " (" . [/interface get $ipv6gw name] . ")"));
      :put "\n--- Konfigurasi Bypass Domain ---";
      /ip firewall mangle print where comment="Bypass-WARP-Rule";
    '
}

# 3, 4, 5. Tukar Gateway
change_gateway() {
    local mode=$1
    echo -e "${YELLOW}>>> Menukar Default Gateway ke mode: $mode...${NC}"
    local route_cmd_v4='/ip route set [find dst-address=0.0.0.0/0 and routing-mark=main] gateway=wg-warp'
    local route_cmd_v6='/ipv6 route set [find dst-address=::/0 and routing-mark=main] gateway=wg-warp'
    
    # Reset ke gateway ISP dulu
    run_ssh '/ip route set [find gateway=wg-warp] gateway=[/ip route get [find dst-address=0.0.0.0/0 and routing-mark=main] gateway-status~"^[0-9]"]; /ipv6 route set [find gateway=wg-warp] gateway=[/ipv6 route get [find dst-address=::/0 and routing-mark=main] gateway-status~"^[0-9]"];' > /dev/null 2>&1

    case $mode in
        IPv4)
            run_ssh "$route_cmd_v4"
            ;;
        IPv6)
            run_ssh "$route_cmd_v6"
            ;;
        Dual)
            run_ssh "$route_cmd_v4; $route_cmd_v6"
            ;;
    esac
    echo -e "${GREEN}>>> Gateway berhasil ditukar.${NC}"
}

# 6. Tanam Domain (Bypass)
manage_bypass() {
    echo -e "${CYAN}--- Menu Bypass Domain ---${NC}"
    echo "1. Tambah Domain untuk di-Bypass"
    echo "2. Hapus Domain dari Bypass"
    echo "3. Lihat Daftar Domain Bypass"
    echo "4. Kembali ke Menu Utama"
    read -p "Pilih opsi [1-4]: " bypass_choice

    case $bypass_choice in
        1)
            read -p "Masukkan nama domain yang ingin ditambah (misal: disneyplus.com): " domain
            run_ssh "/ip firewall address-list add list=Bypass-Domains address=$domain comment=Bypass-WARP-List; /ip firewall mangle add chain=prerouting dst-address-list=Bypass-Domains action=mark-routing new-routing-mark=via-warp passthrough=no comment=Bypass-WARP-Rule disabled=no;"
            echo -e "${GREEN}Domain '$domain' telah ditambahkan ke bypass.${NC}"
            ;;
        2)
            run_ssh '/ip firewall address-list print where list="Bypass-Domains"'
            read -p "Masukkan nama domain yang ingin dihapus: " domain
            run_ssh "/ip firewall address-list remove [find list=Bypass-Domains and address=$domain];"
            # Cek jika list kosong, matikan rule mangle
            run_ssh ':if ([/ip firewall address-list find where list="Bypass-Domains" and dynamic=no] = "") do={ /ip firewall mangle disable [find comment="Bypass-WARP-Rule"] }'
            echo -e "${RED}Domain '$domain' telah dihapus dari bypass.${NC}"
            ;;
        3)
            echo -e "${YELLOW}--- Daftar Domain Bypass Aktif ---${NC}"
            run_ssh '/ip firewall address-list print where list="Bypass-Domains"'
            ;;
        *)
            return
            ;;
    esac
}

# 7. Uninstall WARP
uninstall_warp() {
    echo -e "${RED}PERINGATAN! Ini akan menghapus SEMUA konfigurasi WARP & Bypass.${NC}"
    read -p "Apakah Anda yakin? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo ">>> Menghapus instalasi..."
        run_ssh '
          :log warning "--- [BASH] Menghapus Instalasi WARP v4.0 ---";
          /interface wireguard remove [find comment="WARP-v4-Manager"];
          /ip route remove [find comment="WARP-v4-Manager"];
          /ipv6 route remove [find comment="WARP-v4-Manager"];
          /ip firewall mangle remove [find comment~"Bypass-WARP"];
          /ip firewall address-list remove [find comment~"Bypass-WARP"];
        '
        echo -e "${GREEN}Semua konfigurasi WARP telah dihapus dari Mikrotik.${NC}"
    else
        echo "Penghapusan dibatalkan."
    fi
}

# 8. Menu Utama
main_menu() {
    while true; do
        echo -e "\n${CYAN}=====================================================${NC}"
        echo -e "${CYAN}       PENGELOLA WARP & BYPASS MIKROTIK v4.0       ${NC}"
        echo -e "${CYAN}=====================================================${NC}"
        echo "1. Install WARP"
        echo "2. Status WARP & Konfigurasi"
        echo -e "\n${YELLOW}--- Tukar Default Gateway ---${NC}"
        echo "3. Gunakan WARP untuk IPv4 SAJA"
        echo "4. Gunakan WARP untuk IPv6 SAJA"
        echo "5. Gunakan WARP untuk IPv4 & IPv6 (Dual Stack)"
        echo -e "\n${YELLOW}--- Bypass Domain ---${NC}"
        echo "6. Kelola Bypass Domain (Netflix, Hotstar, dll.)"
        echo -e "\n${RED}--- Lainnya ---${NC}"
        echo "7. Uninstall WARP"
        echo "8. Keluar"
        echo -e "${CYAN}=====================================================${NC}"
        read -p "Pilih opsi [1-8]: " choice

        case $choice in
            1) install_warp ;;
            2) status_warp ;;
            3) change_gateway "IPv4" ;;
            4) change_gateway "IPv6" ;;
            5) change_gateway "Dual" ;;
            6) manage_bypass ;;
            7) uninstall_warp ;;
            8) exit 0 ;;
            *) echo -e "${RED}Pilihan tidak valid. Silakan coba lagi.${NC}" ;;
        esac
        read -p "Tekan [Enter] untuk kembali ke menu..."
        clear
    done
}

# --- Program Utama ---
clear
check_dependencies
load_config
main_menu
