#!/bin/bash

# 使用 sudo 執行整個腳本
if [[ $EUID -ne 0 ]]; then
   echo "請用 sudo 權限執行這個腳本，例如：sudo bash setup_flask_vps.sh"
   exit 1
fi

# === 可修改變數 ===
PROJECT_NAME="myflaskapp"
SERVICE_NAME=$PROJECT_NAME
INSTALL_DIR="/opt/$PROJECT_NAME"
SOCK_PATH="$INSTALL_DIR/$PROJECT_NAME.sock"

echo "🚀 開始部署 Flask 專案到 VPS..."

# 安裝必要套件
apt update
apt install python3 python3-pip python3-venv nginx lsof -y

# 建立 Flask 專案資料夾
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# 建立虛擬環境
python3 -m venv venv
source venv/bin/activate

# 安裝 Flask 與 Gunicorn
pip install flask gunicorn

# 撰寫 app.py
cat > app.py << EOF
from flask import Flask
app = Flask(__name__)

@app.route("/")
def home():
    return "Hello from Gunicorn + Flask on VPS!"
EOF

# 建立 systemd 服務
cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=Gunicorn instance to serve Flask app
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

# 啟動 systemd 並等待建立 .sock
systemctl daemon-reexec
systemctl start $SERVICE_NAME
sleep 1  # 稍等 socket 建立完成

# 修正 .sock 權限給 nginx 使用
if [ -S "$SOCK_PATH" ]; then
    chown root:www-data "$SOCK_PATH"
    chmod 766 "$SOCK_PATH"
    echo "✅ .sock 權限已設定完成"
else
    echo "❌ 錯誤：.sock 檔案未建立，請使用 'journalctl -u $SERVICE_NAME' 檢查 Gunicorn 啟動錯誤"
    exit 1
fi

# 移除 nginx 預設首頁
rm -f /etc/nginx/sites-enabled/default

# 建立 nginx 設定檔
cat > /etc/nginx/sites-available/$PROJECT_NAME << EOF
server {
    listen 80;
    server_name _;

    location / {
        include proxy_params;
        proxy_pass http://unix:$SOCK_PATH;
    }
}
EOF

# 啟用 nginx 設定
ln -sf /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

echo ""
echo "✅ 部署完成！請打開瀏覽器輸入你的 VPS IP 查看成果："
echo "👉 預期畫面應顯示：Hello from Gunicorn + Flask on VPS!"
