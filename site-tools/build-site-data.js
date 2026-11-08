const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const PACK = 'C:\\Users\\rival\\Documents\\Ngoding\\Bug-Bounty-Finder\\bounty-skills-pack';
const OUT  = 'C:\\Users\\rival\\Documents\\Ngoding\\Bug-Bounty-Finder\\bounty-skills-site';

const TEXT_EXT = new Set(['.md','.txt','.json','.py','.sh','.ps1','.sol','.toml','.yml','.yaml','.csv','.cfg','.ini','.template','.sample']);
const SKIP_DIRS = new Set(['.git','node_modules']);

function walk(dir, base) {
  base = base || '';
  const out = [];
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const rel = base ? base + '/' + e.name : e.name;
    const abs = path.join(dir, e.name);
    if (e.isDirectory()) {
      if (SKIP_DIRS.has(e.name)) continue;
      out.push.apply(out, walk(abs, rel));
    } else {
      out.push({ rel: rel, abs: abs, size: fs.statSync(abs).size });
    }
  }
  return out;
}

function isText(rel) {
  const ext = path.extname(rel).toLowerCase();
  if (TEXT_EXT.has(ext)) return true;
  if (path.basename(rel) === '.gitignore') return true;
  return false;
}

// Collision-free id: sha256 of the full path, hex, 24 chars.
// A truncated base64url of the path collides on long CJK paths.
function makeId(rel) {
  return crypto.createHash('sha256').update(rel, 'utf8').digest('hex').slice(0, 24);
}

if (!fs.existsSync(OUT)) fs.mkdirSync(OUT, { recursive: true });
const DATA = path.join(OUT, 'data');
if (fs.existsSync(DATA)) fs.rmSync(DATA, { recursive: true, force: true });
fs.mkdirSync(DATA, { recursive: true });

const files = walk(PACK);
const manifest = [];
let skipped = 0;
const seen = new Map();

for (const f of files) {
  if (!isText(f.rel)) { skipped++; continue; }
  const id = makeId(f.rel);
  if (seen.has(id)) {
    throw new Error('ID COLLISION: ' + f.rel + ' vs ' + seen.get(id));
  }
  seen.set(id, f.rel);
  const content = fs.readFileSync(f.abs, 'utf8');
  const rec = { path: f.rel, size: f.size, ext: path.extname(f.rel).toLowerCase(), content: content };
  fs.writeFileSync(path.join(DATA, id + '.json'), JSON.stringify(rec));
  manifest.push({ id: id, path: f.rel, size: f.size, ext: rec.ext });
}

fs.writeFileSync(path.join(DATA, '_manifest.json'), JSON.stringify(manifest));

const index = manifest.map(function (m) {
  const rec = JSON.parse(fs.readFileSync(path.join(DATA, m.id + '.json'), 'utf8'));
  return { id: m.id, path: m.path, size: m.size, preview: rec.content.slice(0, 400).replace(/\s+/g, ' ') };
});
fs.writeFileSync(path.join(DATA, '_index.json'), JSON.stringify(index));

console.log('text files embedded:', manifest.length);
console.log('binary skipped    :', skipped);
console.log('unique ids        :', seen.size);
console.log('total bytes       :', manifest.reduce(function (a, b) { return a + b.size; }, 0));