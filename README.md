# flask_vps_deploy

一鍵部署 Flask + Gunicorn + systemd + nginx 的 VPS 架站腳本，適用於 Ubuntu 系統的 Python 網頁應用伺服器。

---

## 🚀 功能簡介
- 適用於 Ubuntu VPS 的 Python Web App 一鍵部署
- 自動建立 Flask 專案、虛擬環境與必要套件
- 使用 Gunicorn 作為 WSGI server
- 使用 systemd 管理開機自動啟動服務
- 整合 nginx 做反向代理並處理 .sock 溝通

---

## 📦 快速開始

### 1️⃣ SSH 登入你的 VPS 後，輸入：
```bash
sudo apt update && sudo apt install git -y
```

### 2️⃣ 克隆專案並執行部署腳本
```bash
git clone https://github.com/maso0310/flask_vps_deploy.git && \
cd flask_vps_deploy && \
chmod +x Flask-vps-deploy.sh && \
sudo ./Flask-vps-deploy.sh myapp yourdomain.com
```

- `myapp`：你要建立的 Flask 專案名稱
- `yourdomain.com`：你的網域名稱（如果沒有請輸入 `_` 代表預設通配）

### ✅ 成功後打開瀏覽器：
- 若無網域：`http://你的VPS IP`
- 若有網域：`http://yourdomain.com`

將會看到畫面顯示：
```
Hello from Gunicorn + Flask on VPS!
```

---

## 🔍 腳本做了哪些事

| 類別   | 操作內容 |
|--------|-----------|
| Linux  | 安裝 Python3 / pip / nginx，建立虛擬環境 |
| Flask  | 建立 app.py，安裝 flask 與 gunicorn |
| systemd | 建立並啟用服務單元檔，使專案開機自動啟動 |
| nginx  | 撰寫設定檔、設定反向代理，使用 Unix socket 溝通 |

---

## 🧹 如何還原安裝內容（uninstall.sh）

若你想清除這次部署的內容，可以使用我們提供的 `uninstall.sh`：

```bash
sudo ./uninstall.sh myapp
```

這會執行以下操作：
- 停止並移除 systemd 服務
- 刪除 nginx 設定檔與啟用連結
- 刪除 `/root/myapp` 專案資料夾

**注意：這不會移除你安裝的 Python/nginx 套件。**

---

## 🛠 常見錯誤排解

### ❌ `nginx: [emerg] bind() to 0.0.0.0:80 failed`：
說明已有其他程式佔用 80 port，請使用以下方式排查：
```bash
sudo lsof -i :80
sudo systemctl stop apache2
```

---

## 📝 範例截圖（可自行加入）
你可以在此放上幾張畫面截圖：
- `部署後 nginx 顯示成功頁面`
- `systemctl status myapp` 顯示 active (running)

---

## 📜 授權 License
MIT License

你可以自由使用、修改與商用此腳本，請保留作者資訊。
