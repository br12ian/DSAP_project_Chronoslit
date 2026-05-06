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
- **Core data structure:** Interval tree implementation. It can handle event insertion and time overlapping problem.

- **CLI parsing engine:** Developed a robust Regex-based parser within the ``SchedulerController`` so that the command can be executed.

- **Basic system integration:** Connected the backend C++ logic and QML frontend.


### Faced challenges
<!-- 遇到什麼問題、如何解決或打算如何解決 -->
- **Calender data scope:** I didn't properly thought of how to implement a good calender in my proposal, so I find it difficult to present a good interface. In my prototype, I implemented a strict date-filtering logic so the system only renders current-week data, preventing visual bugs. I plan to make a dynamic date calender, and also make a monthly calender for users to quickly see what their plans are throughout the month.

- **User experience:** I find that the CLI-driven approach isn't that powerful, since the stricted formatting string for every entry may hinder user experience. I plan to implement shorthand input support (e.g., "today", "tmr", "2pm") and command history / autocompletion to minimize repetitive typing and lower the entry barrier for new users.


### Next steps
<!-- 接下來要做什麼 -->
- **Calender design:** Make a better calender design so that user can see their schedules by the 7-columns bar and the monthly calender.

- **Intelligent shorthand engine:** Develop a better engine to make imputs more flexible to enhance user experience.

- **Data persistence:** Implement JSON-based serialization to allow user data to be saved and reloaded across different sessions.

- **Performance benchmarking:** Conduct a formal comparison between the interval tree and a standard linear array search to document the scalability of the Chronoslit kernel for the final demo.
---

## Final Report

### 專案說明
<!-- 完整描述你的專案做了什麼 -->

### 使用方式
<!-- 如何編譯、執行、使用你的程式 -->

