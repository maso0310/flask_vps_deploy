#!/bin/bash

# ========= 權限與參數檢查 =========
if [[ $EUID -ne 0 ]]; then
   echo "請用 sudo 權限執行：sudo bash setup_flask_vps.sh 專案名稱 [網域名稱]"
   exit 1
fi

PROJECT_NAME=${1:-myflaskapp}
DOMAIN_NAME=${2:-_}
SERVICE_NAME=$PROJECT_NAME
INSTALL_DIR="/opt/$PROJECT_NAME"
SOCK_PATH="$INSTALL_DIR/$PROJECT_NAME.sock"
NGINX_SITE="/etc/nginx/sites-available/flask_projects_${DOMAIN_NAME//./_}"

echo "🚀 開始部署 Flask 專案 [$PROJECT_NAME] 到 VPS（網域：$DOMAIN_NAME）..."

# ========= 安裝必要套件 =========
apt update
apt install python3 python3-pip python3-venv nginx lsof curl -y

# ========= 建立虛擬環境與 Flask 專案 =========
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

python3 -m venv venv
source venv/bin/activate
pip install flask gunicorn

# ========= 建立 app.py =========
cat > app.py << EOF
from flask import Flask
from werkzeug.middleware.dispatcher import DispatcherMiddleware

real_app = Flask(__name__)

@real_app.route("/")
def home():
    return "Hello from Gunicorn + Flask on VPS at /$PROJECT_NAME/"

app = DispatcherMiddleware(lambda environ, start_response: (
    start_response('404 Not Found', [('Content-Type', 'text/plain')]) or [b'Not Found']),
    {
        "/$PROJECT_NAME": real_app
    }
)
EOF

# ========= 建立 systemd 服務 =========
cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=Gunicorn instance to serve Flask app [$PROJECT_NAME]
After=network.target

[Service]
User=root
Group=www-data
WorkingDirectory=$INSTALL_DIR
Environment="PATH=$INSTALL_DIR/venv/bin"
ExecStart=$INSTALL_DIR/venv/bin/gunicorn --workers 3 --bind unix:$SOCK_PATH app:app

[Install]
WantedBy=multi-user.target
EOF

# ========= 啟動 Gunicorn 並設定 socket 權限 =========
systemctl daemon-reexec
systemctl start $SERVICE_NAME
sleep 1

if [ -S "$SOCK_PATH" ]; then
    chown root:www-data "$SOCK_PATH"
    chmod 766 "$SOCK_PATH"
    echo "✅ .sock 權限已設定完成"
else
    echo "❌ Gunicorn 未正確啟動，請檢查 journalctl -u $SERVICE_NAME"
    exit 1
fi

# ========= 設定 Nginx =========
echo "🌐 設定 Nginx location /$PROJECT_NAME/ for $DOMAIN_NAME"

# 移除 default 頁面（僅第一次有效）
rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

# 若該 domain 的 nginx 設定不存在，先建立基本框架
if [ ! -f "$NGINX_SITE" ]; then
    cat > "$NGINX_SITE" << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    # ↓ location 區段將在這裡插入 ↓
}
EOF
fi

# 若該 location 尚未存在，插入
if ! grep -q "location /$PROJECT_NAME/" "$NGINX_SITE"; then
    sed -i "/# ↓ location 區段將在這裡插入 ↓/a \\
    location /$PROJECT_NAME/ {\n\
        include proxy_params;\n\
        proxy_pass http://unix:$SOCK_PATH;\n\
    }" "$NGINX_SITE"
    echo "✅ 已新增 /$PROJECT_NAME/ 到 $NGINX_SITE"
else
    echo "⚠️ 已存在 /$PROJECT_NAME/，略過新增"
fi

# 啟用此站台（可重複）
ln -sf "$NGINX_SITE" "/etc/nginx/sites-enabled/$(basename $NGINX_SITE)"

# 重啟 nginx
nginx -t && systemctl restart nginx

# ========= 結尾 =========
echo ""
echo "✅ 專案 [$PROJECT_NAME] 部署完成！"
# ========= 顯示完整測試網址 =========
echo ""

if [ "$DOMAIN_NAME" == "_" ]; then
    PUBLIC_IP=$(curl -s https://api.ipify.org)
    echo "🌐 測試網址： http://$PUBLIC_IP/$PROJECT_NAME/"
else
    echo "🌐 測試網址： http://$DOMAIN_NAME/$PROJECT_NAME/"
fi

echo "🎉 請直接在瀏覽器中貼上以上網址測試！"
