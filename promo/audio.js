// Synthesizes the soundtrack (120 BPM, A minor) with hits synced to index.html's timeline.
const fs = require('fs');
const SR = 44100, DUR = 36, N = SR * DUR;
const L = new Float32Array(N), R = new Float32Array(N);
let seed = 1; const noise = () => (seed = (seed * 1664525 + 1013904223) >>> 0) / 2147483648 - 1;
const add = (t0, len, fn, gain = 1, pan = 0) => {
  const s0 = Math.floor(t0 * SR), n = Math.floor(len * SR);
  for (let i = 0; i < n; i++) {
    const k = s0 + i; if (k < 0 || k >= N) continue;
    const v = fn(i / SR) * gain; L[k] += v * Math.min(1, 1 - pan); R[k] += v * Math.min(1, 1 + pan);
  }
};
const sin = (f, t) => Math.sin(2 * Math.PI * f * t);
const lp = () => { let y = 0; return (x, a) => (y += a * (x - y)); };

// pad: Am F C G, 2s per chord, detuned saws through a lowpass
const CH = [[220, 261.63, 329.63], [174.61, 220, 261.63], [196, 261.63, 329.63], [196, 246.94, 293.66]];
const ROOT = [110, 87.31, 130.81, 98];
for (let k = 0; k < 18; k++) {
  const ch = k >= 16 ? CH[0] : CH[k % 4];
  for (const f of ch) for (const dt of [-.004, .004]) {
    const filt = lp();
    add(k * 2, 2.4, t => {
      const saw = 2 * ((f * (1 + dt) * t) % 1) - 1;
      const env = Math.min(1, t / .35) * Math.min(1, (2.4 - t) / .4);
      return filt(saw, .06) * env;
    }, .09, dt < 0 ? -.4 : .4);
  }
}
// sub bass + kick on every beat, hats on offbeats, clap on 2 & 4
for (let b = 8; b < 70; b++) {
  const t = b * .5;
  add(t, .5, x => Math.tanh(2 * sin(ROOT[Math.floor(t / 2) % 4], x)) * Math.exp(-x * 4), .22);
  add(t, .5, x => Math.sin(2 * Math.PI * (45 * x + 105 * (1 - Math.exp(-30 * x)) / 30)) * Math.exp(-x * 7), .9);
  if (t >= 7.5) { let pv = 0; add(t + .25, .08, x => { const n = noise(), y = n - pv; pv = n; return y * Math.exp(-x * 70); }, .1, b % 2 ? .3 : -.3); }
  if (t >= 19.5 && b % 2) add(t, .25, x => noise() * Math.exp(-x * 18) * .7 + sin(190, x) * Math.exp(-x * 30) * .5, .35);
}
// riser into the logo, then impact
{ const f = lp(); add(2.4, 1.6, x => f(noise(), .01 + .3 * Math.pow(x / 1.6, 3)) * Math.pow(x / 1.6, 2), .5); }
add(4, 2, x => sin(48, x) * Math.exp(-x * 2.2), 1);
add(4, .6, x => noise() * Math.exp(-x * 9), .35);
// whooshes into each scene change
for (const T of [7.5, 19.5, 25, 28, 31.5]) {
  const f = lp();
  add(T - .45, .65, x => { const e = Math.sin(Math.PI * x / .65); return f(noise(), .02 + .25 * e) * e; }, .7, 0);
}
// ticks / plucks synced to on-screen pops
const pluck = (t, f, g = .12, pan = 0) => add(t, .35, x => (sin(f, x) + .4 * sin(f * 2, x)) * Math.exp(-x * 14), g, pan);
const tick = (t, g = .1) => add(t, .03, x => sin(2400, x) * Math.exp(-x * 160), g);
for (let i = 0; i < 7; i++) tick(.25 + i * .13, .14);
for (let i = 0; i < 4; i++) tick(2.3 + i * .08, .12);
[880, 1046.5, 1174.7, 1318.5].forEach((f, i) => pluck(2.75 + i * .2, f, .13));
[9.0, 10.25, 10.95].forEach(t => tick(t, .2));
for (let i = 0; i < 11; i++) add(11.9 + i * .25, .12, x => sin(600 + 2500 * x, x) * Math.exp(-x * 30), .07, (i % 2 ? .5 : -.5));
add(14.65, .8, x => (sin(1318.5, x) + sin(1975.5, x) * .6) * Math.exp(-x * 5), .1);
const PENTA = [440, 523.25, 587.33, 659.25, 783.99, 880, 1046.5];
PENTA.forEach((f, i) => pluck(15.7 + i * .5, f, .12, (i % 2 ? .3 : -.3)));
for (let i = 0; i < 6; i++) pluck(19.9 + i * .1, PENTA[i] * 2, .07);
for (let i = 0; i < 11; i++) tick(25.12 + i * .25, .12);
add(30, 1.6, x => (sin(1046.5, x) + .7 * sin(1568, x) + .3 * sin(2093, x)) * Math.exp(-x * 3), .18);
add(30, .3, x => noise() * Math.exp(-x * 20), .2);
add(31.5, 2, x => sin(48, x) * Math.exp(-x * 2.2), .7);

// master: soft clip, normalize, fades
let peak = 0;
for (let i = 0; i < N; i++) { L[i] = Math.tanh(L[i]); R[i] = Math.tanh(R[i]); peak = Math.max(peak, Math.abs(L[i]), Math.abs(R[i])); }
const buf = Buffer.alloc(44 + N * 4);
buf.write('RIFF', 0); buf.writeUInt32LE(36 + N * 4, 4); buf.write('WAVEfmt ', 8);
buf.writeUInt32LE(16, 16); buf.writeUInt16LE(1, 20); buf.writeUInt16LE(2, 22); buf.writeUInt32LE(SR, 24);
buf.writeUInt32LE(SR * 4, 28); buf.writeUInt16LE(4, 32); buf.writeUInt16LE(16, 34); buf.write('data', 36); buf.writeUInt32LE(N * 4, 40);
for (let i = 0; i < N; i++) {
  const t = i / SR, g = .89 / peak * Math.min(1, t / .05) * Math.min(1, Math.max(0, (36 - t) / .8));
  buf.writeInt16LE(Math.round(L[i] * g * 32767), 44 + i * 4);
  buf.writeInt16LE(Math.round(R[i] * g * 32767), 46 + i * 4);
}
fs.writeFileSync(__dirname + '/audio.wav', buf);
console.log('audio.wav written');
