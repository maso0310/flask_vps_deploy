# flask_vps_deploy
一鍵部署 Flask + Gunicorn + systemd + nginx 的 VPS 架站腳本，適用於 Ubuntu 系統的 Python 網頁應用伺服器

## ✅ 在 VPS 上執行這個腳本的完整流程：

```bash
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
```

---

## 🔧 腳本參數說明

| 參數               | 說明 |
|--------------------|------|
| `myproject`        | 專案名稱，例如 `chatbot_api`，系統會建立 `/root/chatbot_api` 等相關資料夾與設定 |
| `mydomain.com`     | 網域名稱，若沒有可填 `_`，會自動套用 nginx 通配設定 |

---

## 📝 範例：沒綁定網域的基本 VPS 測試

```bash
sudo ./Flask-vps-deploy.sh testapp _
```

部署完成後，開瀏覽器輸入你的 VPS IP，即可看到：
```
Hello from Gunicorn + Flask on VPS!
```

---

```bash
# 一鍵執行部署（無網域版）
git clone https://github.com/maso0310/flask_vps_deploy.git && \
cd flask_vps_deploy && \
chmod +x Flask-vps-deploy.sh && \
sudo ./Flask-vps-deploy.sh myapp _
```
