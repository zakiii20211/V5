#!/bin/bash

# ======================================================================================
#  Pusat Kendali Bypass Mikrotik via BASH
# ======================================================================================
#  FITUR:
#  - Kontrol penuh dari terminal komputer Anda (Linux/macOS/WSL).
#  - Menggunakan SSH untuk komunikasi yang aman.
#  - Menu lengkap: install, on, off, status.
#  - Cukup edit konfigurasi di bawah ini sekali saja.
# ======================================================================================

# --- (WAJIB) EDIT KONFIGURASI DI BAWAH INI ---

# Informasi Login Mikrotik Anda
MIKROTIK_IP="192.168.88.1"
MIKROTIK_USER="admin"
MIKROTIK_PASS="khai767Rul" # <-- Ganti dengan password Mikrotik Anda
MIKROTIK_PORT="22"            # Port SSH, biasanya 22

# Informasi Kunci WARP (didapat dari wgcf)
WARP_PRIVATE_KEY="PASTE_PRIVATE_KEY_ANDA_DARI_WGCF_DI_SINI"
WARP_ADDRESS_V4="172.16.0.2/32"
WARP_ADDRESS_V6="2606:4700:110:abcd:ef12:3456:7890:1234/128"

# --- AKHIR DARI KONFIGURASI ---


# Peringatan Keamanan
if [[ "${MIKROTIK_PASS}" == "password_anda" || "${WARP_PRIVATE_KEY}" == "PASTE_PRIVATE_KEY_ANDA_DARI_WGCF_DI_SINI" ]]; then
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "!!! PERINGATAN: Harap edit konfigurasi di dalam file ini!    !!!"
  echo "!!! Ganti MIKROTIK_PASS dan WARP_PRIVATE_KEY.                !!!"
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  exit 1
fi

# Fungsi untuk menampilkan cara penggunaan
usage() {
  echo " "
  echo "=========================================================="
  echo "       Pusat Kendali Bypass Mikrotik via BASH"
  echo "=========================================================="
  echo " "
  echo "Penggunaan: ./mikrotik_bypass.sh [perintah]"
  echo " "
  echo "Perintah yang tersedia:"
  echo "  install   - Menginstal semua konfigurasi ke Mikrotik (HANYA SEKALI)."
  echo "  on        - Mengaktifkan bypass."
  echo "  off       - Menonaktifkan bypass."
  echo "  status    - Memeriksa status bypass dan koneksi WARP."
  echo " "
  echo "Contoh: ./mikrotik_bypass.sh install"
  echo "=========================================================="
}

# Fungsi untuk mengirim perintah ke Mikrotik via SSH
run_ssh_command() {
  sshpass -p "${MIKROTIK_PASS}" ssh -p "${MIKROTIK_PORT}" -o StrictHostKeyChecking=no -o ConnectTimeout=5 "${MIKROTIK_USER}@${MIKROTIK_IP}" "$1"
}

