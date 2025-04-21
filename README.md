# flask\_vps\_deploy：一鍵部署 Flask + Gunicorn + systemd + nginx

這是一個適用於 Ubuntu VPS 的快速部署腳本，能將 Flask 專案透過 Gunicorn 啟動，並用 nginx 作為反向代理。支援多個專案分流，透過路徑分配與多網域共用。

---

## 🚀 快速開始

### 1️⃣ 安裝 Git 並下載專案

```bash
sudo apt update && sudo apt install git -y

# 下載腳本並賦予執行權限
git clone https://github.com/maso0310/flask_vps_deploy.git && \
cd flask_vps_deploy && \
chmod +x setup_flask_vps.sh uninstall.sh
```

### 2️⃣ 使用腳本部署 Flask 專案

```bash
# 建立一個沒有網域的專案（走 IP + 路徑）
sudo ./setup_flask_vps.sh myapp1 _

# 建立另一個專案，同樣走 IP + 路徑
sudo ./setup_flask_vps.sh myapp2 _

# 建立一個有網域的專案
sudo ./setup_flask_vps.sh myapp3 mydomain.com

# 你也可以重複在同一個網域下新增更多子路徑專案
sudo ./setup_flask_vps.sh myapp4 mydomain.com
```

📝 `myapp1` 為專案資料夾名稱，也是日後透過 `http://your-vps-ip/myapp1/` 存取的路徑。

---

## 🔁 如何移除專案？

```bash
# 基本用法
sudo ./uninstall.sh myapp1 _

# 如果是有自訂網域的話
sudo ./uninstall.sh myapp3 mydomain.com
```

此指令會完成以下工作：

- 停止並刪除 systemd 的專案服務
- 從 nginx 設定中移除對應的 location 設定
- 刪除該專案資料夾 `/opt/myapp1`
- 當所有 Flask 專案都移除後，自動恢復 nginx 預設首頁

---

## 📂 系統架構說明

| 功能       | 說明                               |
| -------- | -------------------------------- |
| Python   | 使用虛擬環境安裝 Flask 與 Gunicorn        |
| Gunicorn | 使用 Unix socket 啟動 Flask WSGI App |
| systemd  | 管理 Gunicorn 為服務，可開機自啟動           |
| nginx    | 負責對外入口，依據路徑做反向代理                 |

---

## 🔍 範例說明

- `http://your-vps-ip/myapp1/` → 對應 `/opt/myapp1/app.py`
- `http://yourdomain.com/myapp3/` → 對應 `/opt/myapp3/app.py`

---

## ⚠️ 注意事項

- 僅適用於 Ubuntu 系統（建議版本：20.04 / 22.04）
- 若遇到 `502 Bad Gateway`，請使用 `journalctl -u 專案名` 查看 Gunicorn 啟動狀況
- 單一網域下可部署多個子路徑 Flask 專案

---

## 🙋‍♂️ 聯絡我
====================================<br>
如果喜歡這個教學內容<br>
歡迎訂閱Youtube頻道<br>
[Maso的萬事屋](https://www.youtube.com/playlist?list=PLG4d6NSc7_l5-GjYiCdYa7H5Wsz0oQA7U)<br>
或加我私下討論 LINE ID: mastermaso<br>
![LOGO](https://yt3.ggpht.com/ytc/AKedOLR7I7tw_IxwJRgso1sT4paNu2s6_4hMw2goyDdrYQ=s88-c-k-c0x00ffffff-no-rj)<br>


====================================<br>

