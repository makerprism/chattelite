const esbuild = require('esbuild')

// Automatically exclude all node_modules from the bundled version
const { nodeExternalsPlugin } = require('esbuild-node-externals')

esbuild.build({
  entryPoints: ['./src/browser.ts'],
  outfile: 'browser-lib/index.js',
  bundle: true,
  minify: true,
  platform: 'browser',
  sourcemap: true,
  target: 'es2015',
  plugins: [nodeExternalsPlugin()]
}).catch(() => process.exit(1))


esbuild.build({
    entryPoints: ['./src/index.ts'],
    outfile: 'lib/index.js',
    bundle: true,
    minify: false,
    platform: 'neutral',
    sourcemap: true,
    target: 'es2015',
    plugins: [nodeExternalsPlugin()]
  }).catch(() => process.exit(1))
  