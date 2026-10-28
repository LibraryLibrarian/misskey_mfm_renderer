# Documentation dependency security review

Initial review on **2026-10-19**, for the Node 22 / Docusaurus 3.10.2 English/Japanese site, with subsequent dated reassessments below. This is an assessment of the documentation toolchain, not a security certification of the Flutter library or every possible Docusaurus configuration.

## Current dependency reassessment (2026-10-28)

A fresh audit including dev, optional and peer dependencies found **23 affected package entries** (1 High, 1 Moderate, 21 Low), from **7 advisories in 4 packages**, in the previously reviewed lockfile. Fixing only the first CI error, `body-parser`, would not restore the audit gate.

| Dependency update | Advisories removed from the resolved tree |
|---|---|
| `body-parser` **1.20.8 → 1.20.9** | High: [GHSA-27r3-jxmh-p828](https://github.com/advisories/GHSA-27r3-jxmh-p828), unhandled errors from trailing bytes after a compressed request body. |
| `fast-uri` **3.1.8 → 3.1.9** | Moderate/Low: [scheme decoding](https://github.com/advisories/GHSA-w74x-v6f9-j3xg), [relative-path equivalence](https://github.com/advisories/GHSA-xhq7-xmqj-769h), [host canonicalization](https://github.com/advisories/GHSA-wjr9-j795-jxcr), and [suffix-reference scheme injection](https://github.com/advisories/GHSA-333x-w4r6-6crp). |
| `serialize-javascript` **7.1.2 → 7.1.3** | Low: [GHSA-m5mm-p8h7-m29v](https://github.com/advisories/GHSA-m5mm-p8h7-m29v), an unescaped script-closing sequence at the end of a serialized function body. |

These are patch updates, not a framework or plugin-stack upgrade. `fast-uri` remains within Ajv's `^3.0.1` requirement. The two existing parent-scoped `serialize-javascript` overrides move to 7.1.3; their cross-major compatibility obligation described in the original review still applies.

`body-parser` is installed through `@docusaurus/core → webpack-dev-server → express`. Express 4.22.3's `~1.20.5` range permits 1.20.9, but npm 10.9.2's named update retained 1.20.8, including with refreshed registry metadata. An override scoped to **Express → body-parser 1.20.9** makes the intended resolution explicit. Reassess/remove this pin when updating Express; do not carry it into an incompatible parent range. The lockfile was generated with npm's targeted update and `npm install --package-lock-only --ignore-scripts`, not edited by hand. Only these three package entries change, each in version, registry URL and integrity; all parent dependency edges and the other installed versions remain unchanged.

### Remaining blocker: deepmerge

[GHSA-gcqx-w48m-w2h4](https://github.com/advisories/GHSA-gcqx-w48m-w2h4) reports Low-severity prototype poisoning of returned objects in **deepmerge 4.3.1**. The installed path is `@docusaurus/preset-classic → @docusaurus/plugin-svgr → @svgr/webpack → @svgr/plugin-svgo → deepmerge`. As of this review, the registry's latest deepmerge is still 4.3.1, the advisory lists no patched version, and the latest `@svgr/plugin-svgo` (8.1.0) still requires `deepmerge ^4.3.1`.

The updated audit reports **5 Low affected package entries**, all propagating from this one advisory, and no High, Moderate or Critical findings. **This finding is unresolved and has no exception. Both raw `npm audit` and `npm run check:audit` remain failing.** Do not merge or publish on the basis of the other checks passing. Removing this path requires a separately reviewed dependency/configuration change, or an upstream fixed release; merely disabling a plugin does not remove installed packages from the audit. The checker, severity policy and CI publication gate are unchanged.

### Removed historical braces exception

GitHub [withdrew GHSA-vfj7-8cjw-p6xm](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm) on **2026-10-23 at 12:53:02 UTC**, stating that it is not a practically exploitable vulnerability. The fresh npm audit no longer reports it. This is an advisory withdrawal, **not a package fix**: `braces` remains at 3.0.3.

The now-unused braces exception and its lock hash are removed; `audit-exceptions.json` contains an empty exception list. No expiry is extended, no replacement exception is added, and no lock hash is renewed to bypass review. The historical assessment and original expiry below are retained as a record, not as a current allowance. Static roots, glob inputs, plugins and deployment trust boundaries are unchanged.

### Local validation of the patch updates

Under Node 22.15.0 / npm 10.9.2, an isolated site copy passed `npm ci`, **347 tests**, translation checks, typechecking and the production build of all **six locales / 48 routes**. The test suite also verifies an empty exception policy without a lock hash and rejection of Low-severity findings. The full raw audit and policy check both returned **exit 1** for deepmerge; running the other checks locally does not bypass that CI failure.

Targeted, bounded compatibility fixtures passed for Express JSON (uncompressed, gzip and deflate), form/text bodies, Ajv relative-URI/fragment schema references, both parents' resolution of serialize-javascript 7.1.3, uncached parallel CSS minimization, and copy-plugin transform-cache/transformAll. No exploit or resource-exhaustion payload was used. Optional pooled SSG, SockJS and browser interaction checks were not repeated; their dependencies and site configuration are unchanged. No Pages deployment, public-URL verification or native build was performed.

## Initial review result and limits (2026-10-19)

The original lockfile reported **49 affected package entries**, arising from **8 advisories in 6 underlying packages**. The updated lockfile reports **28 High entries, all propagating from one remaining advisory in `braces@3.0.3`**. It reports no Critical or Moderate entries. The increase in the High subtotal is reclassification of dependency ancestors that previously had higher-severity findings, not 28 new independent vulnerabilities.

Seven originating advisories have been removed from the resolved dependency tree by updating the affected packages or removing their dependency path. **The braces vulnerability is not fixed.** Its narrowly scoped, temporary exception is described below; a successful policy check is not a clean `npm audit` result. Raw `npm audit` still exits nonzero.

These dependencies run on developer machines and CI. A static deployment does not run the Node build toolchain for each visitor, but that alone does not make build dependencies safe. MDX, configuration, plugins, and npm scripts are executable code. Do not build an unreviewed pull request on a privileged local machine on the assumption that this review makes its source trustworthy. The docs build job uses a hosted runner, read-only repository permissions, no deployment credentials, and checkout without persisted credentials. The later PR4 deployment boundary is described separately below.

## Advisory-by-advisory assessment

| Advisory | Previous dependency | Conditions and observed use | Action |
|---|---|---|---|
| [GHSA-5gmw-xhrv-c9v3](https://github.com/advisories/GHSA-5gmw-xhrv-c9v3) — Critical | tinypool 1.1.1 | Requires an independent prototype-pollution source and inherited worker options at worker creation. Docusaurus's pooled SSG is off by default in this site. | Scoped override under `@docusaurus/core` to **2.2.0**; both Tinypool advisories are fixed from 2.1.2 onward. |
| [GHSA-85c8-ppgw-ccpr](https://github.com/advisories/GHSA-85c8-ppgw-ccpr) — Critical | tinypool 1.1.1 | Requires prior prototype pollution and a supplied `run()` options object inheriting a module filename. Docusaurus calls `pool.run(task)` without that second argument, and the site does not enable the pool. This is an exposure observation, not a reason to retain the vulnerable version. | Same **2.2.0** override. |
| [GHSA-5c6j-r48x-rmvq](https://github.com/advisories/GHSA-5c6j-r48x-rmvq) — High | serialize-javascript 6.0.2 | Attacker-influenced RegExp/Date serialization followed by execution of the emitted JavaScript. The production CSS minimizer really does serialize and evaluate worker options, including implementation functions. Its current inputs are bundled CSS and build configuration, not visitor requests. | Scoped overrides under the two consuming webpack plugins to **7.1.2**. |
| [GHSA-qj8w-gfj5-8c6v](https://github.com/advisories/GHSA-qj8w-gfj5-8c6v) — Moderate | serialize-javascript 6.0.2 | Crafted array-like/prototype-influenced objects can cause excessive iteration. Ordinary CSS text is not itself that object shape. Copy-plugin serialization is gated by transform/cache or transformAll, which the current site does not configure. | Same **7.1.2** overrides; both advisories are fixed from 7.0.5 onward. |
| [GHSA-rj75-hqrm-r3gf](https://github.com/advisories/GHSA-rj75-hqrm-r3gf) — Moderate | postcss-selector-parser 6.1.4 | Expensive parsing of attacker-controlled flat selectors. The old copy was used by cssnano during production builds of repository/theme CSS. Other dependency paths already had 7.1.6. | Override the six affected parent packages to **7.1.6**. All installed copies now resolve to that version. |
| [GHSA-hp3w-g68c-fv3c](https://github.com/advisories/GHSA-hp3w-g68c-fv3c) — Moderate | sprintf-js 1.0.3 | Requires control over the format string, not merely formatted values. The dependency was only in `gray-matter → js-yaml 3 → argparse 1`, for the YAML CLI; ordinary front-matter parsing did not invoke it. No patched sprintf-js release was available. | **Removed the dependency path**, using Docusaurus 3.10.2's `@11ty/gray-matter@1.0.0` / js-yaml 4 instead. No standalone YAML-major override. |
| [GHSA-w5hq-g745-h8pq](https://github.com/advisories/GHSA-w5hq-g745-h8pq) — Moderate | uuid 8.3.2 | Affects v3/v5/v6 with a supplied output buffer. SockJS uses argument-free v4, not those APIs; the site's development server defaults to `ws`, not SockJS. | Scoped override under `sockjs` to **11.1.1**, which retains CommonJS compatibility. |
| [GHSA-vfj7-8cjw-p6xm](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm) — High | braces 3.0.3 | Deeply nested brace patterns can exhaust the stack during compilation/expansion. The reviewed paths process repository-controlled glob patterns, not document bodies or visitor input. No patched release was available. | **Still vulnerable.** One exact-version, lock-bound exception, expiring **2026-11-18 00:00:00 UTC**. |

## Why the overrides are limited

All five direct `@docusaurus/*` dependencies use exactly 3.10.2. The old Webpack 5.105.4 compatibility override is removed: this lockfile uses Webpack 5.112.0 with webpackbar 7.0.0 and builds both locales successfully.

Upgrading Docusaurus alone still leaves vulnerable transitive requirements. The overrides change only the relevant children, rather than upgrading the entire copy/CSS plugin stack or replacing the documentation framework:

- `@docusaurus/core → tinypool@2.2.0`.
- `copy-webpack-plugin` and `css-minimizer-webpack-plugin → serialize-javascript@7.1.2`.
- `postcss-calc`, `postcss-discard-unused`, `postcss-merge-rules`, `postcss-minify-selectors`, `postcss-unique-selectors`, and `stylehacks → postcss-selector-parser@7.1.6`.
- `sockjs → uuid@11.1.1`.

These overrides cross the parents' declared major ranges. They are local compatibility decisions, not claims of upstream support. Tinypool's internal worker-data tuple and worker ID are also used by Docusaurus. A default build alone does not exercise that optional path. Reassess/remove overrides when upstream adopts compatible fixed dependencies; do not keep overriding newer upstream dependencies blindly.

A first version-range-only selector override left an old hoisted 6.1.4 copy in the generated lockfile. The final parent-scoped overrides were checked against the actual installed versions and a fresh audit, not just the manifest. Lockfiles are generated by npm, never hand-edited to claim a fix.

## Historical braces exception (removed 2026-10-28)

The former `audit-exceptions.json` bound the exception to:

- package **braces**, version **3.0.3**;
- advisory **GHSA-vfj7-8cjw-p6xm**, reviewed severity **High**, only;
- the complete affected-node set: **`node_modules/braces`**;
- the SHA-256 of the reviewed `package-lock.json`, including the parent dependency graph;
- expiry **2026-11-18T00:00:00.000Z** (the exact instant at which the check starts failing).

Reviewed paths in this dependency graph:

| Path | Input boundary |
|---|---|
| Docusaurus docs/pages → globby → fast-glob → micromatch → braces | Default include patterns such as `**/*.{md,mdx}` and `**/*.{js,jsx,ts,tsx,md,mdx}`, relative to configured repository directories. File bodies are not glob patterns. |
| Docusaurus development watcher → chokidar → braces | Repository config/content paths and the same fixed plugin patterns. |
| webpack-dev-server → chokidar | Configured static directory is a plain repository path. No additional watchFiles configuration. No brace expansion for the current plain path. |
| Docusaurus static-copy plugin → globby/fast-glob | Active for the two reviewed PNGs in `docs/static/img/`. Docusaurus passes the repository static directory as `from`; copy-webpack-plugin detects a directory, escapes its absolute path with `fastGlob.escapePath`, and appends fixed `**/*`. No visitor/Markdown-body input becomes a glob. No transform, transformAll or transform-cache options are configured. |
| webpack-dev-server → http-proxy-middleware → micromatch | No proxy configured. There is no public glob-processing endpoint in the site. |

PR2 static-asset reassessment (2026-10-20): inspected Docusaurus 3.10.2 `StaticDirectoriesCopyPlugin.js` and copy-webpack-plugin’s directory branch in the unchanged installed dependency tree. The new inputs are repository-controlled, unmodified PNGs with provenance in [screenshots.md](screenshots.md). Image bytes are copied, not evaluated as glob expressions. This activates the ordinary copy path, not the optional serialization fixtures described below. The dependency versions, lock hash, exception scope and expiry are unchanged; **braces remains unfixed**. New static roots, transforms or configurable glob inputs require another review.

The threat boundary is reviewed source/configuration and installed dependencies, **not all pull requests being trusted**. An attacker able to supply arbitrary build scripts or configuration can already execute code in that build. This exception does not make that execution safe. Future plugins, user-provided glob strings, unusual repository path names, a public preview server, or a different trust boundary require a new assessment.

Do not extend the expiry automatically or add another exception merely to make CI pass. Check for an upstream fix first. If the remaining risk cannot be accepted, keep the change unmerged rather than describing it as fixed.

## PR4 publication boundary reassessment (2026-10-20)

The six-language build reuses the reviewed dependency tree, static roots, copy
settings and glob inputs. Deployment changes the trust boundary, not the audit
exception: **braces remains unfixed**, with the same version, lock hash, scope
and expiry. No visitor request executes the Node toolchain, but reviewed build
inputs and dependencies can still execute code on the build runner.

- The `docs` job retains `contents: read`, no deployment permissions and checkout
  without persisted credentials. npm scripts, MDX and plugins run only there.
- Only canonical-repository `push` runs on `refs/heads/develop` upload the built
  `docs/build` directory. PR and fork builds do not publish artifacts for Pages.
- A separate deployment job requires successful docs and the existing CI gate.
  Only that job has `pages: write` / `id-token: write`, plus `contents: read` for
  a current-develop-SHA check. It has no checkout, npm installation, MDX build or
  repository-script execution; it deploys the same run's static artifact.
- The independent `github-pages` environment must restrict deployment to the
  `develop` branch. Settings activation requires separate approval. No PAT,
  release App credentials, automatic Pages enablement, privileged PR workflow or
  cross-workflow artifact download is introduced.
- Stale SHA candidates are skipped, API failures stop deployment, and active
  deployments are not intentionally cancelled by a newer push. This does not
  make SHA lookup/deployment atomic or guarantee FIFO/latest-run publication.

The artifact contains HTML/JavaScript served to visitors. Separating permissions
reduces build-token exposure; it does **not** establish the safety of arbitrary
content emitted by a compromised dependency or an unreviewed change. Source,
workflow and dependency review remain necessary. There are no new public preview
servers, static roots, copy transforms or visitor-controlled glob inputs.
See [deployment](deployment.md) for conditions, actual-publication checks and
recovery. This assessment is not evidence that GitHub Pages has been enabled or
that a deployment has succeeded.

## Audit gate and maintenance

After `npm ci`, run:

```bash
npm test
npm run check:audit
npm run check:translations
npm run typecheck
npm run build
```

The audit gate includes dev, optional, and peer dependencies. It resolves npm's inherited `via` entries back to originating advisories. Unknown advisories of **any severity**, changed affected versions/paths, a changed lockfile, expired or unused exceptions, malformed/unsupported reports, and registry/process failures all fail the check. It also checks installed versions against the lockfile. A permitted finding is printed as **UNFIXED**, not suppressed.

Changes to dependency inputs must be reviewed in addition to this mechanical gate. The gate does not infer the meaning of new source/configuration. Updating the recorded lock hash without reassessing those paths defeats the exception's purpose.

When updating these dependencies, revalidate:

1. A clean install, complete audit, tests, typecheck, and six-language production build.
2. Actual pooled SSG with at least two workers in a disposable site copy; keep the main site's default config unchanged.
3. Uncached CSS worker serialization and representative selector behavior, plus copy-plugin transform-cache/transformAll paths in small fixtures.
4. SockJS's resolved CommonJS UUID import and actual connection construction.
5. Desktop/mobile navigation, language switching, deep links/reload, themes, and the local-only development server.

Do not use `npm audit fix --force`, exclude development dependencies to hide findings, edit installed vendor code, or run resource-exhaustion/code-execution proofs of concept as part of routine validation.
