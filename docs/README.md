# Documentation development

This directory contains the English/Japanese Docusaurus foundation. It is not yet deployed. The canonical URL in the configuration is reserved for a future publication step; the root READMEs remain the existing entry points.

## Requirements and installation

Use Node 22 (see `.node-version`) and npm. Run the following from this directory:

```bash
npm ci
```

Commit `package-lock.json` alongside intentional dependency changes. Do not commit `node_modules`, `.docusaurus`, or `build`.

Docusaurus packages are pinned together at `3.10.2`. The lockfile uses Webpack 5.112.0 / webpackbar 7.0.0 without the former Webpack compatibility override. Scoped overrides address vulnerable build dependencies; see [the dependency security review](dependency-security.md) before changing them.

One **unfixed** braces advisory remains under an exact-version, lockfile-bound exception expiring **2026-11-18 00:00:00 UTC**. `npm run check:audit` reports it explicitly and rejects new findings, dependency changes, expired exceptions, or audit failures. A passing policy check is not a vulnerability-free audit. Do not automatically refresh the exception hash/expiry or use `npm audit fix --force`.

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

`npm run build` builds both languages. Broken internal links, Markdown links, and anchors fail the build. External destinations, prose, translation quality, and code examples still need review.

The translation checker verifies the three-page manifest, matching IDs/slugs, nonempty document metadata/body, and custom navbar translations. It is a structural check, not a translation-quality check. Its tests use disposable directories and include missing-page and invalid-label cases.

## Preview the production build

After the build completes:

```bash
npm run serve -- --host 127.0.0.1 --port 3000 --no-open
```

Open:

- English: `http://127.0.0.1:3000/misskey_mfm_renderer/`
- Japanese: `http://127.0.0.1:3000/misskey_mfm_renderer/ja/`

Check all three pages, direct entry and refresh on deep URLs, same-page language switching, desktop and mobile navigation, keyboard focus, and light/dark mode. Long code should scroll within its block rather than widening the page.

## Maintaining the content

- English pages live in `docs/`; Japanese pages live in `i18n/ja/docusaurus-plugin-content-docs/current/`.
- Keep matching file names, stable `id` and `slug`, and localized `title`/`sidebar_label`. The checker intentionally expects simple, unquoted scalar front matter, not arbitrary YAML constructs.
- Use relative Markdown links between documents so Docusaurus resolves the current language and base URL.
- Keep custom navbar labels in `i18n/ja/docusaurus-theme-classic/navbar.json` synchronized with `docusaurus.config.ts` and the checker.
- When adding a page in a later change, update both languages, `sidebars.ts`, and the small manifest in `scripts/check-translations.mjs` together.
- Keep the Dart getting-started snippet identical in both languages. Validate the actual snippet against the documented published dependency, not only a local path dependency.
- The YAML package-version examples in both getting-started pages are registered in `../tool/src/release_config.dart`. Preserve the `misskey_mfm_renderer: ^<version>` form so release tooling can update them.
- The example app uses development source and can include unreleased features. Do not present those as already available in the published package.

The existing repository CI validates this site without publishing it. Deployment configuration, screenshots, detailed guides, and further languages belong to subsequent work.
