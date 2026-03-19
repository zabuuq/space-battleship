# Development Setup Guide

This document outlines the steps required to set up a local development environment for Space Battleship and the expectations for contributing to the project.

## Prerequisites

To work on this project, you should have the following tools installed:

- **Godot Engine (v4.6.1)**: The core game engine. Ensure the `godot` executable is in your system PATH.
- **Python (v3.x)**: Required for GDScript linting tools.
- **GDToolkit**: Install via `pip install gdtoolkit`. Provides `gdformat` and `gdlint`.
- **Node.js (v24+) & npm**: Required for the multiplayer relay server and E2E testing.
- **GitHub CLI (gh)**: For managing issues and pull requests from the terminal.

## Local Setup

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/zabuuq/space-battleship.git
   cd space-battleship
   ```

2. **Initialize Submodules/Addons**:
   GUT is included in the `addons/` directory. No extra steps are required for the base engine.

3. **Install E2E Dependencies**:
   ```bash
   cd tests/e2e
   npm install
   npx playwright install --with-deps chromium
   ```

4. **Verify Tooling**:
   Ensure everything is correctly mapped by running:
   ```bash
   godot --version
   gdformat --version
   gdlint --version
   butler -V
   ```

## Running the Project

- **From the Editor**: Open `project.godot` in the Godot Editor and press F5.
- **Headless Mode**: Use the command line for automation:
  ```bash
  godot --headless --path .
  ```

## Testing

### Unit Tests (GUT)
Run all unit tests headlessly:
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -glog=1 -gexit
```

### E2E Tests (Playwright)
Run browser-based integration tests:
```bash
cd tests/e2e
npx playwright test
```

## Linting and Formatting

All code must pass linting before being committed. We follow the 120-character line length rule.

```bash
# Check formatting
gdformat --check src tests

# Run static analysis
gdlint src tests
```

## Continuous Integration

Every push and pull request to the `main` branch triggers the GitHub Actions CI pipeline, which:
1. Runs all GUT unit tests.
2. Generates a test report (available as a workflow artifact).
3. Performs a Playwright infrastructure check.

## Contribution Workflow

1. Create a feature branch from `main`.
2. Implement your changes in small, testable units.
3. Write and run tests locally.
4. Ensure code passes `gdformat` and `gdlint`.
5. Open a Pull Request to `main`.
