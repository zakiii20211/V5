#!/bin.bash
# ==============================================================================
# Smart Streaming Domain Bypass Script
# Versi: 1.0
#
# CARA KERJA:
# Mengalihkan trafik untuk domain streaming tertentu ke sebuah LOCAL PROXY PORT.
# Anda harus menjalankan proxy client (misal: SSH tunnel, Shadowsocks)
# yang mendengarkan di port tersebut dan terhubung ke server Anda di luar negeri.
#
# DIBUTUHKAN: iptables, dig (dari dnsutils/bind-tools)
# ==============================================================================

# --- KONFIGURASI PENGGUNA (SILAKAN UBAH) ---

# Alamat IP dan Port dari PROXY LOKAL Anda.
# Ini adalah tempat proxy client Anda berjalan di komputer Anda.
# Contoh: Jika Anda menggunakan SSH tunnel `ssh -D 1080 user@server.com`
# maka port-nya adalah 1080.
# Untuk Squid/HTTP Proxy, biasanya port seperti 3128 atau 8080.
# Skrip ini menggunakan REDSOCKS/TRANSPARENT PROXY, jadi kita set port-nya.
REDIRECT_PORT="12345"

# --- DAFTAR DOMAIN (Bisa ditambah/dikurangi) ---

# Daftar domain bisa berubah. Anda mungkin perlu memperbarui ini secara berkala.
DOMAINS_NETFLIX=(
    "netflix.com"
    "nflxvideo.net"
    "nflximg.net"
    "nflxso.net"
    "fast.com" # Milik Netflix
)

DOMAINS_HOTSTAR=(
    "hotstar.com"
    "hotstar-cdn.net"
    "hses.akamaized.net"
    "live.hotstar.com"
)

# Gabungkan semua domain menjadi satu array
ALL_DOMAINS=("${DOMAINS_NETFLIX[@]}" "${DOMAINS_HOTSTAR[@]}")

# Nama chain untuk iptables agar mudah dibersihkan
CHAIN_NAME="STREAMING_BYPASS"

# --- FUNGSI-FUNGSI SKRIP ---

# Fungsi untuk memulai bypass
start_bypass() {
    echo "=> Memulai proses bypass..."

    # 1. Periksa hak akses sudo
    if [[ $EUID -ne 0 ]]; then
       echo "Skrip ini harus dijalankan dengan sudo."
       exit 1
    fi

    # 2. Buat chain baru di iptables
    echo "-> Membuat chain iptables: $CHAIN_NAME"
    iptables -t nat -N $CHAIN_NAME

    # 3. Alihkan trafik dari chain baru ke port proxy lokal
    # Menggunakan REDIRECT yang cocok untuk transparent proxy
    iptables -t nat -A $CHAIN_NAME -p tcp -j REDIRECT --to-ports $REDIRECT_PORT

    # 4. Cari IP untuk setiap domain dan tambahkan aturan
    echo "-> Mencari alamat IP dan menambahkan aturan routing..."
    for domain in "${ALL_DOMAINS[@]}"; do
        echo "  - Memproses domain: $domain"
        # Gunakan 'dig' untuk mendapatkan semua alamat IP (A dan AAAA record)
        IP_ADDRESSES=$(dig +short "$domain" A "$domain" AAAA | grep -v '^\s*$' | sort -u)
        if [[ -z "$IP_ADDRESSES" ]]; then
            echo "    Peringatan: Tidak dapat menemukan IP untuk $domain. Mungkin domain sudah tidak aktif."
            continue
        fi

        for ip in $IP_ADDRESSES; do
            echo "    - Menambahkan aturan untuk IP: $ip"
            # Tambahkan aturan untuk setiap IP agar melompat ke chain kita
            iptables -t nat -A OUTPUT -p tcp -d "$ip" -j $CHAIN_NAME
        done
    done

    echo "=> Bypass berhasil diaktifkan!"
    echo "=> Pastikan proxy client Anda berjalan dan mendengarkan di port $REDIRECT_PORT."
}

# Fungsi untuk menghentikan bypass
stop_bypass() {
    echo "=> Menghentikan proses bypass..."

    if [[ $EUID -ne 0 ]]; then
       echo "Skrip ini harus dijalankan dengan sudo."
       exit 1
    fi

    # 1. Hapus aturan dari chain OUTPUT yang merujuk ke chain kita
    # Cara aman: list aturan dengan nomor, lalu hapus dari bawah ke atas
    echo "-> Menghapus aturan dari chain OUTPUT..."
    iptables -t nat -L OUTPUT --line-numbers | grep $CHAIN_NAME | sort -r -k1 | cut -d' ' -f1 | while read -r num; do
        iptables -t nat -D OUTPUT "$num"
    done

    # 2. Flush (kosongkan) chain kustom kita
    echo "-> Mengosongkan chain $CHAIN_NAME..."
    iptables -t nat -F $CHAIN_NAME

    # 3. Hapus chain kustom kita
    echo "-> Menghapus chain $CHAIN_NAME..."
    iptables -t nat -X $CHAIN_NAME

    echo "=> Bypass berhasil dinonaktifkan. Semua aturan telah dibersihkan."
}

# Fungsi untuk menampilkan status
show_status() {
    echo "=> Status Aturan Bypass:"
    if iptables -t nat -L $CHAIN_NAME > /dev/null 2>&1; then
        echo "Status: AKTIF"
        echo "Proxy Port: $REDIRECT_PORT"
        echo "Aturan di chain OUTPUT yang mengarah ke bypass:"
        iptables -t nat -L OUTPUT -v -n | grep $CHAIN_NAME
    else
        echo "Status: TIDAK AKTIF"
    fi
}


# --- MAIN LOGIC ---

case "$1" in
    start)
        start_bypass
        ;;
    stop)
        stop_bypass
        ;;
    status)
        show_status
        ;;
    *)
        echo "Penggunaan: sudo $0 {start|stop|status}"
        exit 1
        ;;
esac