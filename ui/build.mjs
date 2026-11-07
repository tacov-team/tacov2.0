// Baut die NUI mit esbuild nach ../server/resources/[tacov]/tacov_core/ui/
import * as esbuild from 'esbuild';
import { mkdirSync, copyFileSync, readdirSync, writeFileSync, statSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const out = join(here, '..', 'server', 'resources', '[tacov]', 'tacov_core', 'ui');
const watch = process.argv.includes('--watch');

mkdirSync(join(out, 'assets', 'items'), { recursive: true });
for (const f of readdirSync(join(here, 'public'))) {
  const src = join(here, 'public', f);
  if (statSync(src).isFile()) copyFileSync(src, join(out, 'assets', f));
}

// Item-Icons: PNG hat Vorrang vor SVG; items/index.json sagt der UI, welche Datei es je Item gibt
const itemDir = join(here, 'public', 'items');
const index = {};
if (existsSync(itemDir)) {
  for (const f of readdirSync(itemDir)) {
    const m = /^([a-z0-9_]+)\.(png|svg)$/.exec(f);
    if (!m) continue;
    const [, name, ext] = m;
    if (index[name] === 'png') continue; // PNG bleibt
    index[name] = ext;
    copyFileSync(join(itemDir, f), join(out, 'assets', 'items', f));
  }
}
writeFileSync(join(out, 'assets', 'items', 'index.json'), JSON.stringify(index));


writeFileSync(join(out, 'index.html'), `<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<title>TacoV</title>
<link rel="stylesheet" href="app.css">
</head>
<body>
<div id="root"></div>
<script src="app.js"></script>
</body>
</html>
`);

const options = {
  entryPoints: [join(here, 'src', 'main.tsx')],
  bundle: true,
  minify: !watch,
  sourcemap: watch ? 'inline' : false,
  target: ['chrome103'],
  format: 'iife',
  outfile: join(out, 'app.js'),
  loader: { '.png': 'file', '.svg': 'file' },
  external: ['*.ttf', '*.otf', '*.woff', '*.woff2'], // Schrift-URLs bleiben relativ zu index.html stehen
  define: { 'process.env.NODE_ENV': watch ? '"development"' : '"production"', __ITEM_ICONS__: JSON.stringify(index) },
  logLevel: 'info',
};

if (watch) {
  const ctx = await esbuild.context(options);
  await ctx.watch();
} else {
  await esbuild.build(options);
}
