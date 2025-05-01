#!/bin/bash
clear
### Color
apt update -y
apt install ruby -y
apt install curl wget -y
gem install lolcat
apt install wondershaper -y

NC='\033[0m'
rbg='\033[41;37m'
r='\033[1;91m'
g='\033[1;92m'
y='\033[1;93m'
u='\033[0;35m'
c='\033[0;96m'
w='\033[1;97m'
a='\033[0;34m'

# Mengecek apakah directory xray
if [[ ! -d /etc/xray ]]; then
    mkdir -p /etc/xray
fi

# Pengecekan apakah file isp sudah ada dan pengecekan apakah file isp kosong
if [[ ! -f /etc/xray/isp ]] || [[ ! -s /etc/xray/isp ]]; then
    curl -s ipinfo.io/org?token=7a814b6263b02c -o /etc/xray/isp
fi

# Pengecekan apakah file city sudah ada dan pengecekan apakah file city kosong
if [[ ! -f /etc/xray/city ]] || [[ ! -s /etc/xray/city ]]; then
    curl -s ipinfo.io/city?token=7a814b6263b02c -o /etc/xray/city
fi

# Pengecekan apakah file ipvps sudah ada dan pengecekan apakah file ipvps kosong
if [[ ! -f /root/.ipvps ]] || [[ ! -s /root/.ipvps ]]; then
    curl -s ipv4.icanhazip.com -o /root/.ipvps
fi

ISP=$(cat /etc/xray/isp)
CITY=$(cat /etc/xray/city)
IP=$(cat /root/.ipvps)

# // Checking Os Architecture
if [[ $( uname -m | awk '{print $1}' ) == "x86_64" ]]; then
echo -ne
else
echo -e "${EROR} Your Architecture Is Not Supported ( ${y}$( uname -m )${NC} )"
exit 1
fi

if [ "$(systemd-detect-virt)" == "openvz" ]; then
echo "OpenVZ is not supported"
exit 1
fi

url_izin="https://raw.githubusercontent.com/zakiii20211/V5/main/Regist"
username=$(wget -qO- $url_izin | grep $IP | awk '{print $2}')
exp=$(wget -qO- $url_izin | grep $IP | awk '{print $3}')

d1=$(date -d "$valid" +%s)
d2=$(date -d "$today" +%s)
certifacate=$(((d1 - d2) / 86400))
# VPS Information
DATE=$(date +'%Y-%m-%d')
datediff() {
d1=$(date -d "$1" +%s)
d2=$(date -d "$2" +%s)
echo -e "$COLOR1 $NC Expiry In   : $(( (d1 - d2) / 86400 )) Days"
}
mai="datediff "$Exp" "$DATE""
Info="(${g}Active${NC})"
Error="(${r}Expired${NC})"
today=`date -d "0 days" +"%Y-%m-%d"`
Exp1=$(wget -qO- $url_izin | grep $IP | awk '{print $4}')
if [[ $today < $Exp1 ]]; then
sts="${Info}"
else
sts="${Error}"
fi

REPO="https://raw.githubusercontent.com/zakiii20211/V5/main/"
start=$(date +%s)
secs_to_human() {
echo "Installation time : $((${1} / 3600)) hours $(((${1} / 60) % 60)) minute's $((${1} % 60)) seconds"
}
function print_ok() {
echo -e "${OK} ${c} $1 ${NC}"
}
function print_install() {
echo -e "${g} =============================== ${NC}"
echo -e "${y} # $1 ${NC}"
echo -e "${g} =============================== ${NC}"
sleep 0.5
}

function print_error() {
echo -e "${ERROR} ${REDBG} $1 ${NC}"
}

function print_success() {
if [[ 0 -eq $? ]]; then
echo -e "${g} =============================== ${NC}"
echo -e "${g} # $1 berhasil dipasang"
echo -e "${g} =============================== ${NC}"
fi
}

function is_root() {
if [[ 0 == "$UID" ]]; then
print_ok "Root user Start installation process"
else
print_error "The current user is not the root user, please switch to the root user and run the script again"
fi
}

