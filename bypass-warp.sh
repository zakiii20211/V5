#!/bin/bash

# ======================================================================================
#  PENGELOLA BYPASS MIKROTIK OTOMATIS v3.0 - "ZERO EDIT" EDITION
# ======================================================================================
#  Oleh: Asisten AI
#  Fitur:
#  - Tidak perlu edit skrip.
#  - Setup interaktif pada penggunaan pertama.
#  - Otomatis membuat dan mengambil kunci WARP.
#  - Menyimpan konfigurasi agar tidak perlu input berulang.
#  - Menu lengkap: install, on, off, status, uninstall.
# ======================================================================================

# --- Variabel Global & Konfigurasi ---
CONFIG_FILE="manager.conf"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Fungsi-fungsi Inti ---

# Fungsi untuk memeriksa dependensi
check_dependencies() {
    echo -e "${YELLOW}--> Memeriksa program yang dibutuhkan...${NC}"
    for cmd in sshpass wgcf jq; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}KESALAHAN: Program '$cmd' tidak ditemukan.${NC}"
            echo "Harap instal terlebih dahulu. Petunjuk ada di dokumentasi."
            exit 1
        fi
    done
    echo -e "${GREEN}Semua program yang dibutuhkan tersedia.${NC}"
}

# Fungsi untuk setup pertama kali
run_first_time_setup() {
    echo "======================================================"
    echo " Selamat Datang! Ini adalah Penggunaan Pertama Kali. "
    echo "======================================================"
    echo "Kita akan melakukan konfigurasi awal."
    echo ""

    # 1. Minta kredensial Mikrotik
    read -p "Masukkan IP Address Mikrotik: " MIKROTIK_IP
    read -p "Masukkan Username Mikrotik: " MIKROTIK_USER
    read -s -p "Masukkan Password Mikrotik: " MIKROTIK_PASS
    echo ""

    # 2. Generate profil WARP
    echo -e "\n${YELLOW}--> Menjalankan 'wgcf' untuk membuat profil WARP...${NC}"
    if wgcf register --accept-tos && wgcf generate; then
        echo -e "${GREEN}Profil WARP berhasil dibuat (wgcf-profile.conf).${NC}"
    else
        echo -e "${RED}KESALAHAN: Gagal membuat profil WARP. Pastikan 'wgcf' berfungsi.${NC}"
        exit 1
    fi

    # 3. Ekstrak kunci dari file profil
    echo -e "${YELLOW}--> Mengekstrak kunci dari profil...${NC}"
    WARP_PRIVATE_KEY=$(grep 'PrivateKey' wgcf-profile.conf | awk '{print $3}')
    WARP_ADDRESSES=$(grep 'Address' wgcf-profile.conf | awk -F '= ' '{print $2}')
    WARP_ADDRESS_V4=$(echo "$WARP_ADDRESSES" | cut -d ',' -f 1)
    WARP_ADDRESS_V6=$(echo "$WARP_ADDRESSES" | cut -d ',' -f 2 | sed 's/ //g')

    if [[ -z "$WARP_PRIVATE_KEY" || -z "$WARP_ADDRESS_V4" ]]; then
        echo -e "${RED}KESALAHAN: Gagal mengekstrak kunci dari 'wgcf-profile.conf'.${NC}"
        exit 1
    fi

    # 4. Simpan konfigurasi ke file
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

    echo -e "\n${GREEN}======================================================"
    echo "      Setup Selesai! Konfigurasi Telah Disimpan.    "
    echo "======================================================${NC}"
    echo "Anda sekarang dapat menggunakan perintah 'install'."
}

# Muat konfigurasi dari file
load_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        run_first_time_setup
    fi
    # Gunakan JQ untuk memuat variabel dengan aman
    MIKROTIK_IP=$(jq -r .MIKROTIK_IP "$CONFIG_FILE")
    MIKROTIK_USER=$(jq -r .MIKROTIK_USER "$CONFIG_FILE")
    MIKROTIK_PASS=$(jq -r .MIKROTIK_PASS "$CONFIG_FILE")
    WARP_PRIVATE_KEY=$(jq -r .WARP_PRIVATE_KEY "$CONFIG_FILE")
    WARP_ADDRESS_V4=$(jq -r .WARP_ADDRESS_V4 "$CONFIG_FILE")
    WARP_ADDRESS_V6=$(jq -r .WARP_ADDRESS_V6 "$CONFIG_FILE")
}

