# Beta Design Q&A

Tracks clarification questions asked during the Post-MVP Beta Design & MVP Alignment workflow.
Answer directly in the **Answer** fields below, then let Claude know you're ready to continue.

---

## Task 2 — MVP Validation

### Q1 — Lobby / Matchmaking scope
**Question:** The Lobby scene currently has a placeholder "Start" button that skips straight to Ship Placement. Is the real lobby code flow (Issues #40–#42: WebSocket, relay server, lobby code match) in scope for MVP, or is the MVP a **local/same-machine two-player** prototype first?

**Answer:**
Those issues are in scope for MVP

---

### Q2 — Ship Movement in MVP
**Question:** Is movement (Issues #17–#22: facing, forward movement, turning costs) part of the MVP combat loop, or is the MVP combat limited to **probe + missile only** on a static fleet?

**Answer:**
Every ship can perform one or two actions per turn, depending on ship abilities. Those actions are either to move, send a probe, or shoot a missile.

---

### Q3 — Ship Abilities in MVP
**Question:** Are the 5 special abilities (double probe, double missile, double move, probe mask) required for MVP, or are they **Beta features** that get stubbed out now?

**Answer:**
Keep these in the MVP.

---

### Q4 — Victory / End-Game in MVP
**Question:** Is the full win/loss detection + results screen (Issues #51–#55) required for MVP?

**Answer:**
Yes

---

### Q5 — Fog of War in MVP
**Question:** Is a separate fog-of-war data model (Issue #74) needed for the MVP networked build, or is the current full `GameState` approach sufficient for local testing?

**Answer:**
Keep issue #74 in the MVP

---

## Task 3 — Beta Vision

### Q6 — Beta core rules
**Question:** Is Beta still the same core game (probe + missile + move) with polish and more content, or do you envision **significantly different rules** (e.g., real-time play, new abilities, new win conditions)?

**Answer:**
It will still be the same core game with some additional ship abilities with attacking and defending. I want to add shields and lasers and clearly define how to destroy each ship, which may differs slightly from the MVP.

---

### Q7 — Grid dimensions in Beta
**Question:** Does Beta target the same 120×12 grid dimensions, or is the grid size/shape something you want to revisit for Beta?

**Answer:**
Beta will use the same grid dimensions. Making the grid three dimensional is something I am considering for the full release, but not the initial beta.

---
