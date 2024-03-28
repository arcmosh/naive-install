#!/bin/bash

until [ -n "$domain" ]
do
	read -p "Enter your domain: " domain
done
IPV4=$(wget -qO- ipv4.ip.sb)
IPV6=$(wget -qO- ipv6.ip.sb)
echo "请确认你已经设置好域名解析 指向 $IPV4 或$IPV6 "

read -p "按下回车键继续..."

export UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)}

## set BBR advance network optmized.
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p >/dev/null 

wget -O /etc/systemd/system/caddy.service  https://raw.githubusercontent.com/arcmosh/naive-install/main/caddy.service
wget https://github.com/klzgrad/forwardproxy/releases/download/v2.7.6-naive/caddy-forwardproxy-naive.tar.xz
tar -xf caddy-forwardproxy-naive.tar.xz
mv caddy-forwardproxy-naive/caddy /usr/bin/caddy
rm -rf caddy-forwardproxy-naive*

# config Caddyfile
mkdir -p /etc/caddy
cat > /etc/caddy/Caddyfile <<-EOF
{
  order forward_proxy before respond
}
:443, ${domain} {
  tls me@${domain}
  forward_proxy {
    basic_auth $UUID $UUID
    hide_ip
    hide_via
    probe_resistance
  }
  respond "200" 200
}
EOF

systemctl start caddy
systemctl enable caddy

echo "-----------------------------"
echo "naive+https://$UUID:$UUID@$domain:443#Naive-h2"
echo "naive+quic://$UUID:$UUID@$domain:443#Naive-QUIC"
