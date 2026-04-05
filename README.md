# ChronoSlit

## Proposal Report

### Motivations and Objectives
<!-- 說明為什麼想做這個專題 -->
Modern scheduling tools often lack the precision and speed required by power users, since we wiil have to click on the time bar in order to modify our schedule. **Chronoslit** is a native macOS application designed to treat time as a continuous fabric that can be precisely "slit" and managed through a command-driven workflow.

By prioritizing keyboard-centric input and hardware-accelerated timeline visualization, Chronoslit aims to eliminate the friction of traditional mouse-heavy calendars. The objective is to provide a "scheduler kernel" where users can define time occupancy with granular policies and lightning-fast execution.

### Expected features
<!-- 列出預計實作的功能 -->
**1. Command-Driven Slicing:** A specialized input hub that parses complex flags to define a slice's properties with minimal friction:
```
2026/4/4 15:00-17:00 #LinearAlgebra -p hard -t study
```

**2. Interactive Slit View (Timeline):** A horizontal timeline where every time "slit" is a manipulatable object. It supports click-to-inspect for details and drag-to-adjust for manual refinements.

A hardware-accelerated horizontal timeline where every time "slit" is a manipulatable object:

- Direct Interaction: Supports **click-to-inspect** for event details and **drag-to-adjust** for rapid manual refinements.

- Visual Fidelity & Real-time Feedback:
  - Policy-Based Visuals: ```Hard``` slits are rendered as solid, high-contrast blocks, while Flexible slits use semi-transparent gradients.
  - Collision Highlighting: Triggers a visual "pulse" or glow effect when a command results in a scheduling conflict.
  - Fluid 60FPS UI: Leveraging QML's scene graph for butter-smooth zooming and panning.

**3. Occupancy Policies (```-p``` flag):**
- Hard (Immutable): A solid slice that prevents any overlaps; any conflict triggers a rejection based on the Interval Tree query.
- Soft (Informative): Allows overlaps but triggers visual warnings and color-coded alerts.
- Flexible (Fluid): A placeholder slice that can be automatically truncated or shifted by higher-priority tasks.

**4. Tag-Based Indexing (```-t``` flag):**
- Instantaneously filter through time slices by category defined by users (e.g., ```#sports```, ```#work```) using a high-speed Hash Map system.

**5. Smart Gap Searching:**
- Use commands like ```find 2h``` to locate the next available continuous 2-hour window.
- Automatically calculates the union of all occupied slits to derive the "free-time" complement set.

### Core Tech Stack
<!-- 使用的語言、框架、工具等 -->
**Language:** C++20 (Algorithm engine & Command parsing).

**UI Framework:** Qt 6 / QML (Fluid animations, hardware-accelerated rendering, and modern macOS aesthetics).

**Data Persistence:** JSON-based local storage to ensure zero-latency startup and complete user data privacy.

### Development timeline
<!-- 各週預計完成的進度 -->
| Week | Schedule |
| :--- | :--- |
| **Week 1-2** | Environment setup (Qt/QML) and core C++ Backend (Interval Tree & Command Parser). |
| **Week 3-4** | Implementation of the Overlap Policy logic and Data Persistence layer. |
| **Week 5-6** | QML Timeline Visualization and Interactive Mouse-to-Slit handling. |
| **Week 7-8** | UI/Animation polishing, final debugging, and performance benchmarking. |

### Link to DSAP
<!-- 你的專題可能涉及哪些資料結構或演算法概念？為什麼？ -->
The architecture of **Chronoslit** is built upon rigorous data handling and algorithmic efficiency:

- **Interval Tree:** The primary structure for managing time slits. It handles **Overlap Queries** and **Point-in-Interval Queries** in $O(\log N + K)$ time. This ensures the UI remains responsive and provides instantaneous conflict detection as the user types.
- **Command Lexical Analysis:** Instead of simple string splitting, Chronoslit employs **Lexical Analysis** logic to parse commands. By treating input as a stream of tokens processed through a **Finite State Machine (FSM)**, the engine ensures robust parsing of flags like ```-p``` and ```-t```.
- **Greedy Interval Merging & Gap Searching:** To implement "Smart Gap Discovery" (e.g., finding the next available 2-hour window), the engine performs an **Interval Merging** algorithm. This involves sorting existing slits and performing a linear scan to identify the empty spaces—a classic application of greedy algorithms.
 
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
