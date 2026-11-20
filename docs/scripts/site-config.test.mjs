import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {createRequire} from 'node:module';
import {dirname, join, resolve} from 'node:path';
import test from 'node:test';
import {fileURLToPath} from 'node:url';
import {runInNewContext} from 'node:vm';
import ts from 'typescript';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const configPath = join(root, 'docusaurus.config.ts');
const readJson = (path) => JSON.parse(readFileSync(join(root, path), 'utf8'));
const manifest = readJson('package.json');
const lock = readJson('package-lock.json');
const siteDependencies = [
  '@docusaurus/plugin-content-docs',
  '@docusaurus/plugin-content-pages',
  '@docusaurus/plugin-debug',
  '@docusaurus/plugin-sitemap',
  '@docusaurus/theme-classic',
  '@docusaurus/theme-common',
];

function loadConfig(environment) {
  const {outputText, diagnostics} = ts.transpileModule(readFileSync(configPath, 'utf8'), {
    fileName: configPath,
    reportDiagnostics: true,
    compilerOptions: {
      module: ts.ModuleKind.CommonJS,
      target: ts.ScriptTarget.ES2022,
      esModuleInterop: true,
    },
  });
  assert.equal(diagnostics.length, 0);
  const module = {exports: {}};
  runInNewContext(outputText, {
    module,
    exports: module.exports,
    require: createRequire(configPath),
    process: {env: environment === undefined ? {} : {NODE_ENV: environment}},
  }, {filename: configPath, timeout: 5000});
  return JSON.parse(JSON.stringify(module.exports.default));
}

test('pins explicitly configured Docusaurus packages to the core version', () => {
  const version = manifest.dependencies['@docusaurus/core'];
  assert.match(version, /^\d+\.\d+\.\d+$/);
  for (const name of siteDependencies) {
    assert.equal(manifest.dependencies[name], version, name);
    assert.equal(lock.packages[`node_modules/${name}`].version, version, name);
  }
  for (const [name, value] of Object.entries({...manifest.dependencies, ...manifest.devDependencies})) {
    if (name.startsWith('@docusaurus/')) assert.equal(value, version, name);
  }
});

test('does not install the unused preset and vulnerable SVG dependency path', () => {
  const packages = Object.keys(lock.packages);
  for (const name of [
    '@docusaurus/preset-classic', '@docusaurus/plugin-svgr',
    '@svgr/webpack', '@svgr/plugin-svgo', 'deepmerge',
  ]) {
    assert(!Object.hasOwn(manifest.dependencies, name), name);
    assert(!Object.hasOwn(manifest.devDependencies, name), name);
    assert(!packages.some((path) => path === `node_modules/${name}` || path.endsWith(`/node_modules/${name}`)), name);
  }
});

for (const environment of ['production', 'development', undefined]) {
  test(`registers the intended plugins for NODE_ENV=${environment ?? '(unset)'}`, () => {
    const config = loadConfig(environment);
    assert.equal(config.presets, undefined);
    assert.deepEqual(config.plugins, [
      ['@docusaurus/plugin-content-docs', {sidebarPath: './sidebars.ts', routeBasePath: '/'}],
      '@docusaurus/plugin-content-pages',
      environment === 'production' ? '@docusaurus/plugin-sitemap' : '@docusaurus/plugin-debug',
    ]);
    assert.deepEqual(config.themes, [
      ['@docusaurus/theme-classic', {customCss: './src/css/custom.css'}],
    ]);
  });
}

test('preserves the six-locale URL and navigation contract without a preset', () => {
  const config = loadConfig('production');
  assert.equal(config.url, 'https://librarylibrarian.github.io');
  assert.equal(config.baseUrl, '/misskey_mfm_renderer/');
  assert.equal(config.trailingSlash, true);
  assert.deepEqual(config.i18n, readJson('locales.json'));
  assert.equal(config.onBrokenLinks, 'throw');
  assert.equal(config.onBrokenAnchors, 'throw');
  assert.equal(config.markdown.hooks.onBrokenMarkdownLinks, 'throw');
  assert.equal(config.themeConfig.colorMode.respectPrefersColorScheme, true);
  assert.deepEqual(config.themeConfig.navbar.items.slice(0, 2), [
    {type: 'docSidebar', sidebarId: 'docsSidebar', label: 'Docs', position: 'left'},
    {type: 'localeDropdown', position: 'right'},
  ]);
  assert.deepEqual(config.themeConfig.prism.additionalLanguages, ['dart', 'yaml', 'bash']);
});
