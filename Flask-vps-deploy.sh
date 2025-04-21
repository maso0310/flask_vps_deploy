#!/bin/bash

# Flask VPS 部署腳本（通用模組化版本）
# GitHub: https://github.com/你的帳號/flask-vps-deploy
# 作者：Maso 的萬事屋

# 用法：sudo bash setup_flask_vps.sh myproject yourdomain.com

set -e

# === 參數設定 ===
PROJECT_NAME=${1:-myflaskapp}
SERVICE_NAME=$PROJECT_NAME
DOMAIN_NAME=${2:-_}
PROJECT_DIR="/root/$PROJECT_NAME"
SOCK_FILE="$PROJECT_DIR/$PROJECT_NAME.sock"
PYTHON_BIN="python3"

# === 函式區 ===
function check_root() {
  if [[ $EUID -ne 0 ]]; then
    echo "❌ 請使用 sudo 權限執行此腳本"
    exit 1
  fi
}

function install_packages() {
  echo "📦 安裝必要套件..."
  apt update
  apt install $PYTHON_BIN python3-pip python3-venv nginx -y
}

function create_project_structure() {
  echo "📁 建立專案資料夾..."
  mkdir -p $PROJECT_DIR
  cd $PROJECT_DIR
  $PYTHON_BIN -m venv venv
  source venv/bin/activate
  pip install flask gunicorn
}

function generate_flask_app() {
  echo "📝 建立 Flask 程式..."
  cat > app.py << EOF
from flask import Flask
app = Flask(__name__)

@app.route("/")
def home():
    return "Hello from Gunicorn + Flask on VPS!"
EOF
}

function setup_systemd_service() {
  echo "🧩 設定 systemd..."
  cat > /etc/systemd/system/$SERVICE_NAME.service << EOF
[Unit]
Description=Gunicorn instance to serve Flask app
After=network.target

[Service]
User=root
Group=www-data
WorkingDirectory=$PROJECT_DIR
Environment=\"PATH=$PROJECT_DIR/venv/bin\"
ExecStart=$PROJECT_DIR/venv/bin/gunicorn --workers 3 --bind unix:$SOCK_FILE app:app

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reexec
  systemctl start $SERVICE_NAME
  systemctl enable $SERVICE_NAME
}

function configure_nginx() {
  echo "🌐 設定 Nginx..."
  cat > /etc/nginx/sites-available/$PROJECT_NAME << EOF
server {
    listen 80;
    server_name $DOMAIN_NAME;

    location / {
        include proxy_params;
        proxy_pass http://unix:$SOCK_FILE;
    }
}
EOF

  ln -sf /etc/nginx/sites-available/$PROJECT_NAME /etc/nginx/sites-enabled/
  nginx -t && systemctl restart nginx
}

function final_message() {
  echo "✅ 專案 $PROJECT_NAME 部署完成！"
  echo "請瀏覽：http://你的 VPS IP 或 http://$DOMAIN_NAME 查看成果"
}

# === 主程序 ===
check_root
install_packages
create_project_structure
generate_flask_app
setup_systemd_service
configure_nginx
final_message
