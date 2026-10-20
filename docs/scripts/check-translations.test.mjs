import assert from 'node:assert/strict';
import {mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {dirname, join} from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import test from 'node:test';
import {checkTranslations} from './check-translations.mjs';

const locales = ['en', 'ja', 'zh-Hans', 'de', 'fr', 'ko'];
const ids = ['overview', 'getting-started', 'rendering', 'configuration', 'custom-emoji', 'interactions', 'animation-accessibility', 'example'];
const script = fileURLToPath(new URL('./check-translations.mjs', import.meta.url));
const contentRoot = (locale) => locale === 'en' ? 'docs' : `i18n/${locale}/docusaurus-plugin-content-docs/current`;
const navbarFile = (locale) => `i18n/${locale}/docusaurus-theme-classic/navbar.json`;
const localeConfig = () => ({
  defaultLocale: 'en',
  locales,
  localeConfigs: Object.fromEntries(locales.map((locale) => [locale, {label: locale}])),
});

function fixture(t) {
  const root = mkdtempSync(join(tmpdir(), 'mfm-docs-translations-'));
  t.after(() => rmSync(root, {recursive: true, force: true}));
  writeFileSync(join(root, 'locales.json'), JSON.stringify(localeConfig()));
  for (const locale of locales) {
    const directory = contentRoot(locale);
    mkdirSync(join(root, directory), {recursive: true});
    for (const id of ids) {
      const slug = id === 'overview' ? '/' : `/${id}`;
      writeFileSync(join(root, directory, `${id}.md`), `---\nid: ${id}\nslug: ${slug}\ntitle: Title\nsidebar_label: Label\n---\nBody\n`);
    }
    if (locale !== 'en') {
      const navbar = Object.fromEntries(['title', 'Docs', 'GitHub', 'pub.dev', 'API reference'].map((label) => [label === 'title' ? label : `item.label.${label}`, {message: label}]));
      const path = join(root, navbarFile(locale));
      mkdirSync(dirname(path), {recursive: true});
      writeFileSync(path, JSON.stringify(navbar));
    }
  }
  return root;
}

function change(root, file, before, after) {
  const path = join(root, file);
  const original = readFileSync(path, 'utf8');
  assert(original.includes(before));
  writeFileSync(path, original.replace(before, after));
}

function addCode(root, code) {
  for (const locale of locales) change(root, `${contentRoot(locale)}/rendering.md`, 'Body', `Body\n${code}`);
}

test('site retains exactly the six required locales with English as default', () => {
  const config = JSON.parse(readFileSync(new URL('../locales.json', import.meta.url), 'utf8'));
  assert.deepEqual(config.locales, locales);
  assert.equal(config.defaultLocale, 'en');
});

test('accepts complete six-locale pages and navbar labels', (t) => {
  assert.doesNotThrow(() => checkTranslations(fixture(t)));
});

test('CLI resolves the actual site independently of the working directory', () => {
  const result = spawnSync(process.execPath, [script], {cwd: tmpdir(), encoding: 'utf8'});
  assert.equal(result.status, 0, result.stderr);
});

for (const [name, modify, error] of [
  ['default', (c) => { c.defaultLocale = 'ja'; }, /defaultLocale/],
  ['order', (c) => { c.locales = ['ja', 'en']; }, /English must be first/],
  ['duplicates', (c) => { c.locales = ['en', 'ja', 'ja']; }, /duplicate locale/],
  ['unsafe code', (c) => { c.locales = ['en', '../fr']; }, /invalid locale code/],
  ['missing locales', (c) => { delete c.locales; }, /expected locales/],
  ['empty locales', (c) => { c.locales = []; }, /expected locales/],
  ['empty label', (c) => { c.localeConfigs.fr.label = ' '; }, /missing label for fr/],
  ['missing config', (c) => { delete c.localeConfigs; }, /missing label/],
  ['extra config', (c) => { c.localeConfigs.es = {label: 'Español'}; }, /localeConfigs mismatch/],
]) {
  test(`rejects locale configuration: ${name}`, (t) => {
    const root = fixture(t);
    const config = localeConfig();
    modify(config);
    writeFileSync(join(root, 'locales.json'), JSON.stringify(config));
    assert.throws(() => checkTranslations(root), error);
  });
}

for (const locale of locales) {
  const directory = contentRoot(locale);
  test(`${locale}: rejects a missing content directory`, (t) => {
    const root = fixture(t);
    rmSync(join(root, directory), {recursive: true});
    assert.throws(() => checkTranslations(root), /ENOENT/);
  });
  for (const id of ids) {
    test(`${locale}: rejects missing page ${id}`, (t) => {
      const root = fixture(t);
      rmSync(join(root, directory, `${id}.md`));
      assert.throws(() => checkTranslations(root), /document set/);
    });
  }
  test(`${locale}: rejects extra nested MDX pages`, (t) => {
    const root = fixture(t);
    mkdirSync(join(root, directory, 'extra'));
    writeFileSync(join(root, directory, 'extra', 'page.mdx'), '# Extra');
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
    test(`${locale}: rejects invalid ${name}`, (t) => {
      const root = fixture(t);
      change(root, `${directory}/example.md`, before, after);
      assert.throws(() => checkTranslations(root), error);
    });
  }
  if (locale === 'en') continue;
  test(`${locale}: CLI exits nonzero for a missing translated page`, (t) => {
    const root = fixture(t);
    rmSync(join(root, directory, 'example.md'));
    const result = spawnSync(process.execPath, [script, root], {encoding: 'utf8'});
    assert.equal(result.status, 1);
    assert.match(result.stderr, /document set/);
  });
  for (const kind of ['file', 'json', 'key', 'empty']) {
    test(`${locale}: rejects navbar ${kind} failure`, (t) => {
      const root = fixture(t);
      const path = join(root, navbarFile(locale));
      if (kind === 'file') rmSync(path);
      else if (kind === 'json') writeFileSync(path, '{');
      else {
        const navbar = JSON.parse(readFileSync(path, 'utf8'));
        if (kind === 'key') delete navbar['item.label.Docs'];
        else navbar['item.label.Docs'].message = '  ';
        writeFileSync(path, JSON.stringify(navbar));
      }
      assert.throws(() => checkTranslations(root));
    });
  }
  for (const language of ['dart', 'yaml', 'bash']) {
    const first = `\`\`\`${language}\nfirst\n\`\`\`\n`;
    const second = `\`\`\`${language} title="second"\nsecond\n\`\`\`\n`;
    for (const [name, translated, valid] of [
      ['matching', first + second, true],
      ['missing', first, false],
      ['reordered', second + first, false],
      ['changed body', first + second.replace('\nsecond\n', '\nchanged\n'), false],
      ['extra', first + second + first, false],
      ['language suffix', first.replace(language, `${language}ish`) + second, false],
      ['info string', first + second.replace('title="second"', 'title="other"'), false],
      ['unclosed', first + second.slice(0, -4), false],
      ['CRLF', (first + second).replaceAll('\n', '\r\n'), true],
    ]) {
      test(`${locale}: ${language} parity: ${name}`, (t) => {
        const root = fixture(t);
        addCode(root, first + second);
        change(root, `${directory}/rendering.md`, first + second, translated);
        if (valid) assert.doesNotThrow(() => checkTranslations(root));
        else assert.throws(() => checkTranslations(root), /code blocks differ|unclosed code fence/);
      });
    }
  }
}
