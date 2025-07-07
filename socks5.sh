#!/bin/bash

# ==============================================================================
# Skrip Bash untuk Bypass Domain via Cloudflare WARP WireGuard
#
# Deskripsi:
# Mengalihkan lalu lintas untuk domain tertentu (Netflix, Hotstar, dll.)
# melalui interface WireGuard WARP, sementara lalu lintas lain tetap normal.
# Mendukung IPv4 dan IPv6.
#
# Dibuat oleh: AI Model
# Versi: 1.1
# ==============================================================================

# --- KONFIGURASI (Silakan ubah sesuai kebutuhan) ---

# 1. Nama interface WireGuard WARP Anda.
#    Cari tahu dengan perintah: `ip a` atau `wg show`
#    Contoh: "wgcf", "warp", "wg0"
WARP_INTERFACE="wgcf"

# 2. Nama dan ID untuk tabel routing kustom.
#    Anda bisa biarkan default jika tidak ada konflik.
WARP_TABLE_ID="100"
WARP_TABLE_NAME="warp"

# 3. Daftar domain yang akan di-bypass.
#    Pisahkan dengan spasi.
DOMAINS_TO_BYPASS=(
    # Netflix
    "netflix.com"
    "nflxvideo.net"
    "nflximg.net"
    "nflxso.net"
    "nflxext.com"
    # Hotstar / Disney+
    "hotstar.com"
    "hotstar-cdn.net"
    "disneyplus.com"
    "disneystreaming.com"
    "dssott.com"
    "bamgrid.com"
)

# --- AKHIR KONFIGURASI ---

# Lokasi file sementara untuk menyimpan daftar IP
IP_LIST_FILE="/tmp/warp_bypass_ips.txt"

# Cek apakah skrip dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
   echo "Skrip ini harus dijalankan sebagai root. Gunakan 'sudo'."
   exit 1
fi

# Fungsi untuk memeriksa dependensi
check_deps() {
    if ! command -v dig &> /dev/null; then
        echo "Perintah 'dig' tidak ditemukan."
        echo "Silakan install 'dnsutils' (Debian/Ubuntu) atau 'bind-utils' (CentOS/RHEL)."
        exit 1
    fi
}

# Fungsi untuk menambahkan nama tabel ke /etc/iproute2/rt_tables jika belum ada
setup_routing_table() {
    if ! grep -q "^\s*$WARP_TABLE_ID\s+$WARP_TABLE_NAME\b" /etc/iproute2/rt_tables; then
        echo "Menambahkan tabel routing '$WARP_TABLE_NAME' ke /etc/iproute2/rt_tables..."
        echo "$WARP_TABLE_ID $WARP_TABLE_NAME" >> /etc/iproute2/rt_tables
    fi
}

# Fungsi untuk mencari IP dari semua domain
resolve_domains() {
    echo "Mencari alamat IP untuk domain yang ditentukan..."
    rm -f "$IP_LIST_FILE"
    for domain in "${DOMAINS_TO_BYPASS[@]}"; do
        # Cari alamat IPv4 (A) dan IPv6 (AAAA)
        dig +short "$domain" A >> "$IP_LIST_FILE"
        dig +short "$domain" AAAA >> "$IP_LIST_FILE"
    done
    # Hapus baris kosong
    sed -i '/^$/d' "$IP_LIST_FILE"
    echo "Pencarian IP selesai. Hasil disimpan di $IP_LIST_FILE"
}

