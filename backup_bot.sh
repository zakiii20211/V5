#!/bin/bash

# ==============================================================================
# Skrip Backup Otomatis VPS ke Telegram
#
# Dibuat oleh: AI (GPT-4)
# Versi: 1.1
#
# Deskripsi:
# Skrip ini akan:
# 1. Mem-backup file konfigurasi Xray.
# 2. Membuat daftar user SSH beserta tanggal kedaluwarsanya.
# 3. Mem-backup direktori penting lainnya yang Anda tentukan.
# 4. Mengemas semuanya dalam satu file .tar.gz.
# 5. Mengirim file arsip tersebut ke chat Telegram Anda.
# ==============================================================================

# Hentikan skrip jika ada perintah yang gagal
set -e
set -o pipefail

# --- (WAJIB DIISI) KONFIGURASI TELEGRAM ---
BOT_TOKEN="GANTI_DENGAN_TOKEN_BOT_ANDA"
CHAT_ID="GANTI_DENGAN_CHAT_ID_ANDA"
# -----------------------------------------

# --- (OPSIONAL) KONFIGURASI PATH & DIREKTORI BACKUP ---
# Path file konfigurasi Xray
XRAY_CONFIG_PATH="/usr/local/etc/xray/config.json"

# Daftar direktori lain yang ingin di-backup.
# Tambahkan path direktori lain di dalam tanda kurung.
# Contoh: OTHER_DIRECTORIES_TO_BACKUP=("/etc/nginx" "/var/www/my-website")
OTHER_DIRECTORIES_TO_BACKUP=(
    "/etc/ssh/sshd_config"  # Contoh: file konfigurasi SSH
    # "/etc/nginx/conf.d"   # Hapus tanda # jika ingin backup konfigurasi Nginx
)
# --------------------------------------------------------

# Cek apakah konfigurasi sudah diisi
if [[ "$BOT_TOKEN" == "GANTI_DENGAN_TOKEN_BOT_ANDA" || "$CHAT_ID" == "GANTI_DENGAN_CHAT_ID_ANDA" ]]; then
    echo "Kesalahan: Harap isi BOT_TOKEN dan CHAT_ID di dalam skrip."
    exit 1
fi

# Cek apakah dijalankan sebagai root (diperlukan untuk membaca beberapa file sistem)
if [[ $EUID -ne 0 ]]; then
   echo "Skrip ini harus dijalankan sebagai root (sudo) untuk mengakses semua file."
   exit 1
fi

# Variabel dinamis
HOSTNAME=$(hostname)
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="/tmp/vps_backup_${DATE}"
ARCHIVE_NAME="backup-${HOSTNAME}-${DATE}.tar.gz"
ARCHIVE_PATH="/tmp/${ARCHIVE_NAME}"

# Fungsi untuk membersihkan file sementara saat skrip selesai atau gagal
cleanup() {
    echo "Membersihkan file sementara..."
    rm -rf "$BACKUP_DIR"
    rm -f "$ARCHIVE_PATH"
    echo "Selesai."
}
trap cleanup EXIT SIGHUP SIGINT SIGTERM

# Fungsi untuk mengirim pesan teks ke Telegram
send_telegram_message() {
    local message="$1"
    curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        -d "text=${message}" \
        -d "parse_mode=Markdown" > /dev/null
}

# Fungsi untuk mengirim file ke Telegram
send_telegram_document() {
    local file_path="$1"
    local caption="$2"
    
    echo "Mengirim file backup ke Telegram..."
    local response
    response=$(curl -s -F "chat_id=${CHAT_ID}" -F "document=@${file_path}" -F "caption=${caption}" "https://api.telegram.org/bot${BOT_TOKEN}/sendDocument")

    # Cek apakah pengiriman berhasil
    if echo "$response" | grep -q '"ok":true'; then
        echo "File backup berhasil dikirim ke Telegram."
    else
        echo "Gagal mengirim file ke Telegram. Respon API:"
        echo "$response"
        send_telegram_message "Gagal mengirim file backup \`$ARCHIVE_NAME\` dari VPS \`$HOSTNAME\`."
        exit 1
    fi
}

# =================================
# MULAI PROSES BACKUP
# =================================

echo "Memulai proses backup untuk VPS: $HOSTNAME"
send_telegram_message "🤖 *Memulai Backup VPS...*

*Server:* \`$HOSTNAME\`
*Waktu:* \`$(date +"%d %B %Y %H:%M:%S")\`"

# Buat direktori backup sementara
mkdir -p "$BACKUP_DIR/xray"
mkdir -p "$BACKUP_DIR/ssh"
mkdir -p "$BACKUP_DIR/other_data"

# 1. Backup User SSH
echo "Membuat daftar user SSH..."
{
    echo "======================================="
    echo "  Daftar User SSH & Tanggal Kedaluwarsa "
    echo "======================================="
    echo "Dibuat pada: $(date)"
    echo "---------------------------------------"
    # Loop melalui user dengan UID 1000 ke atas (user biasa)
    getent passwd | while IFS=: read -r username _ uid _ _ home _; do
        if [ "$uid" -ge 1000 ] && [ -d "$home" ]; then
            expiry_date=$(chage -l "$username" | grep 'Account expires' | awk -F': ' '{print $2}')
            echo "Username: $username | Kedaluwarsa: $expiry_date"
        fi
    done
} > "$BACKUP_DIR/ssh/user_ssh_list.txt"
echo "Daftar user SSH berhasil dibuat."

# 2. Backup Konfigurasi Xray
echo "Mem-backup konfigurasi Xray..."
if [ -f "$XRAY_CONFIG_PATH" ]; then
    cp "$XRAY_CONFIG_PATH" "$BACKUP_DIR/xray/"
    echo "File config.json Xray berhasil di-backup."
else
    echo "Peringatan: File konfigurasi Xray di '$XRAY_CONFIG_PATH' tidak ditemukan."
    echo "File konfigurasi Xray tidak ditemukan!" > "$BACKUP_DIR/xray/ERROR.txt"
fi

# 3. Backup Direktori Lainnya
echo "Mem-backup direktori tambahan..."
for dir in "${OTHER_DIRECTORIES_TO_BACKUP[@]}"; do
    if [ -e "$dir" ]; then
        cp -r "$dir" "$BACKUP_DIR/other_data/"
        echo "  - Direktori '$dir' berhasil di-backup."
    else
        echo "  - Peringatan: Direktori '$dir' tidak ditemukan, dilewati."
    fi
done

# 4. Buat Arsip .tar.gz
echo "Membuat arsip backup: $ARCHIVE_NAME"
tar -czf "$ARCHIVE_PATH" -C "$(dirname "$BACKUP_DIR")" "$(basename "$BACKUP_DIR")"

# 5. Kirim ke Telegram
FILE_SIZE=$(du -h "$ARCHIVE_PATH" | awk '{print $1}')
CAPTION="✅ *Backup VPS Selesai*

*Server:* \`$HOSTNAME\`
*File:* \`$ARCHIVE_NAME\`
*Ukuran:* \`$FILE_SIZE\`

Backup berisi konfigurasi Xray, daftar user SSH, dan data penting lainnya."

send_telegram_document "$ARCHIVE_PATH" "$CAPTION"

echo "================================="
echo "PROSES BACKUP SELESAI"
echo "================================="
