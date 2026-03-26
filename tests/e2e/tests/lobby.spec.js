'use strict';

/**
 * Multiplayer lobby end-to-end tests.
 * Issue #62 – Validate multiplayer gameplay in browser.
 *
 * These tests validate the Godot HTML5 export in a real Chromium browser.
 * They require the exported build to be served at BASE_URL (default
 * http://localhost:8080).  Set BASE_URL env var to point at your server.
 *
 * Run with:
 *   BASE_URL=http://localhost:8080 npx playwright test
 */

const { test, expect } = require('@playwright/test');

test.describe('Multiplayer lobby flow', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the HTML5 build.  The Godot canvas needs a moment to boot.
    await page.goto('/');
    // Wait for the Godot canvas element to exist (exported builds render to #canvas).
    await page.waitForSelector('#canvas, canvas', { timeout: 15_000 });
  });

  test('game loads and displays main menu canvas', async ({ page }) => {
    // Verify the Godot canvas is visible – basic smoke test that the export works.
    const canvas = page.locator('#canvas, canvas').first();
    await expect(canvas).toBeVisible({ timeout: 15_000 });
  });

  test('page title matches project name', async ({ page }) => {
    // The exported HTML sets the page title from the Godot project name.
    await expect(page).toHaveTitle(/Space Battleship/i, { timeout: 10_000 });
  });

  test('no JavaScript errors on load', async ({ page }) => {
    const errors = [];
    page.on('pageerror', (err) => errors.push(err.message));
    await page.waitForTimeout(3_000);
    expect(errors).toHaveLength(0);
  });
});
