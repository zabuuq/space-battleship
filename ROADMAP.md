# Space Battleship Development Roadmap

The roadmap below outlines the recommended sequence for tackling the project’s issues and highlights tasks that can be worked on concurrently to enable multiple AI agents to operate in parallel.

## Phase 1 – Project setup and tooling (concurrent tasks)

- **#1 Initialize Godot project structure** – Sets up the base folder/scene layout.
- **#2 Configure GDScript linting and formatting** – Ensures consistent code style.
- **#3 Install and configure GUT testing framework** – Installs the unit-testing framework; start on CI pipeline setup here.
- **#80 Set up CI pipeline** – Configure GitHub Actions to run tests automatically.
- **#5 Add initial project documentation** – Document project structure and setup.

These tasks establish the development environment and can be handled by separate agents at the same time.

## Phase 2 – Core data models and rendering

- **#6 Implement 120×12 battlefield data model** and **#66 Define canonical game state model** – Lay the foundation for storing game state. These can be developed concurrently.
- **#7 Render the battlefield grid in Godot** and **#9 Add screen‑to‑grid coordinate translation** – Render the grid and map inputs to grid cells.
- **#8 Implement cell selection from click or tap** – Build basic input handling.
- **#10 Add grid boundary validation tests** – Tests for grid access; depends on #6 and #9.
- **#11 Define ship types and placement metadata** – Must complete before placement UI.

## Phase 3 – Ship placement and movement

- **Placement UI and logic** (after #11, can run in parallel):
  - **#12 Implement ship placement UI**
  - **#13 Add ship rotation during placement**
  - **#14 Prevent overlapping ship placement**
  - **#15 Prevent out‑of‑bounds ship placement**
  - **#16 Add ship placement validation tests**
- **Movement system** (after placement):
  - **#17 Implement ship facing direction model**
  - **#18 Implement forward movement rules**
  - **#19 Implement turning cost rules**
  - **#20 Prevent collision during movement**
  - **#21 Implement Destroyer double‑move ability**
  - **#22 Add movement and collision tests**

## Phase 4 – Combat systems

Divide work between probe and missile subsystems:

- **Probe subsystem**:
  - **#23 Implement 3×3 probe targeting**
  - **#24 Reveal ship presence from probe results**
  - **#25 Handle probe scans at map edges**
  - **#26 Implement Support double‑probe ability**
  - **#27 Implement Stealth probe masking**
  - **#28 Add probe system tests**
- **Missile subsystem**:
  - **#29 Implement missile targeting**
  - **#30 Implement hit and miss resolution**
  - **#31 Track ship damage state**
  - **#32 Implement Battleship double‑missile ability**
  - **#33 Implement ship destruction logic**
  - **#34 Add missile combat tests**

These two subsystems can progress concurrently.

## Phase 5 – Turn and action system

- **#35 Implement turn manager**
- **#36 Track per‑ship actions each turn**
- **#37 Prevent illegal extra actions**
- **#38 Implement end‑turn flow**
- **#72 Implement centralized action validation system** – Can be developed alongside the turn manager.
- **#39 Add turn system tests**

## Phase 6 – Networking and multiplayer

Networking tasks depend on a stable game state model and action rules, but they can start once those components are defined:

- **#67 Create network message schema** and **#68 Implement game state serialization**
- **#69 Implement authoritative server game logic**
- **#41 Build WebSocket connection layer**
- **#42 Implement relay server room state**
- **#40 Create lobby code match flow**
- **#43 Synchronize turn actions over the network**
- **#44 Handle disconnects and invalid sessions**
- **#45 Add multiplayer networking tests**, **#71 Add multiplayer sync consistency tests**, **#62 Validate multiplayer gameplay in browser**
- **#61 Configure Godot HTML5 export**

Multiple agents can work on message schema/serialization, WebSocket layer and server logic in parallel, coordinating via agreed message formats.

## Phase 7 – Game loop completion and victory conditions

- **#51 Detect full fleet destruction**
- **#52 Implement win and loss state handling**
- **#53 Create end‑game results screen**
- **#54 Add restart or return‑to‑menu flow**
- **#55 Add victory condition tests**

These tasks depend on core combat and turn systems but can proceed once those are stable.

## Phase 8 – User interface and interaction

Interface and UX tasks can run alongside networking and end‑game work:

- **#46 Build tabbed battlefield interface**
- **#47 Render player battlefield state**
- **#48 Render enemy fog‑of‑war battlefield**
- **#49 Add ship action selection panel**
- **#50 Add turn and status indicators**
- **#70 Implement lobby waiting screen**
- **#77 Implement action preview system**
- **#74 Implement fog‑of‑war data model**
- **#73 Add structured game event logging**

Tests for fog‑of‑war and action preview can be added as new issues if they don’t exist yet.

## Phase 9 – Assets and art production

Start asset work early and run it in parallel with other phases:

- Design ship sprites or models, battlefield backgrounds, and UI assets.
- Produce particle and visual effects.
- Compose background music and comprehensive sound effects (beyond placeholder sounds).
- Animate ship movement and actions (beyond lightweight animations).
- Handle asset sourcing/licensing.

## Phase 10 – Logging, polishing and optimisation

- **#56 Add probe result visual feedback**
- **#57 Add missile hit and miss visual feedback**
- **#58 Add basic sound effects**
- **#59 Add lightweight gameplay animations**
- **#60 Perform MVP bug‑fix pass**
- **#63 Optimize initial web build performance**
- **#73 Add structured game event logging** (if not completed earlier)
- Add tests for serialization (#68), fog‑of‑war (#74), event logging (#73), action preview (#77), match initialization (#78), and ship abilities if not already covered.

These can run concurrently toward the end of development.

## Phase 11 – Deployment and release

- **#64 Prepare itch.io deployment package**
- **#65 Create itch.io release checklist**

These tasks should occur after core gameplay, assets, and testing are complete.

Use this roadmap to coordinate multiple agents, allowing parallel progress where dependencies permit, while ensuring foundational components are completed before dependent features.
