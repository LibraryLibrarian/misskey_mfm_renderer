import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {mkdtempSync, mkdirSync, rmSync, writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import test from 'node:test';
import {checkAudit, validateAudit} from './check-audit.mjs';

const advisory = 'GHSA-vfj7-8cjw-p6xm';
const now = Date.parse('2026-10-19T00:00:00.000Z');
const expiresAt = '2026-11-18T00:00:00.000Z';
const counts = (high) => ({info: 0, low: 0, moderate: 0, high, critical: 0, total: high});
const hash = (text) => createHash('sha256').update(text).digest('hex');

function fixture() {
  const lockText = JSON.stringify({lockfileVersion: 3, packages: {
    'node_modules/braces': {version: '3.0.3'},
    'node_modules/parent': {version: '1.0.0'},
  }});
  return {
    now,
    lockText,
    readVersion: (node) => node === 'node_modules/braces' ? '3.0.3' : '1.0.0',
    policy: {version: 1, lockSha256: hash(lockText), exceptions: [{
      package: 'braces', advisory, version: '3.0.3', severity: 'high', nodes: ['node_modules/braces'],
      expiresAt, reason: 'Fixture: fixed, repository-controlled glob patterns only.',
    }]},
    report: {
      auditReportVersion: 2,
      metadata: {vulnerabilities: counts(2)},
      vulnerabilities: {
        braces: {name: 'braces', severity: 'high', nodes: ['node_modules/braces'], via: [{
          name: 'braces', dependency: 'braces', severity: 'high', range: '<=3.0.3',
          url: `https://github.com/advisories/${advisory}`,
        }]},
        parent: {name: 'parent', severity: 'high', nodes: ['node_modules/parent'], via: ['braces']},
      },
    },
  };
}

function diskFixture(t, input) {
  const root = mkdtempSync(join(tmpdir(), 'mfm-docs-audit-'));
  t.after(() => rmSync(root, {recursive: true, force: true}));
  writeFileSync(join(root, 'package-lock.json'), input.lockText);
  writeFileSync(join(root, 'audit-exceptions.json'), JSON.stringify(input.policy));
  for (const [node, entry] of Object.entries(JSON.parse(input.lockText).packages)) {
    mkdirSync(join(root, node), {recursive: true});
    writeFileSync(join(root, node, 'package.json'), JSON.stringify(entry));
  }
  return root;
}

test('accepts an exact temporary exception and its transitive parents', () => {
  const result = validateAudit(fixture());
  assert.equal(result.counts.total, 2);
  assert.equal(result.exceptions.length, 1);
  assert.equal(result.exceptions[0].severity, 'high');
});

test('accepts zero findings without exceptions', () => {
  const input = fixture();
  input.report.vulnerabilities = {};
  input.report.metadata.vulnerabilities = counts(0);
  input.policy = {version: 1, exceptions: []};
  assert.equal(validateAudit(input).counts.total, 0);
});

test('rejects low-severity findings without exceptions', () => {
  const input = fixture();
  input.policy = {version: 1, exceptions: []};
  input.report.metadata.vulnerabilities = {...counts(0), low: 2, total: 2};
  input.report.vulnerabilities.braces.severity = 'low';
  input.report.vulnerabilities.braces.via[0].severity = 'low';
  input.report.vulnerabilities.parent.severity = 'low';
  assert.throws(() => validateAudit(input), /Unreviewed advisory: braces .* \(low\)/);
});

test('permits reference cycles only when every entry reaches a reviewed origin', () => {
  const input = fixture();
  input.report.vulnerabilities.braces.via.push('parent');
  assert.equal(validateAudit(input).exceptions.length, 1);
});

test('uses the maximum severity across multiple reviewed origins', () => {
  const input = fixture();
  const lowAdvisory = 'GHSA-aaaa-bbbb-cccc';
  input.policy.exceptions.push({
    ...input.policy.exceptions[0], package: 'parent', advisory: lowAdvisory,
    version: '1.0.0', severity: 'low', nodes: ['node_modules/parent'],
  });
  input.report.vulnerabilities.parent.via.push({
    name: 'parent', dependency: 'parent', severity: 'low', range: '<=1.0.0',
    url: `https://github.com/advisories/${lowAdvisory}`,
  });
  assert.equal(validateAudit(input).exceptions.length, 2);
});

for (const name of ['parent', 'braces']) {
  for (const severity of ['low', 'critical']) {
    test(`rejects ${name} entry severity ${severity} inconsistent with High origins`, () => {
      const input = fixture();
      input.report.vulnerabilities[name].severity = severity;
      input.report.metadata.vulnerabilities = {...counts(1), [severity]: 1, total: 2};
      assert.throws(() => validateAudit(input), /severity differs from advisory origins/);
    });
  }
}

test('accepts the last millisecond before expiry', () => {
  const input = fixture();
  input.now = Date.parse(expiresAt) - 1;
  assert.doesNotThrow(() => validateAudit(input));
});

for (const [name, change, error] of [
  ['new advisory', (i) => {i.report.vulnerabilities.braces.via[0].url = 'https://github.com/advisories/GHSA-aaaa-bbbb-cccc';}, /Unreviewed advisory/],
  ['new low severity advisory', (i) => {i.report.vulnerabilities.braces.via.push({...i.report.vulnerabilities.braces.via[0], severity: 'low', url: 'https://github.com/advisories/GHSA-aaaa-bbbb-cccc'});}, /Unreviewed advisory/],
  ['no exception', (i) => {i.policy.exceptions = [];}, /Unreviewed advisory/],
  ['missing exception severity', (i) => {delete i.policy.exceptions[0].severity;}, /Invalid exception severity/],
  ['changed advisory severity', (i) => {i.report.vulnerabilities.braces.via[0].severity = 'critical';}, /advisory severity changed/],
  ['changed lockfile', (i) => {i.lockText += '\n';}, /Lockfile changed/],
  ['changed reviewed version', (i) => {i.policy.exceptions[0].version = '3.0.2';}, /affected version changed/],
  ['changed installed version', (i) => {i.readVersion = () => '0.0.0';}, /installed version differs/],
  ['changed affected paths', (i) => {i.policy.exceptions[0].nodes = ['node_modules/other/node_modules/braces'];}, /affected paths changed/],
  ['traversal in audit path', (i) => {i.report.vulnerabilities.braces.nodes = ['node_modules/../../node_modules/braces'];}, /invalid audit node/],
  ['backslash in audit path', (i) => {i.report.vulnerabilities.braces.nodes = ['node_modules/..\\..\\node_modules/braces'];}, /invalid audit node/],
  ['duplicate node', (i) => {i.report.vulnerabilities.braces.nodes.push('node_modules/braces');}, /duplicate audit nodes/],
  ['expiry boundary', (i) => {i.now = Date.parse(expiresAt);}, /expired/],
  ['after expiry', (i) => {i.now = Date.parse(expiresAt) + 1;}, /expired/],
  ['noncanonical expiry', (i) => {i.policy.exceptions[0].expiresAt = '2026-11-18';}, /Invalid exception expiry/],
  ['bad clock', (i) => {i.now = NaN;}, /Invalid audit clock/],
  ['missing reason', (i) => {delete i.policy.exceptions[0].reason;}, /rationale/],
  ['missing exception package', (i) => {delete i.policy.exceptions[0].package;}, /Invalid exception package/],
  ['duplicate exception', (i) => {i.policy.exceptions.push({...i.policy.exceptions[0]});}, /duplicate exception/],
  ['unused exception', (i) => {i.report.vulnerabilities = {}; i.report.metadata.vulnerabilities = counts(0);}, /unused exception/],
  ['unknown report version', (i) => {i.report.auditReportVersion = 3;}, /Unsupported/],
  ['registry error JSON', (i) => {i.report.error = {code: 'ENOAUDIT'};}, /failed npm audit/],
  ['missing counts', (i) => {delete i.report.metadata;}, /Missing audit counts/],
  ['inconsistent total', (i) => {i.report.metadata.vulnerabilities.total = 0;}, /count does not match/],
  ['inconsistent severity', (i) => {i.report.metadata.vulnerabilities.low = 1; i.report.metadata.vulnerabilities.high = 1;}, /severity count mismatch/],
  ['invalid severity', (i) => {i.report.vulnerabilities.braces.severity = 'unknown';}, /unknown severity/],
  ['empty via', (i) => {i.report.vulnerabilities.parent.via = [];}, /missing advisory origins/],
  ['missing reference', (i) => {i.report.vulnerabilities.parent.via = ['absent'];}, /unresolved advisory reference/],
  ['rootless cycle', (i) => {i.report.vulnerabilities.parent.via = ['parent'];}, /no advisory origin/],
  ['advisory attached to wrong package', (i) => {i.report.vulnerabilities.braces.via[0].dependency = 'other';}, /invalid advisory/],
  ['unsupported advisory URL', (i) => {i.report.vulnerabilities.braces.via[0].url = 'https://example.com/advisory';}, /unsupported advisory URL/],
]) {
  test(`rejects ${name}`, () => {
    const input = fixture();
    change(input);
    assert.throws(() => validateAudit(input), error);
  });
}

test('runs a full npm audit and interprets findings exit code separately', (t) => {
  const input = fixture();
  const root = diskFixture(t, input);
  const result = checkAudit(root, {now, run: (command, args, options) => {
    assert.equal(command, 'npm');
    assert.deepEqual(args, ['audit', '--json', '--include=dev', '--include=optional', '--include=peer', '--audit-level=low']);
    assert.equal(options.cwd, root);
    assert.equal(options.timeout, 120_000);
    return {status: 1, stdout: JSON.stringify(input.report)};
  }});
  assert.equal(result.exceptions[0].advisory, advisory);
});

for (const [name, processResult, error] of [
  ['network failure', {status: 1, stdout: '{"error":{"code":"ENOTFOUND"}}'}, /failed npm audit/],
  ['non-JSON output', {status: 1, stdout: 'network error'}, /valid JSON/],
  ['empty output', {status: 0, stdout: ''}, /valid JSON/],
  ['unexpected exit code', {status: 2, stdout: '{}'}, /npm audit failed/],
  ['termination signal', {status: null, signal: 'SIGTERM'}, /npm audit failed/],
  ['timeout', {status: null, error: new Error('ETIMEDOUT')}, /ETIMEDOUT/],
]) {
  test(`fails closed on ${name}`, (t) => {
    const root = diskFixture(t, fixture());
    assert.throws(() => checkAudit(root, {now, run: () => processResult}), error);
  });
}

test('rejects nonzero audit exit with an otherwise empty successful report', (t) => {
  const input = fixture();
  input.report.vulnerabilities = {};
  input.report.metadata.vulnerabilities = counts(0);
  input.policy.exceptions = [];
  const root = diskFixture(t, input);
  assert.throws(() => checkAudit(root, {now, run: () => ({status: 1, stdout: JSON.stringify(input.report)})}), /failed without reporting/);
});
