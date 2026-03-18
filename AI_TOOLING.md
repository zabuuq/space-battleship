# AI Tooling & Environment Summary: Space Battleship

This document summarizes the current development environment and provides recommendations for AI-enhanced tools and extensions to optimize the **Gemini CLI** workflow for the `space-battleship` project across multiple machines.

---

## 💻 Environment 1: Big Red

### ✅ Currently Installed & Configured (Big Red)

- **Node.js (v24.11.0) & npm (v11.7.0)**: Available for WebSocket relay server development and executing npx commands.
- **Source Control**: Git (v2.52.0) & GitHub CLI (v2.85.0) are fully integrated.
- **MCP Servers**:
  - **mcp-github**: Active. Handles issue management, pull requests, and repository operations.
  - **mcp-chrome-devtools**: Active. Provides direct browser interaction.
  - **mcp-sqlite**: Active. Configured for local database interactions.
  - **mcp-godot**: Configured in `.gemini/settings.json`, but requires the Godot executable to be correctly mapped on this machine.

### ❌ Missing & Required Additions (To Match Desktop)

To enable the full Gemini CLI workflow on this machine, the following tools must be installed and added to the system `PATH`:

1. **Godot Engine CLI**: Download Godot 4.6.1, rename the executable to `godot.exe`, and add its folder to your system `PATH`.
  - *Purpose*: Allows Gemini to run GUT tests headlessly (`godot --headless`) and perform automated HTML5 exports.

2. **Python (v3.x)**: Install Python and ensure it is in your `PATH`.
  - *Purpose*: Required for GDToolkit and backend logic/scripts.

3. **GDToolkit (`gdformat`, `gdlint`)**: Install via `pip install gdtoolkit`.
  - *Purpose*: Required for code quality enforcement and formatting.

4. **Playwright**: Run `npm install -g playwright` and `npx playwright install`.
  - *Purpose*: For the **mcp-playwright** server to function without prompting for installation.

5. **itch.io Butler**: Install the `butler` CLI.
  - *Purpose*: Enables Gemini to autonomously push builds to itch.io (`butler push`).

6. **ImageMagick & FFmpeg**: Install both CLIs.
  - *Purpose*: Essential for processing art and audio assets (Issue #90).

---

## 🖥️ Environment 2: Jason's Desktop

### ✅ Currently Installed & Configured (Jason's Desktop)

#### Gemini CLI / MCP Servers

- **mcp-godot**: Active. Used for scene analysis, editor launching, and project metadata.
- **mcp-github**: Active. Handles issue management, pull requests, and repository operations.
- **mcp-chrome-devtools**: Active. Provides direct browser interaction, WebSocket monitoring (Issue #62), and console log access for HTML5 builds.
- **mcp-playwright**: Active. Local integration via npx configured for browser automation and future CI pipeline testing (Issue #80).
- **mcp-sqlite**: Active. Pointed to a placeholder database in the `server` folder for future relay server state management.

#### Command Line Tools

- **Godot Engine CLI (v4.6.1)**: Active. Enables headless GUT test execution (`godot --headless`) and automated HTML5 exports.
- **GDToolkit (v4.5.0)**: `gdformat` and `gdlint` are ready for code quality enforcement.

#### Languages & Runtimes

- **Python (v3.14.3)**: Available for backend logic or automation scripts.
- **Node.js (v24.11.0) & npm (v11.7.0)**: Available for WebSocket relay server development.

#### Source Control

- **Git (v2.52.0)** & **GitHub CLI (v2.83.2)**: Fully integrated.

### 🚀 Recommended Additions (For Desktop)

- **itch.io Butler**: Install the `butler` CLI.
- **ImageMagick**: Allows Gemini to slice sprite sheets, resize background art, and optimize UI assets.
- **FFmpeg**: Essential for processing, converting (to `.ogg`), and normalizing audio tracks (Issue #90).

---

## Custom Gemini CLI Skills (Shared)

- **`skill-godot-tester`**: To automate headless GUT test execution and failure diagnosis.
- **`skill-gdscript-linter`**: To enforce `gdlint` and `gdformat` standards on every edit.
- **`skill-itch-deploy`**: To orchestrate the full export and `butler` push pipeline.