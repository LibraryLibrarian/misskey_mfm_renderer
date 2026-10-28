# Documentation deployment

## Publication target and scope

The target is <https://librarylibrarian.github.io/misskey_mfm_renderer/>. English
uses that root; Japanese, Simplified Chinese, German, French and Korean use
`ja/`, `zh-Hans/`, `de/`, `fr/` and `ko/`. Each language has eight pages. The complete
Docusaurus build must be deployed together, retaining the project base path and
trailing slashes.

Adding this workflow does not itself enable Pages or prove that the site is live.
Implementation, local validation, commit/push/PR creation, repository settings
and actual publication are separate stages. Obtain explicit publication approval
before enabling Pages and merging the publication change. Do not treat an
implementation or PR-creation request as permission to change settings or merge.

This is independent of package releases. Do not use `main`, version tags,
`Prepare Release`, pub.dev publishing or the release GitHub App credentials to
publish documentation. Root README and metadata changes only reach pub.dev on a
subsequent normal package release; merging a docs PR does not update the
currently published package page.

## First publication checklist

After local validation and independent review:

1. Create the feature-branch PR against `develop` only when requested. Inspect
   its CI results; the PR must validate but must not deploy.
2. After publication approval, a repository administrator selects **Settings →
   Pages → Build and deployment → Source → GitHub Actions**. Reuse the CI workflow;
   do not commit a generated template or select a branch-based publishing source.
3. In **Settings → Environments**, create/configure **github-pages** and restrict
   deployment branches/tags to the **branch `develop` only**, not all protected
   branches, a wildcard or a tag rule. Leave the existing `pub.dev` environment
   unchanged. The default operation is automatic deployment after the CI gate;
   no additional required reviewer is assumed. If administrators add reviewers,
   their approval becomes an additional prerequisite, not a check to bypass.
4. Verify the PR checks, publishing source and environment restriction before
   the user merges the PR to `develop`. That push starts the first candidate
   deployment. No CLI merge or manual workflow dispatch is part of this procedure.
5. Wait for **Deploy Docs → Deploy Pages** to succeed, then perform the public
   checks below. Do not call a skipped deployment a publication success.

Until the first successful deployment, the site can return 404. The root READMEs
retain links to GitHub guide sources and the published API reference as fallbacks.

## CI and permissions

The existing `.github/workflows/ci.yml` performs:

1. **Docs (6 locales):** checkout without persisted credentials, Node 22,
   `npm ci`, tests, audit policy, translations, typecheck and full build.
2. On a `push` to `refs/heads/develop` in
   `LibraryLibrarian/misskey_mfm_renderer` only,
   `actions/upload-pages-artifact@v4` uploads **`docs/build`**, not source files,
   dependencies, evidence or a single-language subset. The default artifact
   name is `github-pages`. `defaults.run.working-directory` does not apply to
   this `uses` step, hence the repository-relative upload path.
3. **Deploy Docs** requires successful `docs` and `gate` jobs and repeats the
   canonical-repository/event/ref restriction. It uses the same workflow run's
   artifact through `actions/deploy-pages@v4` and reports the action's `page_url`
   as the environment URL.

The existing gate depends on `quality`, `example`, `golden` and `docs`. It rejects
failures/cancellations and requires docs success, while allowing other dependent
jobs to be skipped. **API diff is not a gate dependency.** This change does not
claim to strengthen those existing semantics.

Workflow-default permissions remain `contents: read`. Only the deployment job
has `pages: write`, `id-token: write`, and explicit `contents: read` for the SHA
lookup. It does not check out source, install npm packages, build MDX, or execute
repository scripts. It uses the built-in GitHub token, with no PAT, release App
secret or new user-managed credential. Pages is not automatically enabled.

PRs, forks, `main` and tags cannot take this deployment path. There is no
`pull_request_target`, privileged cross-workflow artifact ingestion, public PR
preview, manual dispatch or `gh-pages` branch. Future workflow edits still
require review: the conditions in a reviewed workflow are not a substitute for
branch governance and the environment's independent branch restriction.

## Concurrency and stale candidates

The existing workflow concurrency group remains per workflow/ref. For canonical
`develop` pushes, `cancel-in-progress` is false so a later push does not cancel an
active deployment. This also serializes those CI runs. Other events retain
cancellation of older runs. The deployment job additionally uses the shared
`pages` concurrency group without cancelling in-progress deployments.

GitHub concurrency is **not FIFO** and pending runs can be replaced. Not every
commit is guaranteed to build or deploy in order. A delay or cancelled pending
run must not be reported as a successful deployment.

After obtaining the deployment job's execution slot, immediately before deploy,
a read-only GitHub API lookup compares the current `develop` SHA to the run's
`github.sha`:

- Equal: eligible for the deployment action, not yet proof of publication.
- Different: skip deployment and record the reason in the job summary.
- API error or invalid SHA response: fail closed, without deploying.

This prevents a run already known to be stale from replacing the site, including
old run re-executions. The lookup and deployment are not atomic: a push can arrive
between them. Combined with pending-run replacement, this is **not** a guarantee
that the latest commit is always published. Check the actual deployment SHA.

## Verification and recovery

Before publication, follow [local validation](README.md#validation), test the
workflow conditions/permissions and README links separately, and preserve the
existing release-reference tests for both READMEs plus six getting-started pages.
A local static server cannot verify real Pages settings, OIDC, artifact transfer
or GitHub job scheduling; those remain first-publication checks.

After a successful deployment, record the run, deployment SHA and public URL,
then check:

- All 48 page URLs, including direct entry and reload on deep paths.
- JS, CSS and both example PNGs under `/misskey_mfm_renderer/`, with no new 404s.
- All five nondefault locale prefixes, same-page language switching, desktop and
  mobile navigation, `html lang`, canonical and alternate URLs.
- HTTPS and a genuinely missing URL returning 404. GitHub Pages does not select
  a different localized 404 per URL prefix; the English 404 is acceptable, but
  a missing guide is not.

A build, audit or gate failure prevents deployment. A first publication failure
leaves the site unavailable; if a successful deployment already exists, a failed
update does not intentionally replace it. Inspect actual Pages status rather
than claiming publication from the overall CI status or a deployment candidate
message.

Recover through a reviewed feature-branch PR against `develop` that fixes or
restores document content **while retaining the working publication workflow**.
Removing the workflow in a revert does not roll back already published content.
Do not use an old run rerun, `main`, release automation or manual dispatch as the
standard rollback. Disabling publication, unpublishing the site or changing
repository settings requires separate administrator approval.

The [current dependency review](dependency-security.md#current-dependency-reassessment-2026-10-28)
records an **unresolved** Low `deepmerge` advisory, with no exception. The audit
gate therefore still blocks publication despite the other dependency fixes.
The old `braces` advisory was withdrawn upstream and its unused exception removed,
not extended. Do not add or renew exceptions merely to get a deployment through.

## References

- [GitHub Pages custom workflows](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)
- [Configuring the publishing source](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)
