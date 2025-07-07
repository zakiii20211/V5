#!/bin/bash

# ==============================================================================
# Skrip Manajer Cloudflare WARP
# Fitur: Instal, On/Off, Cek Status, Mode IP, Pengecualian Netflix
# Dibuat oleh: AI Assistant
# ==============================================================================

# Warna untuk output
C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_CYAN='\033[0;36m'

# Daftar domain Netflix untuk dikecualikan
NETFLIX_DOMAINS=(
    "netflix.com"
    "nflxvideo.net"
    "nflximg.net"
    "nflxso.net"
    "nflxext.com"
)

# Fungsi untuk memeriksa apakah skrip dijalankan sebagai root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${C_RED}Skrip ini harus dijalankan sebagai root atau dengan sudo.${C_RESET}"
        echo "Silakan coba lagi dengan: sudo ./warp.sh"
        exit 1
    fi
}

# Fungsi untuk menekan enter untuk melanjutkan
pause() {
    read -p "Tekan [Enter] untuk kembali ke menu..."
}

# Fungsi untuk menginstal WARP
install_warp() {
    echo -e "${C_YELLOW}Mencoba menginstal Cloudflare WARP...${C_RESET}"
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        echo -e "${C_RED}Tidak dapat mendeteksi sistem operasi.${C_RESET}"
        exit 1
    fi

    case $OS in
        ubuntu|debian)
            echo "Mendeteksi OS Debian/Ubuntu..."
            curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list
            apt-get update
            apt-get install -y cloudflare-warp
            ;;
        fedora|centos|rhel)
            echo "Mendeteksi OS Fedora/CentOS/RHEL..."
            dnf install -y cloudflare-warp
            ;;
        *)
            echo -e "${C_RED}Sistem operasi Anda ($OS) tidak didukung secara otomatis oleh skrip ini.${C_RESET}"
            exit 1
            ;;
    esac

    if command -v warp-cli &> /dev/null; then
        echo -e "${C_GREEN}Instalasi Cloudflare WARP berhasil.${C_RESET}"
        echo -e "${C_YELLOW}Menjalankan registrasi awal...${C_RESET}"
        warp-cli register
        warp-cli set-mode warp
        echo -e "${C_GREEN}Registrasi selesai. WARP siap digunakan.${C_RESET}"
    else
        echo -e "${C_RED}Instalasi gagal. Silakan coba instalasi manual.${C_RESET}"
        exit 1
    fi
    pause
}

# Fungsi untuk memeriksa apakah warp-cli sudah terinstal
check_warp_installed() {
    if ! command -v warp-cli &> /dev/null; then
        echo -e "${C_YELLOW}Cloudflare WARP (warp-cli) tidak ditemukan.${C_RESET}"
        read -p "Apakah Anda ingin menginstalnya sekarang? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            install_warp
        else
            echo -e "${C_RED}Skrip tidak dapat melanjutkan tanpa WARP terinstal.${C_RESET}"
            exit 1
        fi
    fi
}

# Fungsi untuk menyambungkan WARP
connect_warp() {
    echo -e "${C_YELLOW}Menyambungkan ke WARP...${C_RESET}"
    warp-cli connect
    echo -e "\n${C_GREEN}Perintah 'connect' telah dijalankan.${C_RESET}"
    warp-cli status | head -n 1
    pause
}

# Fungsi untuk memutuskan WARP
disconnect_warp() {
    echo -e "${C_YELLOW}Memutuskan koneksi dari WARP...${C_RESET}"
    warp-cli disconnect
    echo -e "\n${C_GREEN}Perintah 'disconnect' telah dijalankan.${C_RESET}"
    warp-cli status | head -n 1
    pause
}

# Fungsi untuk memeriksa status WARP
check_status() {
    echo -e "${C_CYAN}--- Status Cloudflare WARP ---${C_RESET}"
    warp-cli status
    echo -e "${C_CYAN}----------------------------${C_RESET}"
    pause
}

