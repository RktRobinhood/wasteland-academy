import { defineConfig, devices } from '@playwright/test';

// The Godot build on an iPhone (FAL-1042, #187). WebKit with the iPhone 13 profile, taps
// only. A machine without WebKit's system libraries can run the same spec in Chromium at
// the same size: WA_BROWSER=chromium npx playwright test -c tests/webkit
const browser = process.env.WA_BROWSER || 'webkit';
const iphone = devices['iPhone 13'];

export default defineConfig({
  testDir: '.',
  testMatch: '*.spec.mjs',
  fullyParallel: false,
  workers: 1,
  timeout: 180_000,
  expect: { timeout: 10_000 },
  forbidOnly: !!process.env.CI,
  retries: 0,
  reporter: process.env.CI ? [['list'], ['html', { open: 'never', outputFolder: '../../playwright-report/webkit' }]] : 'list',
  outputDir: '../../test-results/webkit',
  use: {
    browserName: browser,
    // The iPhone 13's whole 390x844 screen, not the 664 px of it Safari leaves under its bars:
    // the taps in the spec are at points of this size.
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: iphone.deviceScaleFactor,
    hasTouch: true,
    isMobile: true,
    userAgent: browser === 'webkit' ? iphone.userAgent : undefined,
    launchOptions: browser === 'chromium'
      ? { args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] }
      : {},
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
});
