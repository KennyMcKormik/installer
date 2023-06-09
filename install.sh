#!/bin/bash
# Update package index and install dependencies

case $1 in
-u)
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge
    rm -rf ~/vless-client.json
    echo "done."
    exit 0
    ;;
*)
    echo -e "${Error} ${RedBG} installing... ${Font}"
    ;;
esac



# Update package index and install dependencies
sudo apt-get update
sudo apt-get install -y jq openssl qrencode

curl -s https://raw.githubusercontent.com/sajjaddg/xray-reality/master/default.json > config.json

# Extract the desired variables using jq
name="Vless-reality-custom"
email="kennymckormik@github.com"
port=443
sni="yahoo.com"
path="%2F"

if [ -n "$2" ]; then
    port="$2"
fi

bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --beta

json=$(curl -s https://raw.githubusercontent.com/KennyMcKormik/installer/main/default.json)

keys=$(xray x25519)
pk=$(echo "$keys" | awk '/Private key:/ {print $3}')
pub=$(echo "$keys" | awk '/Public key:/ {print $3}')
serverIp=$(curl -s ipv4.wtfismyip.com/text)
uuid=$(xray uuid)
shortId=$(openssl rand -hex 8)

url="vless://$uuid@$serverIp:$port?type=http&security=reality&encryption=none&pbk=$pub&fp=chrome&path=$path&sni=$sni&sid=$shortId#$name"

newJson=$(echo "$json" | jq \
    --arg pk "$pk" \
    --arg uuid "$uuid" \
    --arg port "$port" \
    --arg sni "$sni" \
    --arg path "$path" \
    --arg email "$email" \
    '.inbounds[0].port= '"$(expr "$port")"' |
     .inbounds[0].settings.clients[0].email = $email |
     .inbounds[0].settings.clients[0].id = $uuid |
     .inbounds[0].streamSettings.realitySettings.dest = $sni + ":443" |
     .inbounds[0].streamSettings.realitySettings.serverNames += ["'$sni'", "www.'$sni'"] |
     .inbounds[0].streamSettings.realitySettings.privateKey = $pk |
     .inbounds[0].streamSettings.realitySettings.shortIds += ["'$shortId'"]')

echo "$newJson" | sudo tee /usr/local/etc/xray/config.json >/dev/null
sudo systemctl restart xray

cat >~/reality.json <<-EOF

{
  "dns": {
    "hosts": {
      "domain:googleapis.cn": "googleapis.com"
    },
    "servers": [
      "1.1.1.1"
    ]
  },
  "inbounds": [
    {
      "listen": "127.0.0.1",
      "port": 10808,
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true,
        "userLevel": 8
      },
      "sniffing": {
        "destOverride": [
          "http",
          "tls"
        ],
        "enabled": true
      },
      "tag": "socks"
    },
    {
      "listen": "127.0.0.1",
      "port": 10809,
      "protocol": "http",
      "settings": {
        "userLevel": 8
      },
      "tag": "http"
    }
  ],
  "log": {
    "loglevel": "warning"
  },
  "outbounds": [
    {
      "mux": {
        "concurrency": 8,
        "enabled": false
      },
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "$serverIp",
            "port": $port,
            "users": [
              {
                "encryption": "none",
                "flow": "",
                "id": "$uuid",
                "level": 8,
                "security": "auto"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "httpSettings": {
          "host": [],
          "path": "/"
        },
        "network": "h2",
        "realitySettings": {
          "allowInsecure": false,
          "fingerprint": "chrome",
          "publicKey": "$pub",
          "serverName": "$sni",
          "shortId": "$shortId",
          "show": true,
          "spiderX": ""
        },
        "security": "reality"
      },
      "tag": "proxy"
    },
    {
      "protocol": "freedom",
      "settings": {},
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {
        "response": {
          "type": "http"
        }
      },
      "tag": "block"
    }
  ],
  "routing": {
    "domainMatcher": "mph",
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "ip": [
          "1.1.1.1"
        ],
        "outboundTag": "proxy",
        "port": "53",
        "type": "field"
      },
      {
        "ip": [
          "geoip:ir"
        ],
        "outboundTag": "direct",
        "type": "field"
      }
    ]
  }
}

EOF

echo "$url"

qrencode -s 120 -t ANSIUTF8 "$url"


exit 0
