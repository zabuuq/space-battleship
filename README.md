# Space Battleship

Space Battleship is a two‑player online strategy and deduction game inspired by
classic Battleship but reimagined for a large, asymmetric battlefield and modern
web play.  Each player commands a hidden fleet in a dense nebula and must find
and destroy the opponent’s ships through careful scanning, movement and
calculated strikes.  This repository contains the source code and design
documentation for the MVP implementation built with the Godot game engine.

## Game Overview

Two fleets are pulled out of hyperspace into a rectangular nebula.  Each fleet
is hidden on its own 120×12 grid, invisible to the opponent.  Players take
alternating turns, and each ship may perform one action per turn—move forward,
rotate, fire a **probe scan** (a 3×3 area reveal) or launch a **missile**
attack.  Special ship abilities provide extra probes, extra missiles, double
movement or temporary stealth.  The first player to destroy all enemy ships wins.

### Fleet Composition

| Ship       | Size | Ability                     |
|-----------|------|-----------------------------|
| Support   | 5    | Two probes per action       |
| Battleship| 4    | Two missiles per action     |
| Cruiser   | 3    | No special ability          |
| Destroyer | 3    | Move two squares per action |
| Stealth   | 3    | Masked from probes for one turn (1‑turn cooldown) |

### Key Mechanics

* **Large battlefield** – A wide 120×12 grid prevents full board coverage in a single round.
* **Directional movement** – Ships have a facing; turning costs a move point and ships may not overlap.
* **3×3 probes** – Scanning reveals whether ships occupy the nine tiles around the selected cell without causing damage.
* **Missiles** – Target a single tile, dealing damage and eventually sinking ships.
* **Two battlefields** – The UI presents your own grid (showing your ships and enemy attacks) and an enemy grid under fog of war (showing your probes and missile results).
* **Multiplayer via lobby codes** – Players create or join matches using lobby codes that connect through a lightweight relay server.

### Technology

This MVP uses the **Godot Engine** and **GDScript** for all gameplay logic and
UI, with a browser export target.  A headless **Godot MCP server** acts as a
relay to handle lobby creation, matchmaking, turn validation and win condition
checks.  Simple placeholder graphics and UI components are used during the MVP
phase; a full art pass can follow once the core gameplay is proven.

### MVP Scope

The goal of the MVP is to deliver a playable two‑player web game that includes:

* Ship placement and rotation on the 120×12 grid.
* Turn sequence with per‑ship actions (move, probe, missile) and special abilities.
* Probe and missile resolution, movement rules and collision checking.
* Win condition detection and simple end‑game screen.

Features such as accounts, progression systems, cosmetic customisation and advanced
animations are explicitly out of scope for the first release.

### Project Status

Development is currently in the planning and architecture phase. See
[`AGENTS.md`](AGENTS.md) for detailed instructions and development rules for the AI agent.
All contributions should follow the guidelines described there.

## Getting Started

To set up your local development environment, please follow the [Development Setup Guide](docs/setup.md).

## Project Structure

*   `src/client/`: All client-side Godot scenes and scripts.
    *   `scenes/`: UI and battlefield scenes.
    *   `scripts/`: Logic for ship behavior, grid management, and networking.
    *   `assets/`: Textures, fonts, and audio.
*   `src/shared/`: Data models and utilities used by both client and server.
*   `server/`: Multiplayer relay server code and database.
*   `tests/`: 
    *   `unit/`: GUT unit tests for gameplay systems.
    *   `e2e/`: Playwright end-to-end browser tests.
*   `docs/`: Additional technical documentation.
