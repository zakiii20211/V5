#!/bin.bash

# ======================================================================================
#  SKRIP BYPASS LENGKAP v2 - NETFLIX & HOTSTAR VIA WARP (WIREGUARD IPv4 & IPv6)
# ======================================================================================
#  FITUR:
#  - Instalasi sekali jalan (one-click install).
#  - Satu menu kontrol utama: "Bypass-Menu".
#  - Menu bantuan otomatis jika perintah salah.
#  - Cek status koneksi yang lebih andal (last-handshake).
#
#  Dibuat untuk RouterOS v7+
# ======================================================================================

:log warning "===== MEMULAI INSTALASI BYPASS v2 ====="

{
    # ==================================================
    # --- GANTI DI SINI DENGAN INFORMASI WARP ANDA ---
    :local warpPrivateKey "PASTE_PRIVATE_KEY_ANDA_DARI_WGCF_DI_SINI"
    :local warpAddressV4 "172.16.0.2/32"
    :local warpAddressV6 "2606:4700:110:abcd:ef12:3456:7890:1234/128"
    # ==================================================

    # --- Konfigurasi Internal (Jangan Diubah) ---
    :local warpPublicKey "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo="
    :local warpEndpoint "162.159.193.5:2408"
    :local warpInterfaceName "wg-warp"
    :local commonComment "Bypass-WARP-v2"
    :local routingMarkName "via-warp-bypass"
    :local addressListName "Bypass-Domains"

    # [CLEANUP] Hapus konfigurasi lama jika ada untuk instalasi ulang
    :log info "[SETUP] Membersihkan konfigurasi lama dengan comment '$commonComment'..."
    /interface wireguard remove [find name=$warpInterfaceName]
    /ip firewall mangle remove [find comment=$commonComment]
    /ipv6 firewall mangle remove [find comment=$commonComment]
    /ip route remove [find comment=$commonComment]
    /ipv6 route remove [find comment=$commonComment]
    /ip firewall address-list remove [find list=$addressListName]
    /system script remove [find name="Bypass-Menu"]

    # [SETUP] Membuat Interface WireGuard untuk WARP
    :log info "[SETUP] Membuat interface WireGuard '$warpInterfaceName'..."
    /interface wireguard add name=$warpInterfaceName private-key=$warpPrivateKey listen-port=1337 mtu=1280 comment=$commonComment
    /interface wireguard peers add interface=$warpInterfaceName public-key=$warpPublicKey endpoint-address=[:resolve $warpEndpoint] allowed-address=0.0.0.0/0,::/0 persistent-keepalive=25s comment=$commonComment

    # [SETUP] Menambahkan Alamat IP ke Interface WireGuard
    :log info "[SETUP] Menambahkan alamat IP ke interface..."
    /ip address add address=$warpAddressV4 interface=$warpInterfaceName comment=$commonComment
    /ipv6 address add address=$warpAddressV6 interface=$warpInterfaceName comment=$commonComment

    # [FIREWALL] Membuat Address List untuk domain target
    :log info "[FIREWALL] Membuat address-list '$addressListName'..."
    /ip firewall address-list
    add list=$addressListName address=netflix.com comment=$commonComment
    add list=$addressListName address=nflxvideo.net comment=$commonComment
    add list=$addressListName address=hotstar.com comment=$commonComment
    add list=$addressListName address=hses.jio.com comment=$commonComment

    # [FIREWALL] Membuat Aturan Mangle & Route (dinonaktifkan secara default)
    :log info "[FIREWALL] Membuat aturan Mangle dan Route (disabled by default)..."
    /ip firewall mangle add chain=prerouting dst-address-list=$addressListName action=mark-routing new-routing-mark=$routingMarkName passthrough=no comment=$commonComment disabled=yes
    /ipv6 firewall mangle add chain=prerouting dst-address-list=$addressListName action=mark-routing new-routing-mark=$routingMarkName passthrough=no comment=$commonComment disabled=yes
    /ip route add distance=1 gateway=$warpInterfaceName routing-mark=$routingMarkName comment=$commonComment disabled=yes
    /ipv6 route add distance=1 gateway=$warpInterfaceName routing-mark=$routingMarkName comment=$commonComment disabled=yes

    # [MENU] Membuat Skrip Menu Kontrol Utama
    :log info "[MENU] Membuat skrip menu kontrol 'Bypass-Menu'..."
    /system script add name="Bypass-Menu" owner=admin policy=read,write source={
        :global pilih

        :if ($pilih = "on") do={
            :log warning "--- [MENU] Mengaktifkan Bypass Netflix & Hotstar ---"
            /ip firewall mangle enable [find comment="Bypass-WARP-v2"]
            /ipv6 firewall mangle enable [find comment="Bypass-WARP-v2"]
            /ip route enable [find comment="Bypass-WARP-v2"]
            /ipv6 route enable [find comment="Bypass-WARP-v2"]
            :log info "Status Bypass sekarang: AKTIF (ON)"
        } else={
            :if ($pilih = "off") do={
                :log warning "--- [MENU] Menonaktifkan Bypass Netflix & Hotstar ---"
                /ip firewall mangle disable [find comment="Bypass-WARP-v2"]
                /ipv6 firewall mangle disable [find comment="Bypass-WARP-v2"]
                /ip route disable [find comment="Bypass-WARP-v2"]
                /ipv6 route disable [find comment="Bypass-WARP-v2"]
                :log info "Status Bypass sekarang: TIDAK AKTIF (OFF)"
            } else={
                :if ($pilih = "status") do={
                    :log warning "--- [MENU] Cek Status Bypass ---"
                    :local status "TIDAK AKTIF (OFF)"
                    :if ([/ip firewall mangle get [find comment="Bypass-WARP-v2"] disabled] = false) do={
                        :set status "AKTIF (ON)"
                    }
                    :log info "Status Aturan Bypass: $status"
                    
                    :log info "--- Status Koneksi WireGuard (WARP) ---"
                    :local lastHandshake [/interface wireguard peers get [find comment="Bypass-WARP-v2"] last-handshake]
                    :if ($lastHandshake > 0s) do={
                        :log info "Koneksi WARP: TERHUBUNG (Handshake: $lastHandshake yang lalu)"
                    } else={
                        :log error "Koneksi WARP: GAGAL TERHUBUNG (Tidak ada handshake)"
                    }
                    /ip firewall address-list print where list="Bypass-Domains"
                } else={
                    # Jika tidak ada parameter, tampilkan menu bantuan
                    :log info " "
                    :log warning "=========================================================="
                    :log warning "         MENU KONTROL BYPASS NETFLIX & HOTSTAR v2"
                    :log warning "=========================================================="
                    :log info " "
                    :log info "Gunakan perintah di bawah ini di terminal:"
                    :log info " -> /system script run Bypass-Menu pilih=on"
                    :log info "    (Untuk MENGAKTIFKAN bypass)"
                    :log info " "
                    :log info " -> /system script run Bypass-Menu pilih=off"
                    :log info "    (Untuk MENONAKTIFKAN bypass)"
                    :log info " "
                    :log info " -> /system script run Bypass-Menu pilih=status"
                    :log info "    (Untuk MELIHAT STATUS bypass dan koneksi WARP)"
                    :log info " "
                    :log warning "=========================================================="
                }
            }
        }
    }

    :log warning "===== INSTALASI BYPASS v2 SELESAI! ====="
    :log info "Untuk memulai, jalankan perintah ini di terminal untuk melihat menu:"
    :log info "/system script run Bypass-Menu"
}
