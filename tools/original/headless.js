/**
 * Headless driver for tools/original/index.html: runs the original game in
 * js-dos inside a headless Chromium, without a browser pane, and drives it with
 * a tiny line-based script (one command per line, from a file or from stdin).
 *
 *   NODE_PATH=<runner>/node_modules node tools/original/headless.js steps.txt
 *   tail -n +1 -f cmds.txt | NODE_PATH=... node tools/original/headless.js   # live
 *
 * Commands (js-dos key codes or names: Enter Esc Space Left Right Up Down Ctrl
 * Alt Shift F1..F10, or a letter/digit; see README.md):
 *   wait MS              let the game run MS milliseconds
 *   type TEXT            type TEXT (real upper case; \n is Enter), e.g. type KEEN3\n
 *   key KEY [MS]         press and release KEY (held MS ms, default 120)
 *   down KEY / up KEY    hold or release KEY
 *   keys KEY KEY ...     press several keys one after another
 *   snap NAME            save the last frame as <frames>/NAME.rgb
 *   rec MAX [EVERY]      start recording (MAX frames, one per EVERY ms; 0 = all)
 *   save NAME            stop recording and save NAME.json + NAME.NNN.rgb
 *   js EXPRESSION        evaluate in the page and print the result
 *   quit                 close the browser
 * Lines starting with # are comments. Every command prints "ok <ms> <line>".
 *
 * Environment: URL (default http://127.0.0.1:8765/index.html, served by
 * serve.py), CHROME (Chromium binary; default the Playwright one under
 * PLAYWRIGHT_BROWSERS_PATH or /opt/pw-browsers). It contains no game data and
 * writes nothing itself: frames go to serve.py's folder, outside the repository.
 */
const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { chromium } = require('playwright-core');

const KEY_NAMES = {
  enter: 257, esc: 256, escape: 256, space: 32, left: 263, right: 262, up: 265,
  down: 264, ctrl: 341, alt: 342, shift: 340, tab: 258, backspace: 259,
};
for (let i = 1; i <= 10; i++) KEY_NAMES['f' + i] = 289 + i;

function keyCode(name) {
  const lower = name.toLowerCase();
  if (lower in KEY_NAMES) return KEY_NAMES[lower];
  if (/^\d{2,}$/.test(name)) return Number(name);
  return name.toUpperCase().charCodeAt(0);
}

function findChrome() {
  if (process.env.CHROME) return process.env.CHROME;
  const base = process.env.PLAYWRIGHT_BROWSERS_PATH || '/opt/pw-browsers';
  const dirs = fs.readdirSync(base).filter(d => d.startsWith('chromium-')).sort();
  return path.join(base, dirs[dirs.length - 1], 'chrome-linux', 'chrome');
}

async function run(page, line) {
  const [cmd, ...args] = line.trim().split(/\s+/);
  const rest = line.trim().slice(cmd.length + 1);
  switch (cmd) {
    case 'wait': return page.evaluate(ms => K.wait(ms), Number(args[0]));
    case 'type': return page.evaluate(t => K.typeU(t), rest.replace(/\\n/g, '\n'));
    case 'key': return page.evaluate(([c, ms]) => K.key(c, ms), [keyCode(args[0]), Number(args[1] || 120)]);
    case 'down': return page.evaluate(c => K.raw(c, true), keyCode(args[0]));
    case 'up': return page.evaluate(c => K.raw(c, false), keyCode(args[0]));
    case 'keys': return page.evaluate(cs => K.keys(cs), args.map(keyCode));
    case 'snap': return page.evaluate(n => K.snap(n), args[0]);
    case 'rec': return page.evaluate(([m, e]) => K.startRec(m, e), [Number(args[0]), Number(args[1] || 0)]);
    case 'save': return page.evaluate(n => K.saveRec(n), args[0]);
    case 'js': return page.evaluate(rest);
    default: throw new Error('unknown command: ' + cmd);
  }
}

(async () => {
  const browser = await chromium.launch({
    executablePath: findChrome(), headless: true,
    args: ['--autoplay-policy=no-user-gesture-required'],
  });
  const page = await browser.newPage({ viewport: { width: 1000, height: 650 } });
  page.on('console', m => { if (m.type() === 'error') console.log('console:', m.text()); });
  await page.goto(process.env.URL || 'http://127.0.0.1:8765/index.html');
  await page.waitForFunction(() => window.K && window.K.ci, null, { timeout: 60000 });
  console.log('ready');
  const start = Date.now();
  const input = process.argv[2] ? fs.createReadStream(process.argv[2]) : process.stdin;
  for await (const line of readline.createInterface({ input })) {
    if (!line.trim() || line.trim().startsWith('#')) continue;
    if (line.trim() === 'quit') break;
    try {
      const result = await run(page, line);
      console.log('ok', Date.now() - start, line.trim(), result === undefined ? '' : JSON.stringify(result));
    } catch (e) {
      console.log('error', line.trim(), e.message);
    }
  }
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
