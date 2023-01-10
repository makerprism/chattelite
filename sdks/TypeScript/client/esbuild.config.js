const esbuild = require('esbuild')
const { nodeExternalsPlugin } = require('esbuild-node-externals')

const externals = nodeExternalsPlugin({
    allowList: ["event-source-with-headers"]
});

esbuild.build({
    entryPoints: ['./src/browser.ts'],
    outfile: 'browser-lib/chattelite-client.js',
    bundle: true,
    minify: false,
    platform: 'browser',
    sourcemap: true,
    target: 'es2015',
    plugins: [externals]
}).catch(() => process.exit(1))

esbuild.build({
    entryPoints: ['./src/browser.ts'],
    outfile: 'browser-lib/chattelite-client.min.js',
    bundle: true,
    minify: true,
    platform: 'browser',
    sourcemap: true,
    target: 'es2015',
    plugins: [externals]
}).catch(() => process.exit(1))
