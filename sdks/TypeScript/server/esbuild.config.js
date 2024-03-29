const esbuild = require('esbuild')

// Automatically exclude all node_modules from the bundled version
const { nodeExternalsPlugin } = require('esbuild-node-externals')

esbuild.build({
    entryPoints: ['./src/browser.ts'],
    outfile: 'browser-lib/chattelite.js',
    bundle: true,
    minify: false,
    platform: 'browser',
    sourcemap: true,
    target: 'es2015',
    plugins: [nodeExternalsPlugin()]
}).catch(() => process.exit(1))

esbuild.build({
    entryPoints: ['./src/browser.ts'],
    outfile: 'browser-lib/chattelite.min.js',
    bundle: true,
    minify: true,
    platform: 'browser',
    sourcemap: true,
    target: 'es2015',
    plugins: [nodeExternalsPlugin()]
}).catch(() => process.exit(1))
