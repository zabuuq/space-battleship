# Project Overview

Space Battleship is a two‑player online strategy and deduction game set in a nebula.
Each player commands a fleet of five ships on a long, narrow battlefield hidden
from their opponent.  Players take alternating turns during which each ship may
move, fire a probe scan, or launch a missile.  Special ship abilities (extra
probes, extra missiles, double movement or temporary stealth) introduce asymmetry
and encourage deduction and bluffing.  The match ends when one fleet is destroyed.

# Technical Mandates

## Coding Style

* Use **GDScript** for game code and follow [Godot’s official style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_style_guide.html).
* Names:
  * Variables and functions should use `snake_case`.
  * Classes and scene names should use `PascalCase`.
* Keep lines under 120 characters.
* Use clear, descriptive names and short comments explaining non‑obvious logic.
* Prefer composition over inheritance for scene architecture.

## Linting and Formatting

The project must remain lint‑free.  Before committing any code, run the following:

```
sh
gdformat --check .
gdlint .
```

`gdformat` enforces consistent formatting while `gdlint` performs static analysis.
Fix all issues raised by these tools before pushing commits.  If additional
scripts are added in other languages (e.g. a Node.js relay), configure the
appropriate linter (ESLint with the Airbnb base and Prettier).

# Project Architecture

The project is split into a **client** and a **server**:

* **Godot client** – Runs in the browser and handles all rendering, input and local
  game state.  Scenes include:
  * `MainMenu` – allows creating or joining a lobby via code.
  * `Lobby` – displays connection status until both players are ready.
  * `ShipPlacement` – allows players to arrange their fleet on their own grid.
  * `Battle` – contains two tabbed battlefields (your fleet and the enemy fog‑of‑war view) and
    drives per‑ship actions such as movement, probe scans and missile launches.
  * `EndGame` – shows the win/lose outcome and offers a restart.
* **Godot MCP server** – A headless Godot application (or Node.js relay) that acts as the relay server.
  It accepts lobby creation and join requests, relays turn actions between
  clients, validates moves, enforces turn order and win conditions, and
  broadcasts updates. Match session state and lobby codes are persisted using
  **SQLite**, with the database file located at `server/relay.db`.

## Data Persistence

* **SQLite** – All server-side state (active lobbies, player sessions, and match metadata) is stored in a local SQLite database.
* **Database Location** – The primary database file is `server/relay.db`.
* **AI Tooling** – The **mcp-sqlite** server is configured to allow agents to directly query this database to troubleshoot networking issues or validate game state synchronisation.

All multiplayer messages must be simple JSON payloads.  The server is the
authority for match state; clients send action requests and apply confirmed
updates.  Never trust client input without validation.

# Specific Components

The following components are required for the MVP:

* **Ship Placement System** – UI and logic for placing ships on a 120×12 grid,
  rotating them and preventing overlaps.
* **Turn Manager** – Keeps track of whose turn it is and iterates through each
  ship to perform its action.  Ships may move, probe or launch a missile once
  per turn (ship abilities may allow multiple probes, shots or movement).
* **Probe System** – Implements 3×3 probe scans, reveals presence of ships in
  scanned cells and respects stealth masking effects.
* **Missile System** – Resolves single‑cell attacks, applies damage and
  destruction and reports hit/miss results.
* **Movement & Collision** – Controls directional movement with facing, turning
  costs and collision checks.  Ships may not pass through or overlap.
* **UI Components** – Two battlefield tabs, action selection controls, status
  messages, and turn indicators.
* **Networking Layer** – Handles lobby creation/joining, message serialisation,
  reconnection and error handling.

# Development Instructions

Development should be driven by discrete prompts.  Each prompt should define a
clear task (e.g. “Implement the probe system”) and the assistant should return
only the code needed for that task.  When implementing a feature:

1. **Read the current Game Definition Model** and ensure the task aligns with it.
2. **Implement the feature** in small, testable units.  Avoid monolithic scripts.
3. **Run the linter and tests** locally.  Resolve all issues.
4. **Commit and push** the code with a descriptive commit message (see
   Repository Information below).
5. **Update documentation** (README, AGENTS.md or in‑code docs) as needed.

When you finish a task, commit your changes to the repository and push them to
the remote.  Always push after passing tests; do not accumulate untested work.

# Testing Instructions

Automated testing is required.  Use the **Godot Unit Test (GUT)** framework or
Godot’s built‑in unit testing to verify:

* Grid logic (placement bounds, overlap prevention).
* Turn sequencing and action limits.
* Probe scans reveal the correct cells.
* Missile hits and misses damage or miss ships appropriately.
* Movement respects facing and collision rules.
* Special ship abilities (double probes, double missiles, double movement,
  stealth masking) work as intended.

Write tests alongside features.  Execute tests with:

```
sh
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit
```

Expand the test suite as the project grows.  Do not commit code that fails tests.

# Security Considerations

* **Validate all network messages**.  Never trust client input; the server must
  reject invalid actions, illegal moves or malformed packets.
* **Avoid code injection**.  Treat all user‑supplied data as untrusted and
  sanitise when constructing UI elements or logs.
* **Keep the server headless**.  The Godot MCP server runs without any GUI and
  exposes only the minimal endpoints needed for gameplay.
* **Limit dependencies**.  Use well‑maintained libraries and update them
  regularly.  Do not execute arbitrary code received over the network.

# Repository Information and Instructions

*   **Branching Strategy**:
    *   `main` – Production branch. No direct commits or merges except from `staging` via PR.
    *   `staging` – Pre‑production branch. All new feature branches MUST start from here.
    *   `dev` – Integration branch. Feature branches are merged here first.
*   **Workflow**:
    1.  Create a feature branch off `staging`.
    2.  Implement and test changes in the feature branch.
    3.  Merge the feature branch into `dev`.
    4.  Delete the local and remote feature branch immediately after a successful merge into `dev`.
    5.  Create a Pull Request from `dev` to `staging`.
    6.  After approval in `staging`, create a Pull Request from `staging` to `main`.
*   **Commits**: Write clear, present‑tense commit messages describing what and why.
    Group related changes together; do not commit unrelated features in one go.
*   **Pushing**: Push your branches to the remote repository.  Do not leave local
    work unpushed.  If multiple tasks are in flight, rebase frequently to avoid
    conflicts.
*   **Documentation**: Update `README.md`, `AGENTS.md` and in‑source comments
    whenever you add or change features.  The repository should remain self‑documenting.
*   **Branch protection**: Direct merges to `main` are strictly prohibited. Respect all branch protection rules.

# Boundaries

This project aims for a **minimum viable product**.  Do **not** implement the
following in the MVP:

* User accounts, authentication or persistent profiles.
* Skins, cosmetics, in‑app purchases or monetisation.
* Leaderboards, rankings or social features.
* AI opponents or single‑player modes.
* Advanced graphics, 3D models or complex animations beyond simple placeholders.

All future features beyond the MVP must be planned and documented separately.

# Workflow & Documentation

Maintain a **persistent project summary** throughout development.  After each
milestone, update the Project Memory Summary with:

* Current Game Definition Model.
* Completed features and tests.
* Remaining tasks and known issues.

Use markdown headers and tables sparingly; long prose belongs outside of tables.
Follow the README format guidelines (short paragraphs, clear headings, lists
where appropriate).  Include references to the Godot MCP server in relevant
sections (Architecture and Technical Mandates).  Keep this document (AGENTS.md)
up to date as rules evolve.
