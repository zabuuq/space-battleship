# AI Tooling & Environment Summary: Space Battleship

This document summarizes the current development environment and provides recommendations for AI-enhanced tools and extensions to optimize the **Gemini CLI** workflow for the `space-battleship` project.

## ✅ Currently Installed & Configured

### Gemini CLI / MCP Servers
*   **mcp-godot**: Active. Used for scene analysis, editor launching, and project metadata.
*   **mcp-github**: Active. Handles issue management, pull requests, and repository operations.
*   **mcp-chrome-devtools**: Active. Provides direct browser interaction, WebSocket monitoring (Issue #62), and console log access for HTML5 builds.

### Languages & Runtimes
*   **Python (v3.14.3)**: Available for backend logic or automation scripts.
*   **Node.js (v24.11.0) & npm (v11.7.0)**: Available for WebSocket relay server development.
*   **GDToolkit (v4.5.0)**: `gdformat` and `gdlint` are ready for code quality enforcement.

### Source Control
*   **Git (v2.52.0)** & **GitHub CLI (v2.83.2)**: Fully integrated.

---

## 🚀 Recommended Additions

To enable Gemini CLI to autonomously handle testing, deployment, and asset processing, the following tools should be added to the system `PATH`:

### 1. Essential CLIs (High Priority)
*   **Godot Engine CLI**: Add the `godot` executable to your PATH.
    *   *Purpose*: Allows Gemini to run GUT tests headlessly (`godot --headless`) and perform automated HTML5 exports.
*   **itch.io Butler**: Install the `butler` CLI.
    *   *Purpose*: Enables Gemini to autonomously push builds to itch.io (`butler push`).

### 2. Specialized Automation & MCP Servers
*   **Playwright**:
    *   *Purpose*: **Highly Recommended** for the automated CI pipeline (Issue #80). Playwright is superior for this project as it supports true cross-browser testing (Chromium, Firefox, WebKit), handles Godot's heavy HTML5 loading via auto-waiting, and allows for easy multi-context testing—perfect for simulating two players in a single multiplayer test.
*   **SQLite MCP**:
    *   *Purpose*: For debugging and managing relay server room states (Issue #42).

### 3. Media Processing CLIs (Art & Audio Milestone)
*   **ImageMagick**:
    *   *Purpose*: Allows Gemini to slice sprite sheets, resize background art, and optimize UI assets.
*   **FFmpeg**:
    *   *Purpose*: Essential for processing, converting (to `.ogg`), and normalizing audio tracks (Issue #90).

### 4. Custom Gemini CLI Skills
*   **`skill-godot-tester`**: To automate headless GUT test execution and failure diagnosis.
*   **`skill-gdscript-linter`**: To enforce `gdlint` and `gdformat` standards on every edit.
*   **`skill-itch-deploy`**: To orchestrate the full export and `butler` push pipeline.
