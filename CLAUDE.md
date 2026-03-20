# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### GDScript Linting and Formatting
```sh
gdformat --check .   # check formatting
gdformat .           # auto-format
gdlint .             # static analysis
```
Both tools exclude `.git/` and `addons/`. All code must pass lint and format checks before committing.

### Running GUT Unit Tests (headless)
```sh
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -glog=1 -gexit
```

### Running a Single Test File
```sh
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -glog=1 -gexit -gtest=res://tests/unit/test_battlefield_grid.gd
```

### Running E2E Tests (Playwright)
```sh
cd tests/e2e
npm install
npx playwright install --with-deps chromium
npx playwright test
```

## Branching and Workflow

**Strictly follow this branching strategy:**

1. Create feature branches off `staging` (never off `main` or `dev`)
2. Merge feature branch → `dev` (integration)
3. Delete the feature branch immediately after merging into `dev` (both local and remote)
4. Open a PR from `dev` → `staging`
5. After approval, open a PR from `staging` → `main`

Direct commits to `main` are prohibited. See `AGENTS.md` for the full rules.

## Architecture

### Layer Separation

- **`src/shared/`** — Pure data models (`RefCounted`), used by both client and server. No Godot node dependencies.
- **`src/client/`** — Godot scenes (`.tscn`) and their controller scripts. UI and input logic only.
- **`server/`** — Headless relay server. Authoritative for match state. SQLite DB at `server/relay.db`.

### Core Data Models (`src/shared/`)

**`BattlefieldGrid.gd`** — Low-level 120×12 grid. Stores per-cell state as a `Dictionary` keyed by `Vector2i`. Each cell holds `"occupied_by"` (ship ID or `null`) and `"state"` (`"hidden"`, `"revealed"`, `"hit"`, `"miss"`). Provides `is_in_bounds`, `pos_to_index`/`index_to_pos`, `set_cell_state`, `set_cell_occupant`.

**`GameState.gd`** — Top-level match container. Owns a `BattlefieldGrid` and a `ships` array of dictionaries. Ship dictionaries carry `id`, `type`, `position` (`Vector2i`), `facing` (`Vector2i`), `length`, `health`, `is_destroyed`. `add_ship()` writes to both the array and the grid. `to_dict()`/`from_dict()` serialize for network transport; `from_dict()` replays ship and missile data to reconstruct grid state from scratch.

### Client Rendering (`src/client/`)

**`BattlefieldGridUI.gd`** extends `Control`. Renders the 120×12 grid using custom `_draw()` at 16 px per cell (total 1920×192 px). Translates mouse positions via `screen_to_grid()` and emits the `cell_selected(grid_pos: Vector2i)` signal. Repeated clicks on the same cell do not re-emit the signal.

Scenes in `src/client/scenes/` correspond to game flow: `MainMenu → Lobby → ShipPlacement → Battle → EndGame`.

### Key Conventions

- Grid coordinates are always `Vector2i`; screen coordinates are `Vector2`.
- Out-of-bounds positions are represented as `Vector2i(-1, -1)`.
- Ships are dictionaries, not typed classes, for serialization flexibility.
- Composition over inheritance for scene architecture.
- Max line length: 120 characters. Max methods per class: 20.
- GUT test files use the `test_` prefix and live under `tests/unit/`.
