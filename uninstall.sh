#!/bin/bash

# Flask VPS 專案清除腳本
# 用法：sudo ./uninstall.sh myproject

set -e

PROJECT_NAME=${1:-myflaskapp}
PROJECT_DIR="/root/$PROJECT_NAME"
SERVICE_FILE="/etc/systemd/system/$PROJECT_NAME.service"
NGINX_SITE="/etc/nginx/sites-available/$PROJECT_NAME"
NGINX_LINK="/etc/nginx/sites-enabled/$PROJECT_NAME"

echo "🧹 開始移除 Flask 專案：$PROJECT_NAME"

# 停止並移除 systemd 服務
if systemctl list-units --full -all | grep -q "$PROJECT_NAME.service"; then
    systemctl stop $PROJECT_NAME
    systemctl disable $PROJECT_NAME
    rm -f $SERVICE_FILE
    echo "✅ systemd 服務已移除"
else
    echo "⚠️ systemd 服務不存在，略過"
fi

# 移除 nginx 設定
rm -f $NGINX_SITE
rm -f $NGINX_LINK

# 還原 nginx 預設 default 設定檔（若不存在）
if [ ! -f /etc/nginx/sites-available/default ]; then
    echo "🌱 還原 nginx 預設 default 設定檔..."
    cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    root /var/www/html;

    index index.html index.htm index.nginx-debian.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
    echo "✅ nginx 預設 default 設定檔已還原"
fi

systemctl restart nginx
echo "✅ nginx 設定已清除並重啟"

# 移除專案資料夾
rm -rf $PROJECT_DIR
echo "✅ 專案資料夾已刪除：$PROJECT_DIR"

echo "🧼 清理完成！"
