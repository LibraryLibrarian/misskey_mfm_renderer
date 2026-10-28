# Documentation development

This directory contains the Docusaurus documentation in English, Japanese, Simplified Chinese, German, French and Korean. The publication target is <https://librarylibrarian.github.io/misskey_mfm_renderer/>; the root READMEs provide short entry points to these guides and the published API reference. Repository configuration alone does not mean the site is live: see [deployment](deployment.md) for the separate first-publication approval, administrator setup and verification.

## Requirements and installation

Use Node 22 (see `.node-version`) and npm. Run the following from this directory:

```bash
npm ci
```

Commit `package-lock.json` alongside intentional dependency changes. Do not commit `node_modules`, `.docusaurus`, or `build`.

Docusaurus packages are pinned together at `3.10.2`. The lockfile uses Webpack 5.112.0 / webpackbar 7.0.0 without the former Webpack compatibility override. Scoped overrides address vulnerable build dependencies; see [the dependency security review](dependency-security.md) before changing them.

The **2026-10-28** reassessment patches `body-parser`, `fast-uri` and `serialize-javascript`, and removes the unused preset/SVG dependency path to `deepmerge`. The former braces advisory was withdrawn upstream, so its unused exception is removed rather than renewed. **The reviewed dependency graph has zero audit findings and no active exceptions.** See [the current assessment](dependency-security.md#current-dependency-reassessment-2026-10-28) for scope and limitations. Findings of any severity and audit failures remain blocking. Do not add exceptions merely to pass CI, automatically refresh an exception hash/expiry, or use `npm audit fix --force`.

## Plugin configuration

The site registers official plugins directly in `docusaurus.config.ts`, without `@docusaurus/preset-classic`:

- `plugin-content-docs` keeps the existing sidebar and `/` route; `plugin-content-pages` retains the preset's normal-page support.
- `theme-classic` keeps the existing custom CSS and UI; `theme-common` is a direct dependency for its configuration types.
- `plugin-sitemap` loads only for `NODE_ENV=production`; `plugin-debug` loads otherwise, matching the former preset's defaults.
- Blog, search, analytics, SVG-component conversion and CSS-cascade-layer plugins are not registered. The blog package remains a theme dependency, not an enabled blog.

Keep these packages pinned to the same version as core. Future search, analytics, SVG-component imports or CSS-cascade features require explicit plugin/dependency setup and a new security review; changing a theme or future flag alone no longer enables a preset plugin. Ambient TypeScript SVG declarations remain, so a passing typecheck does not establish support for importing SVG files as React components.

`npm test` covers the explicit dependencies, absence of the removed dependency path, production/development plugin selection and stable locale/URL configuration. Builds and browser checks are still required for actual rendering behavior.

## Local development

```bash
npm start -- --locale en --host 127.0.0.1 --no-open
```

Stop that server before starting the Japanese preview:

```bash
npm start -- --locale ja --host 127.0.0.1 --no-open
```

A development server previews one locale. Use the combined production build to check locale switching and localized URLs.

## Validation

Run these steps serially:

```bash
npm test
npm run check:audit
npm run check:translations
npm run typecheck
npm run build
```

`npm run build` builds all six languages. Broken internal links, Markdown links, and anchors fail the build. External destinations, prose, translation quality, and code examples still need review.

The translation checker reads `locales.json` and verifies the eight-page manifest in every locale, matching IDs/slugs, nonempty metadata/body, and custom navbar messages. All fenced examples (Dart, YAML and Bash), including fence info strings, must match English in source order; only CRLF is normalized. Use unindented triple-backtick fences. Tests cover each locale, malformed configuration and missing/changed code. This checks structure, not translation quality. A separate test pins the six required locales so deleting one cannot silently reduce coverage.

## Preview the production build

After the build completes (Node 22):

```bash
npm run serve -- --host 127.0.0.1 --port 3000 --no-open
```

Open:

- English: `http://127.0.0.1:3000/misskey_mfm_renderer/`
- Japanese: `http://127.0.0.1:3000/misskey_mfm_renderer/ja/`
- Simplified Chinese: `http://127.0.0.1:3000/misskey_mfm_renderer/zh-Hans/`
- German: `http://127.0.0.1:3000/misskey_mfm_renderer/de/`
- French: `http://127.0.0.1:3000/misskey_mfm_renderer/fr/`
- Korean: `http://127.0.0.1:3000/misskey_mfm_renderer/ko/`

Check all eight pages in all six languages (48 routes), direct entry and refresh on deep URLs, same-page language switching, desktop and mobile navigation, keyboard focus, and light/dark mode. Long code should scroll within its block rather than widening the page.

Do not rebuild into a directory that another preview server is serving. Stop your own preview first, or copy the source to a separate directory (excluding `node_modules`, `build` and `.docusaurus`), install with `npm ci`, and build there. Use another free localhost port for the isolated preview; do not stop another session’s server.

## Maintaining the content

- English pages live in `docs/`; translated pages live in `i18n/<locale>/docusaurus-plugin-content-docs/current/`. Use English as the source and preserve every limitation and the published/development distinction.
- `locales.json` is shared by the site configuration and checker. Keep native language labels there. Bundled Docusaurus theme translations provide standard UI messages; translate custom navbar messages in each locale’s `docusaurus-theme-classic/navbar.json`.
- Keep matching file names, stable `id` and `slug`, and localized `title`/`sidebar_label`. The checker intentionally expects simple, unquoted scalar front matter, not arbitrary YAML constructs.
- Use relative Markdown links between documents so Docusaurus resolves the current language and base URL.
- Keep custom navbar labels in `i18n/<locale>/docusaurus-theme-classic/navbar.json` synchronized with `docusaurus.config.ts` and the checker.
- When adding a page in a later change, update all six languages, `sidebars.ts`, and the small manifest in `scripts/check-translations.mjs` together.
- Keep every fenced example identical and in the same order across all languages, including comments, sample strings, commands and versions. Localize prose, headings and link labels, not identifiers or link destinations. Validate the actual snippet against the documented published dependency, not only a local path dependency.
- Register every locale’s getting-started page in `../tool/src/release_config.dart`. Preserve `misskey_mfm_renderer: ^<version>` in the YAML example. `test/tool/docs_locale_release_config_test.dart` checks locale/reference coverage; the existing release tests verify the referenced files.
- The example app uses development source and can include unreleased features. Do not present those as already available in the published package.

The existing repository CI validates pull requests without publishing them. After the required administrator setup, a successful canonical-repository `develop` push can deploy the complete six-language build through a separate, narrowly privileged job. The existing CI gate and a current-SHA check must pass; an old run can be skipped without publishing. See [deployment](deployment.md) for exact conditions, concurrency limits and recovery. Do not use `main` or package-release automation to deploy docs.

## Screenshot maintenance

The example page uses unmodified Android captures of the development example, not published-package visual guarantees. See [capture provenance](screenshots.md). Keep every locale’s alt text and captions explicit about Android, development source, offline synthetic data and Japanese UI. Preserve the original PNGs, record hashes and capture settings, and inspect images for personal data before adding them. Use standard `/img/...` Markdown assets so Docusaurus handles the base URL. Check image loading and overflow at desktop, 390px and 320px widths in both themes.

Adding/changing static paths, copy transforms or glob settings changes the security review boundary; reassess [dependency-security.md](dependency-security.md) without automatically extending the audit exception. Published-package Dart examples require isolated analyze/widget tests under Flutter 3.38.1 and the repository SDK, not just a development path-dependency build.