# Fungsi untuk memulai bypass
start_bypass() {
    echo "Memulai bypass..."

    # 1. Pastikan interface WARP aktif
    if ! ip link show "$WARP_INTERFACE" &> /dev/null; then
        echo "Error: Interface '$WARP_INTERFACE' tidak ditemukan atau tidak aktif."
        exit 1
    fi

    # 2. Cari alamat IP
    resolve_domains
    if [ ! -s "$IP_LIST_FILE" ]; then
        echo "Error: Gagal mendapatkan alamat IP. Periksa koneksi internet atau daftar domain."
        exit 1
    fi

    # 3. Tambahkan rute default ke tabel kustom via interface WARP
    # Perintah ini akan menangani IPv4 dan IPv6 secara otomatis
    echo "Menambahkan rute default via $WARP_INTERFACE ke tabel $WARP_TABLE_NAME..."
    ip route add default dev "$WARP_INTERFACE" table "$WARP_TABLE_NAME"

    # 4. Tambahkan aturan routing untuk setiap IP
    echo "Menambahkan aturan routing untuk setiap IP..."
    while IFS= read -r ip; do
        if [[ -n "$ip" ]]; then
            ip rule add to "$ip" table "$WARP_TABLE_NAME"
        fi
    done < "$IP_LIST_FILE"

    # 5. Bersihkan cache routing
    ip route flush cache
    echo -e "\nBypass berhasil diaktifkan!"
    echo "Lalu lintas ke Netflix/Hotstar sekarang dialihkan melalui $WARP_INTERFACE."
}

# Fungsi untuk menghentikan bypass
stop_bypass() {
    echo "Menghentikan bypass..."

    if [ ! -f "$IP_LIST_FILE" ]; then
        echo "Tidak ada file daftar IP ($IP_LIST_FILE). Mungkin bypass belum pernah dijalankan."
        echo "Mencoba menghapus aturan secara umum (jika ada)..."
        # Mencoba menghapus aturan yang mungkin tersisa
        while ip rule | grep -q "lookup $WARP_TABLE_NAME"; do
           ip rule del lookup "$WARP_TABLE_NAME"
        done
    else
        # 1. Hapus aturan routing untuk setiap IP
        echo "Menghapus aturan routing..."
        while IFS= read -r ip; do
            if [[ -n "$ip" ]]; then
                # Terus hapus sampai tidak ada lagi aturan untuk IP ini
                while ip rule list | grep -q "to $ip table $WARP_TABLE_NAME"; do
                    ip rule del to "$ip" table "$WARP_TABLE_NAME"
                done
            fi
        done < "$IP_LIST_FILE"
        rm -f "$IP_LIST_FILE"
    fi

    # 2. Hapus rute default dari tabel kustom
    echo "Menghapus rute dari tabel $WARP_TABLE_NAME..."
    ip route flush table "$WARP_TABLE_NAME"

    # 3. Bersihkan cache routing
    ip route flush cache
    echo -e "\nBypass berhasil dihentikan."
    echo "Semua lalu lintas kembali normal."
}

# Fungsi untuk menampilkan status
status_bypass() {
    echo "--- Status Bypass WARP ---"
    if ! ip link show "$WARP_INTERFACE" &> /dev/null; then
        echo "Interface $WARP_INTERFACE: TIDAK AKTIF"
    else
        echo "Interface $WARP_INTERFACE: AKTIF"
    fi

    echo ""
    echo "Aturan routing untuk tabel '$WARP_TABLE_NAME':"
    ip rule show | grep "lookup $WARP_TABLE_NAME" || echo "Tidak ada aturan ditemukan."

    echo ""
    echo "Isi tabel routing '$WARP_TABLE_NAME':"
    ip route show table "$WARP_TABLE_NAME" || echo "Tabel kosong."
    
    echo ""
    echo "Daftar IP yang di-bypass (jika aktif):"
    if [ -f "$IP_LIST_FILE" ]; then
        cat "$IP_LIST_FILE"
    else
        echo "Tidak ada file daftar IP. Bypass kemungkinan tidak aktif."
    fi
    echo "--------------------------"
}

# Logika utama skrip
case "$1" in
    start)
        check_deps
        setup_routing_table
        start_bypass
        ;;
    stop)
        stop_bypass
        ;;
    restart)
        stop_bypass
        sleep 1
        check_deps
        setup_routing_table
        start_bypass
        ;;
    status)
        status_bypass
        ;;
    *)
        echo "Penggunaan: sudo $0 {start|stop|restart|status}"
        exit 1
        ;;
esac

exit 0
