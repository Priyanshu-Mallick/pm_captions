// Renders index.html frame-by-frame and pipes PNGs into ffmpeg.
//   node render.js                 -> pm_captions_intro.mp4 (60fps)
//   STILLS=1,5.5,12 node render.js -> stills/<t>.png for quick checks
const { chromium } = require('playwright');
const { spawn } = require('child_process');
const { once } = require('events');
const fs = require('fs');
const os = require('os');

const FPS = +process.env.FPS || 60, DUR = 36, OUT = process.env.OUT || 'pm_captions_intro.mp4';
const CHROME = process.env.CHROME || `${os.homedir()}/Library/Caches/ms-playwright/chromium-1243/chrome-mac-arm64/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing`;

(async () => {
  const browser = await chromium.launch({ executablePath: CHROME, args: ['--allow-file-access-from-files', '--force-color-profile=srgb'] });
  const page = await browser.newPage({ viewport: { width: 1920, height: 1080 } });
  page.on('pageerror', e => { console.error(e); process.exit(1); });
  await page.goto(`file://${__dirname}/index.html`);
  await page.evaluate(() => window.ready);

  if (process.env.STILLS) {
    fs.mkdirSync(`${__dirname}/stills`, { recursive: true });
    for (const s of process.env.STILLS.split(',')) {
      await page.evaluate(t => render(t), +s);
      await page.screenshot({ path: `${__dirname}/stills/${s}.png` });
    }
    return browser.close();
  }

  const ff = spawn('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', String(FPS), '-c:v', 'png', '-i', '-',
    '-i', 'audio.wav', '-map', '0:v', '-map', '1:a', '-c:v', 'libx264', '-preset', 'slow', '-crf', '16', '-pix_fmt', 'yuv420p',
    '-c:a', 'aac', '-b:a', '192k', '-shortest', '-movflags', '+faststart', OUT], { cwd: __dirname, stdio: ['pipe', 'inherit', 'inherit'] });
  const N = DUR * FPS;
  for (let f = 0; f < N; f++) {
    await page.evaluate(t => render(t), f / FPS);
    const buf = await page.screenshot({ type: 'png' });
    if (!ff.stdin.write(buf)) await once(ff.stdin, 'drain');
    if (f % FPS === 0) process.stdout.write(`\r${f / FPS}/${DUR}s`);
  }
  ff.stdin.end();
  await once(ff, 'close');
  await browser.close();
  console.log(`\ndone -> ${OUT}`);
})();