# Fungsi untuk mengirim perintah ke Mikrotik via SSH
run_ssh() {
    sshpass -p "${MIKROTIK_PASS}" ssh -p 22 -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${MIKROTIK_USER}@${MIKROTIK_IP}" "$1"
}

# Fungsi untuk menampilkan menu bantuan
usage() {
    echo " "
    echo "=========================================================="
    echo "       PENGELOLA BYPASS MIKROTIK OTOMATIS v3.0"
    echo "=========================================================="
    echo " "
    echo "Penggunaan: ./mikrotik_manager.sh [perintah]"
    echo " "
    echo "Perintah yang tersedia:"
    echo -e "  ${GREEN}install${NC}    - Menginstal semua konfigurasi ke Mikrotik."
    echo -e "  ${GREEN}on${NC}         - Mengaktifkan bypass."
    echo -e "  ${GREEN}off${NC}        - Menonaktifkan bypass."
    echo -e "  ${YELLOW}status${NC}     - Memeriksa status bypass dan koneksi WARP."
    echo -e "  ${RED}uninstall${NC}  - Menghapus semua konfigurasi bypass dari Mikrotik."
    echo " "
}

# --- Logika Perintah ---

install_logic() {
    echo -e "${YELLOW}>>> Memulai instalasi ke Mikrotik di ${MIKROTIK_IP}...${NC}"
    
    # Perintah RouterOS yang akan dikirim, dengan placeholder
    read -r -d '' ROS_SCRIPT <<EOF
{
    :log warning "===== MEMULAI INSTALASI BYPASS v3.0 ====="
    :local warpPrivateKey "%WARP_PRIVATE_KEY%"
    :local warpAddressV4 "%WARP_ADDRESS_V4%"
    :local warpAddressV6 "%WARP_ADDRESS_V6%"
    :local commonComment "Bypass-Auto-v3"
    :local warpInterfaceName "wg-warp-auto"

    :log info "[SETUP] Membersihkan konfigurasi lama..."
    /interface wireguard remove [find name=\$warpInterfaceName]
    /ip firewall mangle remove [find comment=\$commonComment]
    /ipv6 firewall mangle remove [find comment=\$commonComment]
    /ip route remove [find comment=\$commonComment]
    /ipv6 route remove [find comment=\$commonComment]
    /ip firewall address-list remove [find list="Bypass-Domains"]
    
    :log info "[SETUP] Membuat interface WireGuard..."
    /interface wireguard add name=\$warpInterfaceName private-key=\$warpPrivateKey listen-port=1337 mtu=1280 comment=\$commonComment
    /interface wireguard peers add interface=\$warpInterfaceName public-key="bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo=" endpoint-address=[:resolve 162.159.193.5] endpoint-port=2408 allowed-address=0.0.0.0/0,::/0 persistent-keepalive=25s comment=\$commonComment
    
    :log info "[SETUP] Menambahkan alamat IP..."
    /ip address add address=\$warpAddressV4 interface=\$warpInterfaceName comment=\$commonComment
    /ipv6 address add address=\$warpAddressV6 interface=\$warpInterfaceName comment=\$commonComment
    
    :log info "[FIREWALL] Membuat address-list..."
    /ip firewall address-list
    add list="Bypass-Domains" address=netflix.com comment=\$commonComment
    add list="Bypass-Domains" address=nflxvideo.net comment=\$commonComment
    add list="Bypass-Domains" address=hotstar.com comment=\$commonComment
    add list="Bypass-Domains" address=hses.jio.com comment=\$commonComment

    :log info "[FIREWALL] Membuat aturan Mangle dan Route (disabled by default)..."
    /ip firewall mangle add chain=prerouting dst-address-list="Bypass-Domains" action=mark-routing new-routing-mark="via-warp-bypass" passthrough=no comment=\$commonComment disabled=yes
    /ipv6 firewall mangle add chain=prerouting dst-address-list="Bypass-Domains" action=mark-routing new-routing-mark="via-warp-bypass" passthrough=no comment=\$commonComment disabled=yes
    /ip route add distance=1 gateway=\$warpInterfaceName routing-mark="via-warp-bypass" comment=\$commonComment disabled=yes
    /ipv6 route add distance=1 gateway=\$warpInterfaceName routing-mark="via-warp-bypass" comment=\$commonComment disabled=yes
    
    :log warning "===== INSTALASI SELESAI! ====="
}
EOF

    # Ganti placeholder dengan nilai sebenarnya
    ROS_SCRIPT="${ROS_SCRIPT//%WARP_PRIVATE_KEY%/$WARP_PRIVATE_KEY}"
    ROS_SCRIPT="${ROS_SCRIPT//%WARP_ADDRESS_V4%/$WARP_ADDRESS_V4}"
    ROS_SCRIPT="${ROS_SCRIPT//%WARP_ADDRESS_V6%/$WARP_ADDRESS_V6}"

    run_ssh "$ROS_SCRIPT"
    echo -e "${GREEN}>>> Instalasi selesai.${NC}"
}

