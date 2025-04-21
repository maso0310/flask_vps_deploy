#!/bin/bash

# Flask VPS 專案清除腳本（適用於 /opt 安裝路徑）
# 用法：sudo ./uninstall.sh 專案名稱 [網域名稱]
# 範例：sudo ./uninstall.sh myapp1 _
#      sudo ./uninstall.sh myapp5 mydomain.com

set -e

PROJECT_NAME=${1:-myflaskapp}
DOMAIN_NAME=${2:-_}
PROJECT_DIR="/opt/$PROJECT_NAME"
SERVICE_FILE="/etc/systemd/system/$PROJECT_NAME.service"
SOCK_PATH="$PROJECT_DIR/$PROJECT_NAME.sock"
NGINX_SITE="/etc/nginx/sites-available/flask_projects_${DOMAIN_NAME//./_}"
NGINX_LINK="/etc/nginx/sites-enabled/$(basename $NGINX_SITE)"

echo "🧹 開始移除 Flask 專案：$PROJECT_NAME (domain: $DOMAIN_NAME)"

# ========== 停止並移除 systemd 服務 ==========
if systemctl list-units --full -all | grep -q "$PROJECT_NAME.service"; then
    echo "🛑 停止並移除 systemd 服務..."
    systemctl stop $PROJECT_NAME
    systemctl disable $PROJECT_NAME
    rm -f $SERVICE_FILE
    echo "✅ systemd 服務已刪除"
else
    echo "⚠️ 找不到 systemd 服務，略過"
fi

# ========== 從 nginx 設定中移除該 location ==========
if [ -f "$NGINX_SITE" ]; then
    if grep -q "location /$PROJECT_NAME/" "$NGINX_SITE"; then
        echo "🗑️ 移除 nginx 設定中的 location /$PROJECT_NAME/"
        sed -i "/location \\/$PROJECT_NAME\\//,/^ *}/d" "$NGINX_SITE"
        echo "✅ 已從 nginx 設定中移除 location"

        # 如果刪完後，裡面已無任何 location，就刪整個檔案
        if ! grep -q "location /" "$NGINX_SITE"; then
            echo "📭 該 nginx 設定已無其他專案，將一併刪除"
            rm -f "$NGINX_SITE" "$NGINX_LINK"
        fi

        nginx -t && systemctl restart nginx
    else
        echo "⚠️ 未在 nginx 設定中找到 /$PROJECT_NAME/，略過"
    fi
else
    echo "⚠️ 找不到對應的 nginx 設定檔 $NGINX_SITE，略過"
fi

# ========== 刪除專案資料夾 ==========
if [ -d "$PROJECT_DIR" ]; then
    echo "🧨 刪除專案目錄 $PROJECT_DIR"
    rm -rf "$PROJECT_DIR"
    echo "✅ 專案資料夾已刪除"
else
    echo "⚠️ 專案資料夾不存在，略過"
fi

# ========== 如果已無任何 flask_projects 設定檔，還原 nginx default ==========
REMAINING_FLASK_FILES=$(find /etc/nginx/sites-available/ -maxdepth 1 -type f -name 'flask_projects_*')

if [ -z "$REMAINING_FLASK_FILES" ]; then
    echo "🌱 已無任何 Flask 專案設定，還原 nginx 預設首頁..."

    # 移除其他重複的 server_name _ 設定（避免 nginx 警告）
    find /etc/nginx/sites-enabled/ -type l -exec grep -l "server_name _;" {} \; | xargs rm -f   
    ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
    nginx -t && systemctl restart nginx
    echo "✅ 已還原 nginx 預設首頁"
else
    echo "📂 尚有其他 Flask 專案設定，略過還原預設首頁"
fi

echo "🧼 清理完成！"
