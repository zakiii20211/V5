# ==========================================================================================
# SKRIP BYPASS NETFLIX & HOTSTAR DENGAN CLOUDFLARE WARP (WIREGUARD IPv4 & IPv6)
# Dibuat untuk RouterOS v7+
#
# FITUR:
# - Setup sekali jalan.
# - Menu ON / OFF / STATUS yang mudah.
# - Mendukung IPv4 dan IPv6.
# - Menggunakan routing mark untuk efisiensi.
#
# CARA PENGGUNAAN SETELAH DIJALANKAN:
# 1. Buka New Terminal
# 2. Untuk mengaktifkan: /system script run Bypass-ON
# 3. Untuk menonaktifkan: /system script run Bypass-OFF
# 4. Untuk cek status: /system script run Bypass-STATUS
# ==========================================================================================

:log info "Memulai instalasi skrip Bypass Netflix & Hotstar via WARP..."

{
    # --- KONFIGURASI WARP (GANTI INI) ---
    :local warpPrivateKey "PASTE_PRIVATE_KEY_ANDA_DARI_WGCF_DI_SINI"
    :local warpAddressV4 "172.16.0.2/32"
    :local warpAddressV6 "2606:4700:110:abcd:ef12:3456:7890:1234/128"
    # ------------------------------------

    # --- Konfigurasi Statis (Biasanya tidak perlu diubah) ---
    :local warpPublicKey "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo="
    :local warpEndpoint "162.159.193.5:2408"
    :local warpInterfaceName "wg-warp"
    :local bypassComment "Bypass-Rule-NetflixHotstar"
    :local routingMarkName "via-warp-bypass"

    # 1. Hapus konfigurasi lama jika ada (untuk instalasi ulang yang bersih)
    :log info "Membersihkan konfigurasi lama (jika ada)..."
    /interface wireguard remove [find name=$warpInterfaceName]
    /ip firewall mangle remove [find comment=$bypassComment]
    /ipv6 firewall mangle remove [find comment=$bypassComment]
    /ip route remove [find comment=$bypassComment]
    /ipv6 route remove [find comment=$bypassComment]
    /ip firewall address-list remove [find list=Bypass-Domains]
    /system script remove [find name~"Bypass-"]

    # 2. Membuat Interface WireGuard untuk WARP
    :log info "Membuat interface WireGuard: $warpInterfaceName"
    /interface wireguard add name=$warpInterfaceName private-key=$warpPrivateKey listen-port=1337 mtu=1280

    # 3. Menambahkan Peer (Server WARP)
    :log info "Menambahkan peer untuk WireGuard..."
    /interface wireguard peers add interface=$warpInterfaceName public-key=$warpPublicKey endpoint-address=[:resolve $warpEndpoint] allowed-address=0.0.0.0/0,::/0 persistent-keepalive=25s

    # 4. Menambahkan Alamat IP ke Interface WireGuard
    :log info "Menambahkan alamat IP ke interface..."
    /ip address add address=$warpAddressV4 interface=$warpInterfaceName
    /ipv6 address add address=$warpAddressV6 interface=$warpInterfaceName

    # 5. Membuat Address List untuk Domain yang akan di-Bypass
    :log info "Membuat address-list untuk domain target..."
    /ip firewall address-list
    add list=Bypass-Domains address=netflix.com comment="Netflix"
    add list=Bypass-Domains address=nflxvideo.net comment="Netflix CDN"
    add list=Bypass-Domains address=hotstar.com comment="Hotstar"
    add list=Bypass-Domains address=hses.jio.com comment="Hotstar CDN"
    # Tambahkan domain lain di sini jika perlu

    # 6. Membuat Aturan Mangle untuk Menandai Traffic (IPv4 & IPv6)
    :log info "Membuat aturan Mangle (tagging traffic)..."
    /ip firewall mangle add chain=prerouting dst-address-list=Bypass-Domains action=mark-routing new-routing-mark=$routingMarkName passthrough=no comment=$bypassComment disabled=yes
    /ipv6 firewall mangle add chain=prerouting dst-address-list=Bypass-Domains action=mark-routing new-routing-mark=$routingMarkName passthrough=no comment=$bypassComment disabled=yes

    # 7. Membuat Aturan Route untuk Mengarahkan Traffic (IPv4 & IPv6)
    :log info "Membuat aturan Routing..."
    /ip route add distance=1 gateway=$warpInterfaceName routing-mark=$routingMarkName comment=$bypassComment disabled=yes
    /ipv6 route add distance=1 gateway=$warpInterfaceName routing-mark=$routingMarkName comment=$bypassComment disabled=yes

    # 8. Membuat Skrip Menu ON / OFF / STATUS
    :log info "Membuat skrip menu ON/OFF/STATUS..."
    
    # --- SKRIP ON ---
    /system script add name="Bypass-ON" source={
        :log info "================ BYPASS ON ================"
        :log info "Mengaktifkan aturan Mangle dan Route untuk Bypass..."
        /ip firewall mangle enable [find comment="Bypass-Rule-NetflixHotstar"]
        /ipv6 firewall mangle enable [find comment="Bypass-Rule-NetflixHotstar"]
        /ip route enable [find comment="Bypass-Rule-NetflixHotstar"]
        /ipv6 route enable [find comment="Bypass-Rule-NetflixHotstar"]
        :log info "Bypass Netflix & Hotstar telah DIAKTIFKAN."
        :log info "==========================================="
    }
    
    # --- SKRIP OFF ---
    /system script add name="Bypass-OFF" source={
        :log info "================ BYPASS OFF ==============="
        :log info "Menonaktifkan aturan Mangle dan Route untuk Bypass..."
        /ip firewall mangle disable [find comment="Bypass-Rule-NetflixHotstar"]
        /ipv6 firewall mangle disable [find comment="Bypass-Rule-NetflixHotstar"]
        /ip route disable [find comment="Bypass-Rule-NetflixHotstar"]
        /ipv6 route disable [find comment="Bypass-Rule-NetflixHotstar"]
        :log info "Bypass Netflix & Hotstar telah DINONAKTIFKAN."
        :log info "==========================================="
    }

    # --- SKRIP STATUS ---
    /system script add name="Bypass-STATUS" source={
        :log info "============== STATUS BYPASS =============="
        :if ([/ip firewall mangle get [find comment="Bypass-Rule-NetflixHotstar"] disabled] = false) do={
            :log info "Status: AKTIF (ON)"
            :log info "--- Cek Koneksi WireGuard ---"
            /interface wireguard peers print
            :log info "--- IP yang sedang di-Bypass ---"
            /ip firewall address-list print where list=Bypass-Domains
        } else={
            :log info "Status: TIDAK AKTIF (OFF)"
        }
        :log info "==========================================="
    }

    :log info "INSTALASI SELESAI!"
    :log info "Gunakan perintah '/system script run Bypass-ON' untuk mengaktifkan."
}