function first_setup(){

print_install "Membuat direktori xray"
    mkdir -p /etc/xray
    touch /etc/xray/domain
    mkdir -p /var/log/xray
    chown www-data:www-data /var/log/xray
    chmod +x /var/log/xray
    touch /var/log/xray/access.log
    touch /var/log/xray/error.log
    mkdir -p /var/lib/kyt >/dev/null 2>&1
    export tanggal=`date -d "0 days" +"%d-%m-%Y - %X" `
    export OS_Name=$( cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/PRETTY_NAME//g' | sed 's/=//g' | sed 's/"//g' )
    export Kernel=$( uname -r )
    export Arch=$( uname -m )
    timedatectl set-timezone Asia/Jakarta
    echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
    echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
    print_success "Directory Xray"
}

function base_package() {
clear
apt update -y
apt install sudo -y
sudo apt-get clean all
apt install -y debconf-utils
apt install p7zip-full at -y
apt-get remove --purge ufw firewalld -y
apt-get remove --purge exim4 -y
apt-get autoremove -y
apt install -y --no-install-recommends software-properties-common
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt-get -y install nginx iptables iptables-persistent netfilter-persistent libxml-parser-perl squid screen curl jq bzip2 gzip coreutils zip unzip rsyslog net-tools sed bc apt-transport-https build-essential dirmngr libxml-parser-perl lsof openvpn easy-rsa fail2ban tmux squid dropbear socat cron bash-completion ntpdate xz-utils apt-transport-https chrony pkg-config bison make git speedtest-cli p7zip-full zlib1g-dev python-is-python3 python3-pip build-essential squid libcurl4-openssl-dev
sudo apt-get autoclean -y >/dev/null 2>&1
audo apt-get -y --purge removd unscd >/dev/null 2>&1
sudo apt-get -y --purge remove samba* >/dev/null 2>&1
sudo apt-get -y --purge remove bind9* >/dev/null 2>&1
sudo apt-get -y remove sendmail* >/dev/null 2>&1
apt autoremove -y >/dev/null 2>&1
print_success "Packet Yang Dibutuhkan"
}

# Fungsi input domain
function pasang_domain() {
clear
echo -e "   .----------------------------------."
echo -e "   |\e[1;32mPlease Select a Domain Type Below \e[0m|"
echo -e "   '----------------------------------'"
echo -e "     \e[1;32m1)\e[0m Domain Sendiri"
echo -e "     \e[1;32m2)\e[0m Gunakan Domain Script"
echo -e "   ------------------------------------"
read -p "   Please select numbers 1-2 or Any Button(Random) : " host
echo ""
if [[ $host == "1" ]]; then
echo -e "   \e[1;32mPlease Enter Your Subdomain $NC"
read -p "   Subdomain: " host1
echo "IP=" >> /var/lib/kyt/ipvps.conf
echo $host1 > /etc/xray/domain
echo $host1 > /root/domain
echo ""
elif [[ $host == "2" ]]; then
echo "Proses pointing"
wget -q -O cf.sh "${REPO}files/cf.sh"
chmod +x cf.sh
./cf.sh
else
clear
echo -e " Pilih hanya dari 1 - 2 !!!!"
sleep 3
pasang_domain
fi
}

restart_system(){

TIMES="10"
URL="https://api.telegram.org/bot$KEY/sendMessage"
CHATID="7065915127"
KEY="7658351322:AAEtC7WqTCylhESrzDzG3JO67o7vQkaKkzA"
TIMEZONE=$(printf '%(%H:%M:%S)T')
TEXT="
<code>────────────────────</code>
<b>⚡AUTOSCRIPT PREMIUM⚡</b>
<code>────────────────────</code>
<code>Owner    :</code><code>$username</code>
<code>Domain   :</code><code>$domain</code>
<code>IPVPS    :</code><code>$IP</code>
<code>ISP      :</code><code>$ISP</code>
<code>CITY     :</code><code>$CITY</code>
<code>Time     :</code><code>$TIMEZONE</code>
<code>Exp Sc.  :</code><code>$exp</code>
<code>────────────────────</code>
<b>   KEN STORE SCRIPT  </b>
<code>────────────────────</code>
<i>Automatic Notifications From Github</i>
"'&reply_markup={"inline_keyboard":[[{"text":"ᴏʀᴅᴇʀ","url":"https://t.me/zaki/tunnel"}]]}' 
    curl -s --max-time $TIMES -d "chat_id=$CHATID&disable_web_page_preview=1&text=$TEXT&parse_mode=html" $URL >/dev/null
}

function pasang_ssl() {
clear
print_install "Memasang SSL Pada Domain"
rm -rf /etc/xray/xray.key
rm -rf /etc/xray/xray.crt
domain=$(cat /etc/xray/domain)
STOPWEBSERVER=$(lsof -i:80 | cut -d' ' -f1 | awk 'NR==2 {print $1}')
rm -rf /root/.acme.sh
mkdir /root/.acme.sh
systemctl stop $STOPWEBSERVER
systemctl stop nginx
curl -s "https://acme-install.netlify.app/acme.sh" -o /root/.acme.sh/acme.sh
chmod +x /root/.acme.sh/acme.sh
/root/.acme.sh/acme.sh --upgrade --auto-upgrade
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc
chmod 777 /etc/xray/xray.key
print_success "SSL Certificate"
}

function make_folder_xray() {
rm -rf /etc/vmess/.vmess.db
rm -rf /etc/vless/.vless.db
rm -rf /etc/trojan/.trojan.db
rm -rf /etc/shadowsocks/.shadowsocks.db
rm -rf /etc/ssh/.ssh.db
rm -rf /etc/bot/.bot.db
mkdir -p /etc/bot
mkdir -p /etc/xray
mkdir -p /etc/vmess
mkdir -p /etc/vless
mkdir -p /etc/trojan
mkdir -p /etc/shadowsocks
mkdir -p /etc/ssh
mkdir -p /usr/bin/xray/
mkdir -p /var/log/xray/
mkdir -p /var/www/html
mkdir -p /etc/kyt/limit/vmess/ip
mkdir -p /etc/kyt/limit/vless/ip
mkdir -p /etc/kyt/limit/trojan/ip
mkdir -p /etc/kyt/limit/ssh/ip
mkdir -p /etc/limit/vmess
mkdir -p /etc/limit/vless
mkdir -p /etc/limit/trojan
mkdir -p /etc/limit/ssh
chmod +x /var/log/xray
touch /etc/xray/domain
touch /var/log/xray/access.log
touch /var/log/xray/error.log
touch /etc/vmess/.vmess.db
touch /etc/vless/.vless.db
touch /etc/trojan/.trojan.db
touch /etc/shadowsocks/.shadowsocks.db
touch /etc/ssh/.ssh.db
touch /etc/bot/.bot.db
echo "& plughin Account" >>/etc/vmess/.vmess.db
echo "& plughin Account" >>/etc/vless/.vless.db
echo "& plughin Account" >>/etc/trojan/.trojan.db
echo "& plughin Account" >>/etc/shadowsocks/.shadowsocks.db
echo "& plughin Account" >>/etc/ssh/.ssh.db
}
function install_xray() {
clear
print_install "Core Xray Latest Version"
domainSock_dir="/run/xray";! [ -d $domainSock_dir ] && mkdir  $domainSock_dir
chown www-data:www-data $domainSock_dir

# / / Ambil Xray Core Version Terbaru
latest_version="$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data --version 24.10.31
#mv /usr/local/bin/xray /usr/bin/xray_24.10.31
#wget -q -O /usr/local/bin/xray "${REPO}files/xray_24.10.31"
#chmod +x /usr/local/bin/xray
wget -q -O /etc/xray/config.json "${REPO}files/config.json"
domain=$(cat /etc/xray/domain)
IPVPS=$(cat /etc/xray/ipvps)
print_success "Core Xray Latest Version"
clear
print_install "Memasang Konfigurasi Packet"
wget -q -O /etc/nginx/conf.d/xray.conf "${REPO}files/xray.conf"
wget -q -O /etc/nginx/nginx.conf "${REPO}files/nginx.conf"
sed -i "s/xxx/${domain}/g" /etc/nginx/conf.d/xray.conf
rm -rf /etc/systemd/system/xray.service.d
cat >/etc/systemd/system/xray.service <<EOF
Description=Xray Service
Documentation=https://t.me/zaki/tunnel
After=network.target nss-lookup.target

[Service]
User=www-data
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target

EOF
print_success "Konfigurasi Packet"
}

function ssh(){
clear
print_install "Memasang Password SSH"
wget -q -O /etc/pam.d/common-password "${REPO}files/password"
chmod +x /etc/pam.d/common-password

    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure keyboard-configuration
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/altgr select The default for the keyboard layout"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/compose select No compose key"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/ctrl_alt_bksp boolean false"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/layoutcode string de"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/layout select English"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/modelcode string pc105"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/model select Generic 105-key (Intl) PC"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/optionscode string "
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/store_defaults_in_debconf_db boolean true"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/switch select No temporary switch"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/toggle select No toggling"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/unsupported_config_layout boolean true"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/unsupported_config_options boolean true"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/unsupported_layout boolean true"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/unsupported_options boolean true"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/variantcode string "
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/variant select English"
    debconf-set-selections <<<"keyboard-configuration keyboard-configuration/xkb-keymap select "

# go to root
cd

# Edit file /etc/systemd/system/rc-local.service
cat > /etc/systemd/system/rc-local.service <<-END
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
END

# nano /etc/rc.local
cat > /etc/rc.local <<-END
#!/bin/sh -e
# rc.local
# By default this script does nothing.
exit 0
END

# Ubah izin akses
chmod +x /etc/rc.local

# enable rc local
systemctl enable rc-local
systemctl start rc-local.service

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

#update
# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
print_success "Password SSH"
}

function udp_mini(){
clear
print_install "Memasang Service Limit Quota"
cd
wget -q -O /etc/systemd/system/limitvmess.service "https://raw.githubusercontent.com/zakiii20211/V5/main/files/limitvmess.service"
wget -q -O /etc/systemd/system/limitvless.service "https://raw.githubusercontent.com/zakiii20211/V5/refs/heads/main/files/limitvless.service"
wget -q -O /etc/systemd/system/limittrojan.service "https://raw.githubusercontent.com/zakiii20211/V5/main/files/limittrojan.service"
wget -q -O /etc/systemd/system/limitshadowsocks.service "https://raw.githubusercontent.com/zakiii20211/V5/main/files/limitshadowsocks.service"
wget -q -O /etc/xray/limit.vmess "https://raw.githubusercontent.com/zakiii20211/V5/main/files/vmess" >/dev/null 2>&1
wget -q -O /etc/xray/limit.vless "https://raw.githubusercontent.com/zakiii20211/V5/main/files/vless" >/dev/null 2>&1
wget -q -O /etc/xray/limit.trojan "https://raw.githubusercontent.com/zakiii20211/V5/main/files/trojan" >/dev/null 2>&1
wget -q -O /etc/xray/limit.shadowsocks "https://raw.githubusercontent.com/zakiii20211/V5/main/files/shadowsocks" >/dev/null 2>&1
chmod +x /etc/xray/limit.vmess
chmod +x /etc/xray/limit.vless
chmod +x /etc/xray/limit.trojan
chmod +x /etc/xray/limit.shadowsocks

wget -q -O /usr/bin/limit-ip "https://raw.githubusercontent.com/zakiii20211/V5/main/files/limit-ip"
chmod +x /usr/bin/*
cd /usr/bin
sed -i 's/\r//' limit-ip
cd

#SERVICE LIMIT ALL IP
cat >/etc/systemd/system/vmip.service << EOF
[Unit]
Description=My
ProjectAfter=network.target

[Service]
WorkingDirectory=/root
ExecStart=/usr/bin/limit-ip vmip
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat >/etc/systemd/system/vlip.service << EOF
[Unit]
Description=My
ProjectAfter=network.target

[Service]
WorkingDirectory=/root
ExecStart=/usr/bin/limit-ip vlip
Restart=always

[Install]
WantedBy=multi-user.target
EOF

cat >/etc/systemd/system/trip.service << EOF
[Unit]
Description=My
ProjectAfter=network.target

[Service]
WorkingDirectory=/root
ExecStart=/usr/bin/limit-ip trip
Restart=always

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /usr/local/xdxl/
wget -q -O /usr/local/xdxl/badvpn "https://raw.githubusercontent.com/zakiii20211/V5/main/files/badvpn"
chmod +x /usr/local/xdxl/badvpn
wget -q -O /usr/local/kyt/udp-mini "https://raw.githubusercontent.com/zakiii20211/V5/main/files/udp-mini"
chmod +x /usr/local/kyt/udp-mini
wget -q -O /etc/systemd/system/udp-mini-1.service "https://raw.githubusercontent.com/zakiii20211/V5/main/files/udp-mini-1.service"
wget -q -O /etc/systemd/system/udp-mini-2.service "https://raw.githubusercontent.com/zakiii20211/V5/main/files/udp-mini-2.service"
wget -q -O /etc/systemd/system/udp-mini-3.service "https://raw.githubusercontent.com/zakiii20211/V5/main/files/udp-mini-3.service"
print_success "Limit Quota Service"
}

function ssh_slow(){
clear
print_install "Memasang modul SlowDNS Server"
wget -q -O nameserver "${REPO}slowdns/nameserver"
chmod +x nameserver
bash nameserver && rm -f nameserver
print_success "SlowDNS"
}

function ins_SSHD(){
clear
print_install "Memasang SSHD"
wget -q -O /etc/ssh/sshd_config "https://raw.githubusercontent.com/zakiii20211/V5/main/files/sshd"
chmod 700 /etc/ssh/sshd_config
/etc/init.d/ssh restart
systemctl restart ssh
/etc/init.d/ssh status
print_success "SSHD"
}

function ins_dropbear(){
clear
print_install "Install Dropbear, Press any button if too long"
# // Installing Dropbear
apt-get install dropbear -y > /dev/null 2>&1
wget -q -O /etc/default/dropbear "https://raw.githubusercontent.com/zakiii20211/V5/main/files/dropbear"
chmod +x /etc/default/dropbear
/etc/init.d/dropbear restart
/etc/init.d/dropbear status
print_success "Dropbear"
}

function ins_vnstat(){
clear
print_install "Menginstall Vnstat"
# setting vnstat
apt -y install vnstat > /dev/null 2>&1
/etc/init.d/vnstat restart
apt -y install libsqlite3-dev > /dev/null 2>&1
wget https://humdi.net/vnstat/vnstat-2.6.tar.gz
tar zxvf vnstat-2.6.tar.gz
cd vnstat-2.6
./configure --prefix=/usr --sysconfdir=/etc && make && make install
cd
vnstat -u -i $NET
sed -i 's/Interface "'""eth0""'"/Interface "'""$NET""'"/g' /etc/vnstat.conf
chown vnstat:vnstat /var/lib/vnstat -R
systemctl enable vnstat
/etc/init.d/vnstat restart
/etc/init.d/vnstat status
rm -f /root/vnstat-2.6.tar.gz
rm -rf /root/vnstat-2.6
print_success "Vnstat"
}

function ins_openvpn(){
clear
print_install "Menginstall OpenVPN"
wget -q -O openvpn.sh "https://raw.githubusercontent.com/zakiii20211/V5/main/files/openvpn"
chmod +x openvpn && ./openvpn
/etc/init.d/openvpn restart
print_success "OpenVPN"
}

function ins_backup(){
clear
print_install "Memasang Backup Server"
apt install rclone -y
printf "q\n" | rclone config
wget -q -O /root/.config/rclone/rclone.conf "${REPO}files/rclone.conf"
cd /bin
git clone  https://github.com/magnific0/wondershaper.git
cd wondershaper
sudo make install
cd
rm -rf wondershaper
echo > /home/limit
wget -q -O /etc/ipserver "${REPO}files/ipserver" && bash /etc/ipserver
print_success "Backup Server"
}

function ins_swab(){
clear
print_install "Memasang Swap"
gotop_latest="$(curl -s https://api.github.com/repos/xxxserxxx/gotop/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"
gotop_link="https://github.com/xxxserxxx/gotop/releases/download/v$gotop_latest/gotop_v"$gotop_latest"_linux_amd64.deb"
curl -sL "$gotop_link" -o /tmp/gotop.deb
dpkg -i /tmp/gotop.deb >/dev/null 2>&1

# > Buat swap sebesar 1G
dd if=/dev/zero of=/swapfile bs=1024 count=1048576
mkswap /swapfile
chown root:root /swapfile
chmod 0600 /swapfile >/dev/null 2>&1
swapon /swapfile >/dev/null 2>&1
sed -i '$ i\/swapfile      swap swap   defaults    0 0' /etc/fstab

# > Singkronisasi jam
chronyd -q 'server 0.id.pool.ntp.org iburst'
chronyc sourcestats -v
chronyc tracking -v

wget -q ${REPO}files/bbr.sh
chmod +x bbr.sh && ./bbr.sh
print_success "Swap 1 G"
}

function ins_Fail2ban(){
clear
apt -y install fail2ban
/etc/init.d/fail2ban restart
/etc/init.d/fail2ban status

# Instal DDOS Flate
if [ -d '/usr/local/ddos' ]; then
	echo; echo; echo "Please un-install the previous version first"
	#exit 0
else
	mkdir /usr/local/ddos
fi

echo "Banner /etc/issue.net" >>/etc/ssh/sshd_config
sed -i 's@DROPBEAR_BANNER=""@DROPBEAR_BANNER="/etc/issue.net"@g' /etc/default/dropbear

wget -q -O /etc/issue.net "https://raw.githubusercontent.com/zakiii20211/V5/main/files/issue.net"
}

function ins_epro(){
clear
print_install "Install ePro WebSocket Proxy"
    wget -O /usr/bin/ws "https://raw.githubusercontent.com/zakiii20211/V5/main/files/ws" >/dev/null 2>&1
    wget -O /usr/bin/tun.conf "https://raw.githubusercontent.com/zakiii20211/V5/main/files/tun.conf" >/dev/null 2>&1
    wget -O /etc/systemd/system/ws.service "https://raw.githubusercontent.com/zakiii20211/V5/main/files/ws.service" >/dev/null 2>&1
    chmod +x /etc/systemd/system/ws.service
    chmod +x /usr/bin/ws
    chmod 644 /usr/bin/tun.conf
systemctl disable ws
systemctl stop ws
systemctl enable ws
systemctl start ws
systemctl restart ws
wget -q -O /usr/local/share/xray/geosite.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat" >/dev/null 2>&1
wget -q -O /usr/local/share/xray/geoip.dat "https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat" >/dev/null 2>&1
wget -O /usr/sbin/ftvpn "https://raw.githubusercontent.com/zakiii20211/V5/main/files/ftvpn" >/dev/null 2>&1
chmod +x /usr/sbin/ftvpn
iptables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
iptables -A FORWARD -m string --string "announce_peer" --algo bm -j DROP
iptables -A FORWARD -m string --string "find_node" --algo bm -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
iptables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -A FORWARD -m string --algo bm --string "torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce" -j DROP
iptables -A FORWARD -m string --algo bm --string "info_hash" -j DROP
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload

# remove unnecessary files
cd
apt autoclean -y >/dev/null 2>&1
apt autoremove -y >/dev/null 2>&1
print_success "ePro WebSocket Proxy"
}

#Instal Menu
function menu(){
clear
mkdir -p /cache
cd /cache
wget -q -O menu.zip "${REPO}ftr/menu.zip"
unzip menu.zip
chmod +x menu/*
mv menu/* /usr/local/sbin/
cd
rm -rf /cache

wget -qO- https://raw.githubusercontent.com/zakiii20211/V5/main/version > /root/.versi

}

# Membaut Default Menu 
function profile(){
clear
cat >/root/.profile <<EOF
# ~/.profile: executed by Bourne-compatible login shells.
if [ "$BASH" ]; then
    if [ -f ~/.bashrc ]; then
        . ~/.bashrc
    fi
fi
mesg n || true
menu xdxl
EOF

cat >/etc/cron.d/xp_all <<-END
		SHELL=/bin/sh
		PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
		0 0 * * * root /usr/local/sbin/xp
	END
cat >/etc/cron.d/auto_backup <<-END
		SHELL=/bin/sh
		PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
		59 23 * * * root /usr/local/sbin/backup
	END
cat >/etc/cron.d/auto_backup2 <<-END
		SHELL=/bin/sh
		PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
		59 23 * * * root /usr/local/sbin/bkpusr
	END
	cat >/etc/cron.d/logclean <<-END
		SHELL=/bin/sh
		PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
		*/19 * * * * root /usr/local/sbin/clearlog
		END
    chmod 644 /root/.profile
	
    cat >/etc/cron.d/daily_reboot <<-END
		SHELL=/bin/sh
		PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
		0 5 * * * root /sbin/reboot
	END

    echo "*/1 * * * * root echo -n > /var/log/nginx/access.log" >/etc/cron.d/log.nginx
    echo "*/1 * * * * root echo -n > /var/log/xray/access.log" >>/etc/cron.d/log.xray
    service cron restart
    cat >/home/daily_reboot <<-END
		5
	END

cat >/etc/systemd/system/rc-local.service <<EOF
[Unit]
Description=/etc/rc.local
ConditionPathExists=/etc/rc.local
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
[Install]
WantedBy=multi-user.target
EOF

echo "/bin/false" >>/etc/shells
echo "/usr/sbin/nologin" >>/etc/shells
cat >/etc/rc.local <<EOF
#!/bin/sh -e
# rc.local
# By default this script does nothing.
iptables -I INPUT -p udp --dport 5300 -j ACCEPT
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
systemctl restart netfilter-persistent
exit 0
EOF

    chmod +x /etc/rc.local
    
    AUTOREB=$(cat /home/daily_reboot)
    SETT=11
    if [ $AUTOREB -gt $SETT ]; then
        TIME_DATE="PM"
    else
        TIME_DATE="AM"
    fi
}

# Restart layanan after install
function enable_services(){
clear
print_install "Enable Service"
echo
systemctl daemon-reload
services=(
    "nginx"
    "xray"
    "rc-local"
    "dropbear"
    "openvpn"
    "cron"
    "netfilter-persistent"
    "fail2ban"
    "rc-local"
    "ws"
    "limitvmess"
    "limitvless"
    "limittrojan"
    "limitshadowsocks"
    "vmip"
    "vlip"
    "trip"
    "udp-mini-1"
    "udp-mini-2"
    "udp-mini-3"
)
for service in "${services[@]}"; do
  systemctl enable $service &>/dev/null
  echo -ne " Enable service $service...\r"
  sleep 1
  echo -ne " Enable service $service...$green Done! $neutral\n"
done

print_success "Enable Service"
}

# Fingsi Install Script
function install_with_input_domain(){
clear
first_setup
base_package
make_folder_xray
pasang_domain
password_default
pasang_ssl
install_xray
ssh
udp_mini
ssh_slow
ins_SSHD
ins_dropbear
ins_vnstat
ins_openvpn
ins_backup
ins_swab
ins_Fail2ban
ins_epro
menu
profile
enable_services
restart_system
}

function install_with_no_input_domain() {
clear
first_setup
nginx_install
base_package
make_folder_xray
password_default
pasang_ssl
install_xray
ssh
udp_mini
ssh_slow
ins_SSHD
ins_dropbear
ins_vnstat
ins_openvpn
ins_backup
ins_swab
ins_Fail2ban
ins_epro
menu
profile
enable_services
restart_system
}

data_server=$(curl -v --insecure --silent https://google.com/ 2>&1 | grep Date | sed -e 's/< Date: //')
date_list=$(date +"%Y-%m-%d" -d "$data_server")
useexp=$(wget -qO- $url_izin | grep $IP | awk '{print $3}')
if [[ $useexp == "lifetime" || $useexp == "Lifetime" ]]; then
echo -ne
else
  if [[ $date_list < $useexp ]]; then
   echo -ne
   else
   echo -e "VPS anda tidak memiliki akses untuk script"
   exit 0
  fi
fi

if [[ $1 ]]; then
mkdir -p /etc/xray
echo "${1}" > /etc/xray/domain
install_with_no_input_domain
else
install_with_input_domain
fi

echo ""
history -c
echo "unset HISTFILE" >> /etc/profile

cd
rm -f /root/openvpn
rm -f /root/key.pem
rm -f /root/cert.pem
rm -rf /root/*.zip
rm -rf /root/*.sh
rm -rf /root/LICENSE
rm -rf /root/README.md
rm -rf $0
clear
#sudo hostnamectl set-hostname $user
secs_to_human "$(($(date +%s) - ${start}))"
sudo hostnamectl set-hostname $username
echo -e "${g}Script Successfull Installed ${NC}"
echo ""
sleep 3
reboot