on_logic() {
    echo ">>> Mengaktifkan bypass..."
    run_ssh ':log info "--- [BASH] Mengaktifkan Bypass ---"; /ip firewall mangle enable [find comment="Bypass-Auto-v3"]; /ipv6 firewall mangle enable [find comment="Bypass-Auto-v3"]; /ip route enable [find comment="Bypass-Auto-v3"]; /ipv6 route enable [find comment="Bypass-Auto-v3"];'
    echo -e "${GREEN}Bypass telah DIAKTIFKAN.${NC}"
}

off_logic() {
    echo ">>> Menonaktifkan bypass..."
    run_ssh ':log info "--- [BASH] Menonaktifkan Bypass ---"; /ip firewall mangle disable [find comment="Bypass-Auto-v3"]; /ipv6 firewall mangle disable [find comment="Bypass-Auto-v3"]; /ip route disable [find comment="Bypass-Auto-v3"]; /ipv6 route disable [find comment="Bypass-Auto-v3"];'
    echo -e "${RED}Bypass telah DINONAKTIFKAN.${NC}"
}

status_logic() {
    echo ">>> Memeriksa status..."
    run_ssh '
      :log info "--- [BASH] Cek Status ---";
      :local status "TIDAK AKTIF (OFF)";
      :if ([/ip firewall mangle get [find comment="Bypass-Auto-v3"] disabled] = false) do={ :set status "AKTIF (ON)"; }
      :put "Status Aturan Bypass: $status";
      :put "--- Status Koneksi WireGuard (WARP) ---";
      /interface wireguard peers print;
    '
}

uninstall_logic() {
    echo -e "${RED}PERINGATAN! Ini akan menghapus SEMUA konfigurasi bypass dari Mikrotik.${NC}"
    read -p "Apakah Anda yakin ingin melanjutkan? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        echo ">>> Menghapus instalasi..."
        run_ssh '
          :log warning "--- [BASH] Menghapus Instalasi Bypass ---";
          /interface wireguard remove [find comment="Bypass-Auto-v3"];
          /ip firewall mangle remove [find comment="Bypass-Auto-v3"];
          /ipv6 firewall mangle remove [find comment="Bypass-Auto-v3"];
          /ip route remove [find comment="Bypass-Auto-v3"];
          /ipv6 route remove [find comment="Bypass-Auto-v3"];
          /ip firewall address-list remove [find comment="Bypass-Auto-v3"];
          :log info "Penghapusan selesai.";
        '
        echo -e "${GREEN}Semua konfigurasi bypass telah dihapus dari Mikrotik.${NC}"
    else
        echo "Penghapusan dibatalkan."
    fi
}


# --- Program Utama ---
check_dependencies
load_config

case "$1" in
    install) install_logic ;;
    on) on_logic ;;
    off) off_logic ;;
    status) status_logic ;;
    uninstall) uninstall_logic ;;
    *) usage ;;
esac

exit 0
