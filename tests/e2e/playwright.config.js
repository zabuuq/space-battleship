'use strict';

const { defineConfig, devices } = require('@playwright/test');

/**
 * Playwright configuration for Space Battleship browser tests.
 * Issue #62 – Validate multiplayer gameplay in browser.
 *
 * The tests open the exported HTML5 build served by a local static server.
 * Set BASE_URL to point at your local build output, e.g.
 *   BASE_URL=http://localhost:8080 npx playwright test
 */

const BASE_URL = process.env.BASE_URL || 'http://localhost:8080';

module.exports = defineConfig({
  testDir: './tests',
  timeout: 30_000,
  expect: { timeout: 5_000 },
  fullyParallel: false,
  retries: 0,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: BASE_URL,
    headless: true,
    screenshot: 'only-on-failure',
    video: 'off',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
