import assert from 'node:assert/strict';
import {readdirSync, readFileSync} from 'node:fs';
import {dirname, join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const scriptPath = fileURLToPath(import.meta.url);
const siteRoot = resolve(dirname(scriptPath), '..');
const pages = [
  {id: 'overview', slug: '/'},
  {id: 'getting-started', slug: '/getting-started'},
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

export function checkTranslations(root = siteRoot) {
  const expectedFiles = pages.map(({id}) => `${id}.md`).sort();
  for (const directory of ['docs', 'i18n/ja/docusaurus-plugin-content-docs/current']) {
    const contentRoot = join(root, directory);
    assert.deepEqual(markdownFiles(contentRoot), expectedFiles, `${directory}: document set does not match the three-page manifest`);
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
    }
  }

  const navbarFile = 'i18n/ja/docusaurus-theme-classic/navbar.json';
  const navbar = JSON.parse(readFileSync(join(root, navbarFile), 'utf8'));
  for (const key of navbarKeys) {
    const message = navbar[key]?.message;
    assert(typeof message === 'string' && message.trim(), `${navbarFile}: missing or empty ${key}`);
  }
}

if (process.argv[1] && resolve(process.argv[1]) === scriptPath) {
  try {
    checkTranslations(process.argv[2] ? resolve(process.argv[2]) : siteRoot);
    console.log('English/Japanese document structure and navbar translations are complete.');
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
