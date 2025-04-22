# 輕鬆部署 Flask + Gunicorn + systemd + nginx

這是一個適用於 Ubuntu VPS 的快速部署腳本，能將 Flask 專案透過 Gunicorn 啟動，並用 nginx 作為反向代理。支援多個專案分流，透過路徑分配與多網域共用。

---


## 1️⃣ 安裝 Git 並下載專案

### 更新系統檔案
```bash
sudo apt update && sudo apt install git -y
```

### 下載此專案並賦予腳本執行權限
```bash
git clone https://github.com/maso0310/flask_vps_deploy.git && \
cd flask_vps_deploy && \
chmod +x ./*.sh
```

## 2️⃣ 使用腳本部署 Flask 專案

### 無網域設定部署

```bash
sudo ./setup_flask_vps.sh myapp1 _
```

### 若需要部署另一個 flask 專案，可使用其他專案名稱重新建立
```bash
sudo ./setup_flask_vps.sh myapp2 _
```

📝 此處 `myapp1` 與 `myapp2` 皆為可自定義專案資料夾名稱，也是日後透過 `http://your-vps-ip/myapp1/` 或者 `http://your-vps-ip/myapp2/` 作為讀取的URL路徑。


### 建立一個有網域的專案
```bash
sudo ./setup_flask_vps.sh myapp3 mydomain.com
```

### 你也可以重複在同一個網域下新增更多子路徑專案
```bash
sudo ./setup_flask_vps.sh myapp4 mydomain.com
```

📝 此處 `myapp3` 與 `myapp4` 皆為可自定義專案資料夾名稱，與無網域名稱建立之專案差別為使用網域 `http://mydomain.com/myapp3/` 或者 `http://mydomain.com/myapp4/` 作為讀取的URL路徑。

---

## 🔁 如何移除指定專案？

```bash
### 基本用法
sudo ./uninstall.sh myapp1 _
```

### 如果是有自訂網域的話
```bash
sudo ./uninstall.sh myapp3 mydomain.com
```

此指令會完成以下工作：

- 停止並刪除 systemd 的專案服務
- 從 nginx 設定中移除對應的 location 設定
- 刪除該專案資料夾 `/opt/myapp1`，此處的 `myapp1` 是指令輸入的專案名稱
- 當所有 Flask 專案都移除後，將會自動恢復啟用 nginx 預設設定檔

---

## 📂 系統架構說明

| 功能       | 說明                               |
| -------- | -------------------------------- |
| Python   | 使用虛擬環境安裝 Flask 與 Gunicorn        |
| Gunicorn | 使用 Unix socket 啟動 Flask WSGI App |
| systemd  | 管理 Gunicorn 為服務，可開機自啟動           |
| nginx    | 負責對外入口，依據路徑做反向代理                 |

---

## ⚠️ 注意事項

- 僅適用於 Ubuntu 系統（建議版本：20.04 / 22.04）
- 若遇到 `502 Bad Gateway`，請使用 `journalctl -u 專案名` 查看 Gunicorn 啟動狀況
- 單一網域下可部署多個子路徑 Flask 專案

---

## 🙋‍♂️ 聯絡我
![LOGO](https://yt3.ggpht.com/ytc/AKedOLR7I7tw_IxwJRgso1sT4paNu2s6_4hMw2goyDdrYQ=s88-c-k-c0x00ffffff-no-rj)<br>
如果喜歡這個教學內容<br>
歡迎訂閱Youtube頻道<br>
[Maso的萬事屋](https://www.youtube.com/playlist?list=PLG4d6NSc7_l5-GjYiCdYa7H5Wsz0oQA7U)<br>
或加我私下討論 LINE ID: mastermaso<br>