# Fungsi untuk mengatur mode IP
set_ip_mode() {
    while true; do
        clear
        echo -e "${C_CYAN}--- Pengaturan Mode IP WARP ---${C_RESET}"
        echo "1. Mode IPv4 Saja"
        echo "2. Mode IPv6 Saja"
        echo "3. Mode Dual Stack (IPv4 & IPv6 - Default)"
        echo "4. Kembali ke Menu Utama"
        echo -e "---------------------------------"
        read -p "Pilih opsi [1-4]: " ip_choice

        case $ip_choice in
            1)
                echo -e "${C_YELLOW}Mengatur mode ke IPv4...${C_RESET}"
                warp-cli set-families-mode ipv4
                echo -e "${C_GREEN}Mode berhasil diatur ke IPv4.${C_RESET}"
                pause
                ;;
            2)
                echo -e "${C_YELLOW}Mengatur mode ke IPv6...${C_RESET}"
                warp-cli set-families-mode ipv6
                echo -e "${C_GREEN}Mode berhasil diatur ke IPv6.${C_RESET}"
                pause
                ;;
            3)
                echo -e "${C_YELLOW}Mengatur mode ke Default (Dual Stack)...${C_RESET}"
                warp-cli set-families-mode all
                echo -e "${C_GREEN}Mode berhasil diatur ke Default.${C_RESET}"
                pause
                ;;
            4)
                break
                ;;
            *)
                echo -e "${C_RED}Pilihan tidak valid, coba lagi.${C_RESET}"
                sleep 1
                ;;
        esac
    done
}

# Fungsi untuk mengelola pengecualian Netflix
configure_netflix() {
    while true; do
        clear
        echo -e "${C_CYAN}--- Konfigurasi Pengecualian Domain Netflix ---${C_RESET}"
        echo "Fitur ini akan membuat traffic Netflix tidak melewati WARP."
        echo "Ini berguna untuk menghindari blokir dari Netflix."
        echo ""
        echo "1. Tambahkan Domain Netflix ke Pengecualian"
        echo "2. Hapus Domain Netflix dari Pengecualian"
        echo "3. Lihat Daftar Pengecualian Domain (Fallback)"
        echo "4. Kembali ke Menu Utama"
        echo -e "---------------------------------------------"
        read -p "Pilih opsi [1-4]: " netflix_choice

        case $netflix_choice in
            1)
                echo -e "${C_YELLOW}Menambahkan domain Netflix ke daftar pengecualian...${C_RESET}"
                for domain in "${NETFLIX_DOMAINS[@]}"; do
                    warp-cli add-fallback-domain "$domain"
                done
                echo -e "${C_GREEN}Domain Netflix berhasil ditambahkan.${C_RESET}"
                pause
                ;;
            2)
                echo -e "${C_YELLOW}Menghapus domain Netflix dari daftar pengecualian...${C_RESET}"
                for domain in "${NETFLIX_DOMAINS[@]}"; do
                    warp-cli remove-fallback-domain "$domain"
                done
                echo -e "${C_GREEN}Domain Netflix berhasil dihapus.${C_RESET}"
                pause
                ;;
            3)
                echo -e "${C_CYAN}--- Daftar Domain Pengecualian (Local Domain Fallback) ---${C_RESET}"
                warp-cli fallback-domains
                echo -e "--------------------------------------------------------"
                pause
                ;;
            4)
                break
                ;;
            *)
                echo -e "${C_RED}Pilihan tidak valid, coba lagi.${C_RESET}"
                sleep 1
                ;;
        esac
    done
}


# Fungsi menu utama
main_menu() {
    while true; do
        clear
        echo -e "${C_BLUE}=====================================${C_RESET}"
        echo -e "${C_CYAN}   Manajer Cloudflare WARP Script    ${C_RESET}"
        echo -e "${C_BLUE}=====================================${C_RESET}"
        echo -e "Status Saat Ini: $(warp-cli status | head -n 1 | cut -d ' ' -f 2-)"
        echo ""
        echo -e "${C_GREEN}1. Connect WARP (ON)${C_RESET}"
        echo -e "${C_RED}2. Disconnect WARP (OFF)${C_RESET}"
        echo -e "${C_YELLOW}3. Cek Status Detail${C_RESET}"
        echo "4. Atur Mode IP (IPv4/IPv6)"
        echo "5. Konfigurasi Pengecualian Netflix"
        echo "6. Instal Ulang / Update WARP"
        echo "7. Keluar"
        echo -e "${C_BLUE}-------------------------------------${C_RESET}"
        read -p "Pilih opsi [1-7]: " main_choice

        case $main_choice in
            1) connect_warp ;;
            2) disconnect_warp ;;
            3) check_status ;;
            4) set_ip_mode ;;
            5) configure_netflix ;;
            6) install_warp ;;
            7)
                echo -e "${C_CYAN}Terima kasih telah menggunakan skrip ini!${C_RESET}"
                exit 0
                ;;
            *)
                echo -e "${C_RED}Pilihan tidak valid, coba lagi.${C_RESET}"
                sleep 1
                ;;
        esac
    done
}

# ==============================================================================
# Eksekusi Skrip Utama
# ==============================================================================
check_root
check_warp_installed
main_menu