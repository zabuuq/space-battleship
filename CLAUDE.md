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
4. Open a PR from `dev` → `staging` — CI must pass before merging
5. After approval, open a PR from `staging` → `main` — CI must pass before merging

If a bad merge reaches a shared branch, revert with `git revert -m 1 <merge-commit-sha>` and open a follow-up PR. Never force-push shared branches.

Direct pushes to `main` or `staging` are prohibited; all changes must reach these branches via pull request. Both branches are protected by GitHub rulesets requiring: all CI checks passing, and no direct deletions or force-pushes. Merge commits, squash merges, and rebase merges are all permitted. See `AGENTS.md` for the full rules.

## Architecture

### Layer Separation

- **`src/shared/`** — Pure data models (`RefCounted`), used by both client and server. No Godot node dependencies.
- **`src/client/`** — Godot scenes (`.tscn`) and their controller scripts. UI and input logic only.
- **`server/`** — Headless relay server. Authoritative for match state. SQLite DB at `server/relay.db`.

### Core Data Models (`src/shared/`)

**`BattlefieldGrid.gd`** — Low-level 120×12 grid. Stores per-cell state as a `Dictionary` keyed by `Vector2i`. Each cell holds `"occupied_by"` (ship ID or `null`) and `"state"` (`"hidden"`, `"revealed"`, `"hit"`, `"miss"`). Provides `is_in_bounds`, `pos_to_index`/`index_to_pos`, `set_cell_state`, `set_cell_occupant`.

**`GameState.gd`** — Top-level match container. Owns a `BattlefieldGrid` and a `ships` array of dictionaries. Ship dictionaries carry `id`, `type`, `position` (`Vector2i`), `facing` (`Vector2i`), `length`, `health`, `is_destroyed`. `add_ship()` writes to both the array and the grid. `to_dict()`/`from_dict()` serialize for network transport; `from_dict()` replays ship and missile data to reconstruct grid state from scratch.

**`ShipDefs.gd`** — Canonical ship type registry. Exposes `TYPE_*` string constants, `ABILITY_*` string constants, a `DEFINITIONS` dictionary (keyed by type, each entry has `length`, `health`, `ability`), and a `FLEET_COMPOSITION` array listing the required one-of-each-type fleet. Helpers: `is_valid_type(type)`, `get_definition(type)`, `create_ship_dict(id, type, position, facing)`.

**`PlacementValidator.gd`** — Static helpers for ship placement validation. `get_ship_cells(pos, facing, length)` enumerates the cells a ship occupies. `is_in_bounds(pos, facing, length)` checks the full ship body stays within the 120×12 grid. `is_not_overlapping(grid, pos, facing, length)` checks for collisions with already-placed ships. `can_place` combines both.

**`MovementRules.gd`** — Static movement rules and geometry. Exposes cardinal direction constants (`DIR_EAST/WEST/NORTH/SOUTH`), turn constants (`TURN_LEFT/RIGHT`), and all movement logic: `apply_turn(facing, direction)`, `forward_position(pos, facing, steps)`, `move_steps_for(ship_type)` (Destroyer returns 2 via `ABILITY_DOUBLE_MOVE`), `can_move_forward(game_state, ship_id, steps)`, `move_forward(game_state, ship_id, steps)`, `can_turn(game_state, ship_id, direction)`, `turn_ship(game_state, ship_id, direction)`.

**`ProbeRules.gd`** — Static probe/scan rules. `get_probe_cells(center)` returns the 3×3 area around a cell, silently clipping to grid bounds. `probe_count_for(ship_type)` returns 2 for the Support ship (`ABILITY_DOUBLE_PROBE`), 1 for all others. `fire_probe(game_state, player_index, center)` reveals non-masked occupied cells as `"revealed"`, records the probe in `GameState.probe_history`, and returns detected positions. Stealth masking: `activate_probe_mask(game_state, ship_id)` activates the Stealth ship's one-round hide ability; `tick_probe_mask(ship)` expires the mask and starts a one-round cooldown; `can_activate_probe_mask(ship)` queries availability. Mask state is stored in the ship dictionary as `"probe_mask_active"` (bool) and `"probe_mask_cooldown"` (int).

**`MissileRules.gd`** — Static missile-combat rules. `missile_count_for(ship_type)` returns 2 for the Battleship (`ABILITY_DOUBLE_MISSILE`), 1 for all others. `is_valid_target(pos)` checks whether a cell is in bounds. `fire_missile(game_state, player_index, target)` resolves the shot: returns `RESULT_HIT` and applies 1 damage to the occupying ship (setting `is_destroyed = true` when health reaches 0), `RESULT_MISS` for an empty cell, or `RESULT_INVALID` for an out-of-bounds target; the result is always recorded in `GameState.missile_history` and the cell state updated to `"hit"` or `"miss"`.

**`TurnManager.gd`** — Manages turn sequencing and per-ship action budgets. `begin_turn(game_state)` resets budgets at the start of each player's turn. `can_ship_act(ship_id)` returns true if the ship has not yet used its action. `record_action(game_state, player_index, ship_id)` validates and records an action, returning `RESULT_OK` or an error constant (`RESULT_ALREADY_ACTED`, `RESULT_WRONG_TURN`, `RESULT_GAME_OVER`, `RESULT_NOT_COMBAT`). `end_turn(game_state)` ticks all probe-mask cooldowns, advances the turn via `game_state.next_turn()`, and clears action budgets.

**`ActionValidator.gd`** — Centralised pre-execution validation for all player actions. All methods are static and return `{"valid": bool, "error": String}` without mutating state. `validate_move_forward(game_state, turn_manager, player_index, ship_id, steps)` checks prerequisites then bounds and collision. `validate_turn(...)` validates rotation. `validate_probe(...)` checks the centre cell is in bounds. `validate_missile(...)` checks the target is in bounds. Error constants: `ERROR_WRONG_TURN`, `ERROR_ACTION_LIMIT`, `ERROR_OUT_OF_BOUNDS`, `ERROR_COLLISION`, `ERROR_GAME_OVER`, `ERROR_NOT_COMBAT`.

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
