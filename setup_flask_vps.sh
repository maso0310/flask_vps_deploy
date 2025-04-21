#!/bin/bash

# 使用 sudo 執行整個腳本
if [[ $EUID -ne 0 ]]; then
   echo "請用 sudo 執行這個腳本：sudo bash setup_flask_vps.sh"
   exit 1
fi

PROJECT_NAME="myflaskapp"
SERVICE_NAME="myflask"
SOCK_PATH="/root/$PROJECT_NAME/$PROJECT_NAME.sock"
WORK_DIR="/root/$PROJECT_NAME"

echo "🚀 開始部署 Flask 專案到 VPS..."

# 更新套件列表
apt update

# 安裝 Python3 與 pip
apt install python3 python3-pip python3-venv nginx -y

# 建立 Flask 專案資料夾
mkdir -p $WORK_DIR
cd $WORK_DIR

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
WorkingDirectory=$WORK_DIR
Environment="PATH=$WORK_DIR/venv/bin"
ExecStart=$WORK_DIR/venv/bin/gunicorn --workers 3 --bind unix:$SOCK_PATH app:app

[Install]
WantedBy=multi-user.target
EOF

# 啟用並啟動服務
systemctl daemon-reexec
systemctl start $SERVICE_NAME
systemctl enable $SERVICE_NAME

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
ln -s /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx

echo "✅ 部署完成！請在瀏覽器輸入你的 VPS IP 檢查成果：應該會顯示 Hello from Gunicorn + Flask on VPS!"
