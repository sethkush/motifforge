// Opens a Flutter web build of an integration test in headless Chromium,
// streams the console to a log, takes screenshots when the test asks
// (SPIKE_MARK screenshot-request), and exits when the test finishes.
// Usage: node web_runner.cjs URL OUT_DIR LOG_FILE [timeoutSeconds]
const fs = require('fs');
const path = require('path');
const pw = require(process.env.PLAYWRIGHT_MODULE || 'playwright');

(async () => {
  const [url, outDir, logFile, timeoutArg] = process.argv.slice(2);
  const timeoutMs = (Number(timeoutArg) || 900) * 1000;
  fs.mkdirSync(path.join(outDir, 'screenshots'), { recursive: true });
  const log = fs.createWriteStream(logFile);
  // Full Chromium on the (virtual) display: the headless shell has no real
  // audio output, so nothing would reach the sound card.
  const browser = await pw.chromium.launch({
    headless: !process.env.DISPLAY,
    args: ['--autoplay-policy=no-user-gesture-required', '--no-sandbox'],
  });
  const context = await browser.newContext({
    viewport: { width: 1280, height: 900 },
    locale: 'en-US',
  });
  await context.grantPermissions(['clipboard-read', 'clipboard-write']);
  const page = await context.newPage();
  let finish;
  const done = new Promise((r) => (finish = r));
  let result = 'timeout';
  page.on('console', async (msg) => {
    const text = msg.text();
    log.write(text + '\n');
    const m = text.match(/SPIKE_MARK (\{.*\})/);
    if (m) {
      const mark = JSON.parse(m[1]);
      if (mark.event === 'screenshot-request') {
        await page.screenshot({ path: path.join(outDir, 'screenshots', mark.name + '.png') });
      }
    }
    if (/All tests passed/.test(text)) { result = 'pass'; finish(); }
    if (/Some tests failed/.test(text)) { result = 'fail'; finish(); }
  });
  page.on('pageerror', (e) => log.write('PAGEERROR ' + e.message + '\n'));
  await page.goto(url);
  await Promise.race([done, new Promise((r) => setTimeout(r, timeoutMs))]);
  await page.waitForTimeout(500);
  log.write(`WEB_RUNNER_RESULT ${result}\n`);
  log.end();
  await browser.close();
  process.exit(result === 'pass' ? 0 : 1);
})();
