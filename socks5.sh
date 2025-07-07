#!/bin/bash

# File: menu_socks5_dns_ipv6_full.sh
# Menu lengkap cek SOCKS5 proxy dan DNS IPv6 dengan output JSON

# Daftar domain populer untuk pilihan cepat
POPULAR_DOMAINS=(
  POPULAR_DOMAINS=(
  "google.com"
  "facebook.com"
  "twitter.com"
  "youtube.com"
  "github.com"
  "wikipedia.org"
  "netflix.com"
)

function check_socks5() {
  read -p "Masukkan alamat SOCKS5 proxy (format ip:port): " proxy
  if ! [[ "$proxy" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
    echo "Format proxy salah! Contoh yang benar: 127.0.0.1:1080"
    return
  fi

  read -p "Masukkan host tujuan untuk cek koneksi (misal google.com): " host
  if [ -z "$host" ]; then
    echo "Host tidak boleh kosong."
    return
  fi

  echo "Mengecek koneksi SOCKS5 proxy $proxy ke host $host..."
  http_code=$(curl --socks5 $proxy -m 10 -s -o /dev/null -w "%{http_code}" http://$host)

  if [ "$http_code" = "000" ]; then
    echo "Koneksi gagal: Tidak dapat terhubung ke proxy atau host."
  else
    echo "Koneksi berhasil dengan HTTP status code: $http_code"
  fi
}

function check_dns_ipv6_json() {
  echo "Pilih domain untuk cek DNS IPv6:"
  for i in "${!POPULAR_DOMAINS[@]}"; do
    echo "$((i+1))) ${POPULAR_DOMAINS[$i]}"
  done
  echo "0) Masukkan domain lain"

  read -p "Pilih opsi (0-${#POPULAR_DOMAINS[@]}): " choice

  if [ "$choice" = "0" ]; then
    read -p "Masukkan domain yang ingin dicek (misal example.com): " domain
  elif [[ "$choice" =~ ^[1-9][0-9]*$ ]] && [ "$choice" -le "${#POPULAR_DOMAINS[@]}" ]; then
    domain=${POPULAR_DOMAINS[$((choice-1))]}
    echo "Domain terpilih: $domain"
  else
    echo "Pilihan tidak valid."
    return
  fi

  if [ -z "$domain" ]; then
    echo "Domain tidak boleh kosong."
    return
  fi

  results=$(dig AAAA "$domain" +short)

  echo "{"
  echo "  \"domain\": \"$domain\","
  echo "  \"AAAA_records\": ["

  first=true
  while read -r ip; do
    if [ -z "$ip" ]; then
      continue
    fi
    if [ "$first" = true ]; then
      echo "    \"$ip\""
      first=false
    else
      echo "    ,\"$ip\""
    fi
  done <<< "$results"

  if $first; then
    # Tidak ada hasil AAAA
    echo "    null"
  fi

  echo "  ]"
  echo "}"
}

function menu() {
  clear
  echo "=== Menu Lengkap SOCKS5 dan DNS IPv6 JSON ==="
  echo "1) Cek koneksi SOCKS5 proxy"
  echo "2) Cek DNS IPv6 (AAAA) dengan output JSON"
  echo "0) Keluar"
  echo
  read -p "Pilih opsi (0-2): " choice

  case $choice in
    1)
      check_socks5
      ;;
    2)
      check_dns_ipv6_json
      ;;
    0)
      echo "Keluar..."
      exit 0
      ;;
    *)
      echo "Pilihan tidak valid."
      ;;
  esac
}

while true; do
  menu
  echo
  read -p "Tekan ENTER untuk kembali ke menu..."
done

