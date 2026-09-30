#!/bin/bash
set -e

echo "=== Installing Go ==="
wget -q https://go.dev/dl/go1.23.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.23.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc

echo "=== Cloning wireproxy ==="
git clone https://github.com/windtf/wireproxy.git
cd wireproxy
go build -o wireproxy_bin .
cd ..

echo "=== WireGuard Config ==="
cat > wireproxy.conf << 'WGCNF'
[Interface]
Address = 10.0.7.252/32
PrivateKey = gF3JKiU9+AX1wTXvmHQabtDsSKfUjxhNB6Q2sdzwXGU=
DNS = 1.1.1.1
MTU = 8921

[Peer]
PublicKey = JGU+UxrfkDTr5DdQCLcT78MxiPuiebUrEJG4ek8vuT0=
PresharedKey = 1Yiwec1mhk/5I6u/R/iFYGBxv6JxJzlWnsDfdBG3dLI=
Endpoint = 52.51.233.22:33333
PersistentKeepalive = 30

[Socks5]
BindAddress = 127.0.0.1:25344

[http]
BindAddress = 127.0.0.1:25345
WGCNF

echo "=== Starting wireproxy ==="
cd wireproxy
./wireproxy_bin -c ../wireproxy.conf &
WIREPROXY_PID=$!
echo "wireproxy PID: $WIREPROXY_PID"

echo "=== Waiting for wireproxy to start ==="
sleep 5

echo "=== Testing VPN connection ==="
curl -s --socks5 127.0.0.1:25344 -o /dev/null -w "app.pwn: %{http_code}\n" https://app.pwn.intigriti.rocks/ --max-time 10 || echo "app.pwn failed"
curl -s --socks5 127.0.0.1:25344 -o /dev/null -w "api.pwn: %{http_code}\n" https://api.pwn.intigriti.rocks/ --max-time 10 || echo "api.pwn failed"

echo "=== Done ==="
echo "SOCKS5 proxy: 127.0.0.1:25344"
echo "HTTP proxy: 127.0.0.1:25345"