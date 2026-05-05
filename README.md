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


### Competitve analysis for Chronoslit
> See [Competitive Analysis](docs/competitive_analysis.md) for a comparison with existing CLI-based tools.

### Prototype Expected Verification Content

Focus on three basic things: 
1. Regex parsing from CLI inputs

2. Overlap algorithm with interval tree

3. Basic UI Integration to ensure the C++ backend correctly triggers dynamic rendering on the QML frontend.
---

## Prototype Report

### Current progress
<!-- 完成了什麼 -->

### Faced challenges
<!-- 遇到什麼問題、如何解決或打算如何解決 -->

### Next steps
<!-- 接下來要做什麼 -->

---

## Final Report

### 專案說明
<!-- 完整描述你的專案做了什麼 -->

### 使用方式
<!-- 如何編譯、執行、使用你的程式 -->

