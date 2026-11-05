// Baut die NUI mit esbuild nach ../server/resources/[tacov]/core/ui/
import * as esbuild from 'esbuild';
import { mkdirSync, copyFileSync, readdirSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const out = join(here, '..', 'server', 'resources', '[tacov]', 'core', 'ui');
const watch = process.argv.includes('--watch');

mkdirSync(join(out, 'assets'), { recursive: true });
for (const f of readdirSync(join(here, 'public'))) copyFileSync(join(here, 'public', f), join(out, 'assets', f));

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
  define: { 'process.env.NODE_ENV': watch ? '"development"' : '"production"' },
  logLevel: 'info',
};

if (watch) {
  const ctx = await esbuild.context(options);
  await ctx.watch();
} else {
  await esbuild.build(options);
}
