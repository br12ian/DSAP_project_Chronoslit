# ChronoSlit

## Proposal Report

### Motivations and Objectives
<!-- 說明為什麼想做這個專題 -->
Traditional calendar apps rely heavily on mouse interactions, which are inefficient for high-frequency scheduling. Chronoslit is a keyboard-centric macOS utility that utilizes a command-driven workflow and a lightweight HUD interface, it aims to eliminate interaction friction and provide a high-speed "scheduler kernel" for power users.

### Expected features
<!-- 列出預計實作的功能 -->
**1. Command-Driven Entry:** A specialized input hub that parses flags (e.g., -p for policy, -t for tags) to define schedule properties with zero friction. A command can be like:
```
2026/4/4 15:00-17:00 #LinearAlgebra -p hard -t study
```

**2. 7-Column Vertical Canvas:** A 80% height visualization zone displaying a weekly overview. It features vertical scrolling where seven columns (days) are indexed for real-time conflict highlighting.

**3. Occupancy Policies (```-p``` flag):**
- Hard (Immutable): A solid slice that prevents any overlaps; any conflict triggers a rejection based on the Interval Tree query.
- Soft (Informative): Allows overlaps but triggers visual warnings and color-coded alerts.
- Flexible (Fluid): A placeholder slice that can be automatically truncated or shifted by higher-priority tasks.

**4. Tag-Based Indexing (```-t``` flag):** Instantaneously filter through time slices by category defined by users (e.g., they can define some tags such as ```#sports```, ```#work``` by some special commands).

**5. Smart Gap Discovery:** Command-based search (e.g., ```find 2h```) that calculates the union of occupied slits to identify available time windows.

### Core Tech Stack
<!-- 使用的語言、框架、工具等 -->
**Language:** C++20.

**UI Framework:** Qt 6 / QML.

**Data Persistence:** JSON-based local storage.

### Development timeline
<!-- 各週預計完成的進度 -->
| Week | Schedule |
| :--- | :--- |
| **Week 8-9** | Qt/QML environment setup & core interval tree implementation. |
| **Week 10-11** | Command parser (FSM) & JSON persistence layer. |
| **Week 12-13** | 7-Column vertical UI development & coordinate mapping logic. |
| **Week 14-15** | Conflict visualization, performance tuning, and final debugging. |

### Link to DSAP
<!-- 你的專題可能涉及哪些資料結構或演算法概念？為什麼？ -->
**Interval Tree:** Manages time segments to enable Overlap Queries and Point-in-Interval Queries in $O(\log N + K)$ time, ensuring instant UI feedback.

**Command Lexical Analysis (FSM):** Processes input streams through a Finite State Machine for robust flag parsing and syntax validation.

**Greedy Interval Merging:** Implements a greedy approach to merge occupied intervals and compute the complement set for gap searching.

---

## Prototype Report

### 目前進度
<!-- 完成了什麼 -->

### 遇到的困難
<!-- 遇到什麼問題、如何解決或打算如何解決 -->

### 下一步計畫
<!-- 接下來要做什麼 -->

### 與課程的關聯
<!-- 到目前為止，你的實作中哪些部分與課程內容有關？關係是什麼？ -->

---

## Final Report

### 專案說明
<!-- 完整描述你的專案做了什麼 -->

### 使用方式
<!-- 如何編譯、執行、使用你的程式 -->

### 與課程的關聯總結
<!-- 總結你的專題與進階程式設計及資料結構課程之間的關聯 -->
