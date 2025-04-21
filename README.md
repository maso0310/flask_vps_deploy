# flask_vps_deploy
一鍵部署 Flask + Gunicorn + systemd + nginx 的 VPS 架站腳本，適用於 Ubuntu 系統的 Python 網頁應用伺服器

# 1. 進入主目錄（或你想放的位置）
cd ~

# 2. 下載專案
git clone https://github.com/maso0310/flask_vps_deploy.git

# 3. 進入資料夾
cd flask_vps_deploy

# 4. 給予執行權限（只需一次）
chmod +x Flask-vps-deploy.sh

# 5. 執行腳本（參數說明如下）
sudo ./Flask-vps-deploy.sh myproject mydomain.com
