import assert from 'node:assert/strict';
import {mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname, join} from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import test from 'node:test';
import {checkTranslations} from './check-translations.mjs';

const jaRoot = 'i18n/ja/docusaurus-plugin-content-docs/current';
const navbarFile = 'i18n/ja/docusaurus-theme-classic/navbar.json';
const script = fileURLToPath(new URL('./check-translations.mjs', import.meta.url));

function fixture(t) {
  const root = mkdtempSync(join(tmpdir(), 'mfm-docs-translations-'));
  t.after(() => rmSync(root, {recursive: true, force: true}));
  for (const directory of ['docs', jaRoot]) {
    mkdirSync(join(root, directory), {recursive: true});
    for (const [id, slug] of [['overview', '/'], ['getting-started', '/getting-started'], ['example', '/example']]) {
      writeFileSync(join(root, directory, `${id}.md`), `---\nid: ${id}\nslug: ${slug}\ntitle: Title\nsidebar_label: Label\n---\nBody\n`);
    }
  }
  const navbar = Object.fromEntries(['title', 'Docs', 'GitHub', 'pub.dev', 'API reference'].map((label) => [label === 'title' ? label : `item.label.${label}`, {message: label}]));
  mkdirSync(dirname(join(root, navbarFile)), {recursive: true});
  writeFileSync(join(root, navbarFile), JSON.stringify(navbar));
  return root;
}

function change(root, file, before, after) {
  const path = join(root, file);
  const original = readFileSync(path, 'utf8');
  assert(original.includes(before));
  writeFileSync(path, original.replace(before, after));
}

test('accepts matching pages and navbar labels', (t) => {
  assert.doesNotThrow(() => checkTranslations(fixture(t)));
});

test('CLI resolves the actual site independently of the working directory', () => {
  const result = spawnSync(process.execPath, [script], {cwd: tmpdir(), encoding: 'utf8'});
  assert.equal(result.status, 0, result.stderr);
});

test('CLI exits nonzero for a missing Japanese page', (t) => {
  const root = fixture(t);
  rmSync(join(root, jaRoot, 'example.md'));
  const result = spawnSync(process.execPath, [script, root], {encoding: 'utf8'});
  assert.equal(result.status, 1);
  assert.match(result.stderr, /document set/);
});

test('rejects extra nested MDX pages instead of silently falling back', (t) => {
  const root = fixture(t);
  mkdirSync(join(root, 'docs', 'extra'));
  writeFileSync(join(root, 'docs', 'extra', 'page.mdx'), '# Extra');
  assert.throws(() => checkTranslations(root), /document set/);
});

for (const [name, before, after, error] of [
  ['id', 'id: example', 'id: other', /unexpected id/],
  ['slug', 'slug: /example', 'slug: /other', /unexpected slug/],
  ['title', 'title: Title', 'title: ', /title must be/],
  ['sidebar label', 'sidebar_label: Label', 'sidebar_label: ', /sidebar_label must be/],
  ['body', 'Body', '', /body is empty/],
  ['comment-only title', 'title: Title', 'title: # TODO', /title must be/],
  ['null title', 'title: Title', 'title: null', /title must be/],
  ['uppercase null title', 'title: Title', 'title: NULL', /title must be/],
  ['null sidebar label', 'sidebar_label: Label', 'sidebar_label: ~', /sidebar_label must be/],
  ['commented null title', 'title: Title', 'title: null # TODO', /title must be/],
  ['boolean title', 'title: Title', 'title: true', /title must be/],
]) {
  test(`rejects invalid ${name}`, (t) => {
    const root = fixture(t);
    change(root, `${jaRoot}/example.md`, before, after);
    assert.throws(() => checkTranslations(root), error);
  });
}

for (const missing of [true, false]) {
  test(`rejects ${missing ? 'missing' : 'empty'} navbar messages`, (t) => {
    const root = fixture(t);
    const path = join(root, navbarFile);
    const navbar = JSON.parse(readFileSync(path, 'utf8'));
    if (missing) delete navbar['item.label.Docs'];
    else navbar['item.label.Docs'].message = '  ';
    writeFileSync(path, JSON.stringify(navbar));
    assert.throws(() => checkTranslations(root), /missing or empty item.label.Docs/);
  });
}
