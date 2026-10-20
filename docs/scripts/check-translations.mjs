import assert from 'node:assert/strict';
import {readdirSync, readFileSync} from 'node:fs';
import {dirname, join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const scriptPath = fileURLToPath(import.meta.url);
const siteRoot = resolve(dirname(scriptPath), '..');
const pages = [
  {id: 'overview', slug: '/'},
  {id: 'getting-started', slug: '/getting-started'},
  {id: 'rendering', slug: '/rendering'},
  {id: 'configuration', slug: '/configuration'},
  {id: 'custom-emoji', slug: '/custom-emoji'},
  {id: 'interactions', slug: '/interactions'},
  {id: 'animation-accessibility', slug: '/animation-accessibility'},
  {id: 'example', slug: '/example'},
];
const navbarKeys = [
  'title',
  'item.label.Docs',
  'item.label.GitHub',
  'item.label.pub.dev',
  'item.label.API reference',
];

function markdownFiles(directory, prefix = '') {
  return readdirSync(directory, {withFileTypes: true}).flatMap((entry) => {
    const relative = `${prefix}${entry.name}`;
    if (entry.isDirectory()) {
      return markdownFiles(join(directory, entry.name), `${relative}/`);
    }
    return /\.mdx?$/.test(entry.name) ? [relative] : [];
  }).sort();
}

function field(frontMatter, key, file) {
  const matches = [...frontMatter.matchAll(new RegExp(`^${key}:([^\\r\\n]*)$`, 'gm'))];
  assert.equal(matches.length, 1, `${file}: expected one ${key} field`);
  const value = matches[0][1].trim();
  assert(
    value && !/^["'|>]/.test(value) && !/(?:^|\s)#/.test(value) && !/^(?:null|~|true|false)$/i.test(value),
    `${file}: ${key} must be a nonempty, unquoted text scalar without comments`,
  );
  return value;
}

function readLocales(root) {
  const config = JSON.parse(readFileSync(join(root, 'locales.json'), 'utf8'));
  assert(config && typeof config === 'object', 'locales.json: expected an object');
  assert.equal(config.defaultLocale, 'en', 'locales.json: defaultLocale must be en');
  assert(Array.isArray(config.locales) && config.locales.length > 0, 'locales.json: expected locales');
  assert.equal(config.locales[0], 'en', 'locales.json: English must be first');
  assert.equal(new Set(config.locales).size, config.locales.length, 'locales.json: duplicate locale');
  for (const locale of config.locales) {
    assert(typeof locale === 'string' && /^[a-z]{2}(?:-[A-Za-z0-9]+)*$/.test(locale), 'locales.json: invalid locale code');
    const label = config.localeConfigs?.[locale]?.label;
    assert(typeof label === 'string' && label.trim(), `locales.json: missing label for ${locale}`);
  }
  assert.deepEqual(Object.keys(config.localeConfigs).sort(), [...config.locales].sort(), 'locales.json: localeConfigs mismatch');
  return config.locales;
}

function codeBlocks(body, file) {
  // Guides use unindented triple-backtick fences; preserve info strings and bodies.
  const blocks = [];
  let block;
  for (const line of body.split('\n')) {
    if (block) {
      if (/^```[ \t]*$/.test(line)) {
        blocks.push(block);
        block = undefined;
      } else {
        block.body += `${line}\n`;
      }
    } else if (line.startsWith('```')) {
      block = {info: line.slice(3), body: ''};
    }
  }
  assert(!block, `${file}: unclosed code fence`);
  return blocks;
}

export function checkTranslations(root = siteRoot) {
  const locales = readLocales(root);
  const expectedFiles = pages.map(({id}) => `${id}.md`).sort();
  const sourceBlocks = new Map();
  for (const locale of locales) {
    const directory = locale === 'en' ? 'docs' : `i18n/${locale}/docusaurus-plugin-content-docs/current`;
    const contentRoot = join(root, directory);
    assert.deepEqual(markdownFiles(contentRoot), expectedFiles, `${directory}: document set does not match the eight-page manifest`);
    for (const {id, slug} of pages) {
      const file = `${directory}/${id}.md`;
      const text = readFileSync(join(root, file), 'utf8').replace(/\r\n/g, '\n');
      const match = /^---\n([\s\S]*?)\n---\n([\s\S]*)$/.exec(text);
      assert(match, `${file}: expected opening front matter`);
      assert.equal(field(match[1], 'id', file), id, `${file}: unexpected id`);
      assert.equal(field(match[1], 'slug', file), slug, `${file}: unexpected slug`);
      field(match[1], 'title', file);
      field(match[1], 'sidebar_label', file);
      assert(match[2].trim(), `${file}: document body is empty`);
      const blocks = codeBlocks(match[2], file);
      if (locale === 'en') sourceBlocks.set(id, blocks);
      else assert.deepEqual(blocks, sourceBlocks.get(id), `${file}: code blocks differ from English`);
    }
    if (locale !== 'en') {
      const navbarFile = `i18n/${locale}/docusaurus-theme-classic/navbar.json`;
      const navbar = JSON.parse(readFileSync(join(root, navbarFile), 'utf8'));
      for (const key of navbarKeys) {
        const message = navbar?.[key]?.message;
        assert(typeof message === 'string' && message.trim(), `${navbarFile}: missing or empty ${key}`);
      }
    }
  }
}

if (process.argv[1] && resolve(process.argv[1]) === scriptPath) {
  try {
    checkTranslations(process.argv[2] ? resolve(process.argv[2]) : siteRoot);
    console.log('All configured locales have complete document structure, matching code examples and navbar translations.');
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