# Fungsi untuk menginstal semua konfigurasi
install() {
  echo ">>> Memulai instalasi ke Mikrotik di ${MIKROTIK_IP}..."
  
  # Perintah RouterOS yang akan dikirim
  read -r -d '' MIKROTIK_SCRIPT <<'EOF'
{
    :log warning "===== MEMULAI INSTALASI BYPASS v2 DARI SCRIPT BASH ====="

    :local warpPrivateKey "%WARP_PRIVATE_KEY%"
    :local warpAddressV4 "%WARP_ADDRESS_V4%"
    :local warpAddressV6 "%WARP_ADDRESS_V6%"

    :local warpPublicKey "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo="
    :local warpEndpoint "162.159.193.5:2408"
    :local warpInterfaceName "wg-warp"
    :local commonComment "Bypass-WARP-v2"
    :local routingMarkName "via-warp-bypass"
    :local addressListName "Bypass-Domains"

    :log info "[SETUP] Membersihkan konfigurasi lama..."
    /interface wireguard remove [find name=$warpInterfaceName]
    /ip firewall mangle remove [find comment=$commonComment]
    /ipv6 firewall mangle remove [find comment=$commonComment]
    /ip route remove [find comment=$commonComment]
    /ipv6 route remove [find comment=$commonComment]
    /ip firewall address-list remove [find list=$addressListName]
    /system script remove [find name="Bypass-Menu"]

    :log info "[SETUP] Membuat interface WireGuard '$warpInterfaceName'..."
    /interface wireguard add name=$warpInterfaceName private-key=$warpPrivateKey listen-port=1337 mtu=1280 comment=$commonComment
    /interface wireguard peers add interface=$warpInterfaceName public-key=$warpPublicKey endpoint-address=[:resolve $warpEndpoint] allowed-address=0.0.0.0/0,::/0 persistent-keepalive=25s comment=$commonComment

    :log info "[SETUP] Menambahkan alamat IP..."
    /ip address add address=$warpAddressV4 interface=$warpInterfaceName comment=$commonComment
    /ipv6 address add address=$warpAddressV6 interface=$warpInterfaceName comment=$commonComment

    :log info "[FIREWALL] Membuat address-list '$addressListName'..."
    /ip firewall address-list
    add list=$addressListName address=netflix.com comment=$commonComment
    add list=$addressListName address=nflxvideo.net comment=$commonComment
    add list=$addressListName address=hotstar.com comment=$commonComment
    add list=$addressListName address=hses.jio.com comment=$commonComment

    :log info "[FIREWALL] Membuat aturan Mangle dan Route (disabled by default)..."
    /ip firewall mangle add chain=prerouting dst-address-list=$addressListName action=mark-routing new-routing-mark=$routingMarkName passthrough=no comment=$commonComment disabled=yes
    /ipv6 firewall mangle add chain=prerouting dst-address-list=$addressListName action=mark-routing new-routing-mark=$routingMarkName passthrough=no comment=$commonComment disabled=yes
    /ip route add distance=1 gateway=$warpInterfaceName routing-mark=$routingMarkName comment=$commonComment disabled=yes
    /ipv6 route add distance=1 gateway=$warpInterfaceName routing-mark=$routingMarkName comment=$commonComment disabled=yes
    
    # Skrip Menu ini sekarang hanya untuk backup, kontrol utama ada di BASH
    /system script add name="Bypass-Menu" source=":log info \"Kontrol dipindahkan ke skrip BASH eksternal.\""

    :log warning "===== INSTALASI BYPASS v2 SELESAI! ====="
}
EOF

  # Mengganti placeholder dengan nilai variabel
  MIKROTIK_SCRIPT="${MIKROTIK_SCRIPT//%WARP_PRIVATE_KEY%/$WARP_PRIVATE_KEY}"
  MIKROTIK_SCRIPT="${MIKROTIK_SCRIPT//%WARP_ADDRESS_V4%/$WARP_ADDRESS_V4}"
  MIKROTIK_SCRIPT="${MIKROTIK_SCRIPT//%WARP_ADDRESS_V6%/$WARP_ADDRESS_V6}"

  # Mengirim skrip ke Mikrotik
  run_ssh_command "$MIKROTIK_SCRIPT"
  echo ">>> Instalasi selesai."
}

# Fungsi untuk mengaktifkan bypass
turn_on() {
  echo ">>> Mengaktifkan bypass di Mikrotik..."
  COMMAND='
    :log warning "--- [BASH] Mengaktifkan Bypass Netflix & Hotstar ---";
    /ip firewall mangle enable [find comment="Bypass-WARP-v2"];
    /ipv6 firewall mangle enable [find comment="Bypass-WARP-v2"];
    /ip route enable [find comment="Bypass-WARP-v2"];
    /ipv6 route enable [find comment="Bypass-WARP-v2"];
    :log info "Status Bypass sekarang: AKTIF (ON)";
  '
  run_ssh_command "$COMMAND"
  echo ">>> Selesai."
}

# Fungsi untuk menonaktifkan bypass
turn_off() {
  echo ">>> Menonaktifkan bypass di Mikrotik..."
  COMMAND='
    :log warning "--- [BASH] Menonaktifkan Bypass Netflix & Hotstar ---";
    /ip firewall mangle disable [find comment="Bypass-WARP-v2"];
    /ipv6 firewall mangle disable [find comment="Bypass-WARP-v2"];
    /ip route disable [find comment="Bypass-WARP-v2"];
    /ipv6 route disable [find comment="Bypass-WARP-v2"];
    :log info "Status Bypass sekarang: TIDAK AKTIF (OFF)";
  '
  run_ssh_command "$COMMAND"
  echo ">>> Selesai."
}

# Fungsi untuk memeriksa status
check_status() {
  echo ">>> Memeriksa status di Mikrotik..."
  COMMAND='
    :log warning "--- [BASH] Cek Status Bypass ---";
    :local status "TIDAK AKTIF (OFF)";
    :if ([/ip firewall mangle get [find comment="Bypass-WARP-v2"] disabled] = false) do={ :set status "AKTIF (ON)"; }
    :log info "Status Aturan Bypass: $status";
    :log info "--- Status Koneksi WireGuard (WARP) ---";
    /interface wireguard peers print;
  '
  run_ssh_command "$COMMAND"
}

# Logika Menu Utama
case "$1" in
  install)
    install
    ;;
  on)
    turn_on
    ;;
  off)
    turn_off
    ;;
  status)
    check_status
    ;;
  *)
    usage
    exit 1
    ;;
esac

exit 0
