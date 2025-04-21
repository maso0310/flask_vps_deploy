#!/bin/bash

# ========== 參數處理 ==========
if [[ $EUID -ne 0 ]]; then
   echo "請用 sudo 權限執行：sudo bash setup_flask_vps.sh 專案名稱"
   exit 1
fi

PROJECT_NAME=${1:-myflaskapp}
SERVICE_NAME=$PROJECT_NAME
INSTALL_DIR="/opt/$PROJECT_NAME"
SOCK_PATH="$INSTALL_DIR/$PROJECT_NAME.sock"
NGINX_SITE="/etc/nginx/sites-available/flask_projects"

echo "🚀 開始部署 Flask 專案 [$PROJECT_NAME] 到 VPS..."

# ========== 安裝必要套件 ==========
apt update
apt install python3 python3-pip python3-venv nginx lsof -y

# ========== 建立專案資料夾與虛擬環境 ==========
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

python3 -m venv venv
source venv/bin/activate
pip install flask gunicorn

# ========== 建立 Flask 程式 ==========
cat > app.py << EOF
from flask import Flask
app = Flask(__name__)

@app.route("/")
def home():
    return "Hello from Gunicorn + Flask on VPS at /$PROJECT_NAME/"
EOF

# ========== 建立 systemd 服務 ==========
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

# 啟動 Gunicorn 並設定 .sock 權限
systemctl daemon-reexec
systemctl start $SERVICE_NAME
sleep 1

if [ -S "$SOCK_PATH" ]; then
    chown root:www-data "$SOCK_PATH"
    chmod 766 "$SOCK_PATH"
    echo "✅ .sock 權限已設定完成"
else
    echo "❌ 錯誤：Gunicorn 未正確啟動，請使用 'journalctl -u $SERVICE_NAME' 檢查錯誤"
    exit 1
fi

# ========== 建立/更新統一 Nginx 設定檔 ==========
echo "🌐 設定 nginx location /$PROJECT_NAME/ ..."

# 移除預設 default 頁面（只做一次）
rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

# 如果設定檔不存在，建立 server block 結構
if [ ! -f "$NGINX_SITE" ]; then
    cat > "$NGINX_SITE" << EOF
server {
    listen 80;
    server_name _;

    # 各專案 location 將會插入此區塊
}
EOF
fi

# 檢查是否已存在該專案的 location
if ! grep -q "location /$PROJECT_NAME/" "$NGINX_SITE"; then
    sed -i "/# 各專案 location 將會插入此區塊/a \\
    location /$PROJECT_NAME/ {\n\
        include proxy_params;\n\
        proxy_pass http://unix:$SOCK_PATH;\n\
    }" "$NGINX_SITE"
    echo "✅ location /$PROJECT_NAME/ 已新增至 Nginx"
else
    echo "⚠️ Nginx 中已存在 location /$PROJECT_NAME/，略過"
fi

ln -sf "$NGINX_SITE" /etc/nginx/sites-enabled/flask_projects
nginx -t && systemctl restart nginx

# ========== 結尾提示 ==========
echo ""
echo "✅ 專案 [$PROJECT_NAME] 部署完成！"
echo "👉 請開啟：http://your-vps-ip/$PROJECT_NAME/"
echo "✨ 預期畫面：Hello from Gunicorn + Flask on VPS at /$PROJECT_NAME/"
