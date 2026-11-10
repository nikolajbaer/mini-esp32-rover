// Controller page served at http://192.168.4.1/
#pragma once

static const char INDEX_HTML[] = R"HTML(<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
<title>Mini Rover</title>
<style>
  html, body { margin: 0; height: 100%; background: #14171c; color: #dfe5ee;
    font: 16px system-ui, sans-serif; overflow: hidden; touch-action: none;
    user-select: none; -webkit-user-select: none; }
  #bar { position: fixed; top: 0; left: 0; right: 0; display: flex; gap: 12px;
    align-items: center; padding: 10px 14px; }
  #dot { width: 12px; height: 12px; border-radius: 50%; background: #d9534f; }
  #dot.on { background: #4cc38a; }
  #bar label { margin-left: auto; display: flex; gap: 8px; align-items: center; }
  #pad { position: fixed; inset: 56px 0 0 0; display: grid; place-items: center; }
  #ring { width: min(70vw, 70vh); aspect-ratio: 1; border-radius: 50%;
    border: 2px solid #3a4250; position: relative; background: #1b2028; }
  #knob { position: absolute; left: 50%; top: 50%; width: 30%; aspect-ratio: 1;
    border-radius: 50%; background: #5b9dff; transform: translate(-50%, -50%); }
  #hint { position: fixed; bottom: 10px; left: 0; right: 0; text-align: center;
    color: #77808f; font-size: 13px; }
</style>
</head>
<body>
<div id="bar">
  <div id="dot"></div><span id="status">connecting</span>
  <label>speed <input id="limit" type="range" min="30" max="100" value="100"></label>
</div>
<div id="pad"><div id="ring"><div id="knob"></div></div></div>
<div id="hint">drag the stick, or use WASD / arrow keys</div>
<script>
const ring = document.getElementById('ring'), knob = document.getElementById('knob');
const dot = document.getElementById('dot'), statusEl = document.getElementById('status');
const limit = document.getElementById('limit');
let x = 0, y = 0;          // stick position, -1..1 (y: forward positive)
let ws = null;
const keys = new Set();

function connect() {
  ws = new WebSocket('ws://' + location.host + '/ws');
  ws.onopen = () => { dot.className = 'on'; statusEl.textContent = 'connected'; };
  ws.onclose = () => { dot.className = ''; statusEl.textContent = 'reconnecting';
    setTimeout(connect, 500); };
  ws.onerror = () => ws.close();
}
connect();

function setStick(nx, ny) {
  const m = Math.hypot(nx, ny);
  if (m > 1) { nx /= m; ny /= m; }
  x = nx; y = ny;
  knob.style.left = (50 + nx * 35) + '%';
  knob.style.top = (50 - ny * 35) + '%';
}
function fromPointer(e) {
  const r = ring.getBoundingClientRect();
  setStick((e.clientX - r.left - r.width / 2) / (r.width * 0.35),
          -(e.clientY - r.top - r.height / 2) / (r.height * 0.35));
}
ring.addEventListener('pointerdown', e => { ring.setPointerCapture(e.pointerId); fromPointer(e); });
ring.addEventListener('pointermove', e => { if (ring.hasPointerCapture(e.pointerId)) fromPointer(e); });
for (const t of ['pointerup', 'pointercancel', 'lostpointercapture'])
  ring.addEventListener(t, () => setStick(0, 0));

function fromKeys() {
  const h = k => keys.has(k);
  setStick((h('d') || h('arrowright') ? 1 : 0) - (h('a') || h('arrowleft') ? 1 : 0),
           (h('w') || h('arrowup') ? 1 : 0) - (h('s') || h('arrowdown') ? 1 : 0));
}
addEventListener('keydown', e => { keys.add(e.key.toLowerCase()); fromKeys(); });
addEventListener('keyup', e => { keys.delete(e.key.toLowerCase()); fromKeys(); });
addEventListener('blur', () => { keys.clear(); setStick(0, 0); });

// Arcade mix -> left/right track speeds, sent 20x a second. The rover stops by
// itself if these stop arriving.
setInterval(() => {
  if (!ws || ws.readyState !== 1) return;
  const k = 255 * limit.value / 100;
  const turn = x * 0.7;   // soften steering so it is controllable
  const clamp = v => Math.max(-1, Math.min(1, v));
  const l = Math.round(clamp(y + turn) * k), r = Math.round(clamp(y - turn) * k);
  ws.send(l + ',' + r);
}, 50);
</script>
</body>
</html>
)HTML";
