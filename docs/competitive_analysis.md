# 競品分析

### 概述

本文件將 ChronoSlit 與現有 CLI 排程工具進行比較，說明其設計定位與差異化優勢。
ChronoSlit 的目標用戶是重度鍵盤使用者與開發者。現有工具大多專注於任務追蹤或雲端同步，而 ChronoSlit 定位為一個本地優先、具備衝突感知能力的排程核心，以指令驅動的方式實現零摩擦的高速排程。

### 以下是幾個主要競品可以拿來比較：

| 工具 | 語言 | 特點 | 與 ChronoSlit 的差異 |
| :--- | :--- | :--- | :--- |
| **calcurse** | C | TUI 介面，整合 to-do 與日曆，適合 Linux server 使用者 | 無 flag 式指令語法、無衝突偵測政策 |
| **khal** | Python | 支援 CalDAV，可透過 vdirsyncer 與 Google/Apple Calendar 雙向同步 | 無 interval tree 衝突查詢、無 `-p` 政策層 |
| **remind** | C | 強大的提醒腳本語言 | 無視覺化 HUD、語法學習曲線高 |
| **Taskwarrior + Timewarrior** | C++ | 任務追蹤 + 時間記錄 | 偏向事後記錄，非即時衝突預防 |
| **gcalcli** | Python | 從終端機直接操作 Google Calendar | 依賴雲端，無本地 interval tree 運算 |

差異化亮點：
1. Hard / Soft / Flexible 三層佔用政策（-p flag）
現有 CLI 工具幾乎沒有提供多層級衝突政策的機制。ChronoSlit 允許使用者為每個時間區塊定義「權重」：
  - Hard：不可變更，任何重疊的新事件都會被拒絕
  - Soft：允許重疊，但會觸發視覺警告與色彩提示
  - Flexible：佔位區塊，可被優先級更高的任務自動移位
  
2. ``find 2h`` 智慧空檔搜尋（競品基本沒有這個功能）

3. 純本地 + JSON 持久化（無需網路、無隱私疑慮）

4. $O(log N)$ 衝突偵測：基於 Interval Tree，查詢速度遠優於其他工具的線性掃描，時間表越密集越明顯

### 定位總結

ChronoSlit 是目前唯一同時具備指令式輸入、三層佔用政策、 $O(log N)$ 衝突偵測與智慧空檔搜尋的本地 CLI 排程工具，專為高頻排程需求的鍵盤導向使用者設計。
