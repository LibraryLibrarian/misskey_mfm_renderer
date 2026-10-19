import assert from 'node:assert/strict';
import {createHash} from 'node:crypto';
import {readFileSync} from 'node:fs';
import {dirname, join, resolve} from 'node:path';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const scriptPath = fileURLToPath(import.meta.url);
const siteRoot = resolve(dirname(scriptPath), '..');
const severities = ['info', 'low', 'moderate', 'high', 'critical'];
const advisoryPattern = /^https:\/\/github\.com\/advisories\/(GHSA-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4})$/;
const packagePattern = /^(?:@[a-z0-9][a-z0-9._-]*\/)?[a-z0-9][a-z0-9._-]*$/;
const isObject = (value) => value !== null && typeof value === 'object' && !Array.isArray(value);

function checkNodes(nodes, name) {
  assert(Array.isArray(nodes) && nodes.length > 0, `${name}: missing audit nodes`);
  assert.equal(new Set(nodes).size, nodes.length, `${name}: duplicate audit nodes`);
  for (const node of nodes) {
    assert(
      typeof node === 'string' && node.startsWith('node_modules/') &&
        !node.includes('\\') && node.split('/').every((part) => part && part !== '.' && part !== '..') &&
        (node === `node_modules/${name}` || node.endsWith(`/node_modules/${name}`)),
      `${name}: invalid audit node`,
    );
  }
}

export function validateAudit({report, policy, lockText, readVersion, now = Date.now()}) {
  assert(isObject(report) && !report.error && report.auditReportVersion === 2, 'Unsupported or failed npm audit report');
  assert(isObject(report.vulnerabilities), 'Missing vulnerability map');
  const counts = report.metadata?.vulnerabilities;
  assert(isObject(counts), 'Missing audit counts');
  for (const key of [...severities, 'total']) {
    assert(Number.isSafeInteger(counts[key]) && counts[key] >= 0, `Invalid audit count: ${key}`);
  }
  const entries = Object.entries(report.vulnerabilities);
  assert.equal(counts.total, entries.length, 'Audit count does not match entries');
  assert.equal(severities.reduce((sum, key) => sum + counts[key], 0), counts.total, 'Inconsistent audit counts');
  assert(Number.isFinite(now), 'Invalid audit clock');

  const lock = JSON.parse(lockText);
  assert(lock.lockfileVersion === 3 && isObject(lock.packages), 'Expected npm lockfile v3');
  assert(isObject(policy) && policy.version === 1 && Array.isArray(policy.exceptions), 'Invalid audit exception policy');
  if (policy.exceptions.length > 0) {
    const hash = createHash('sha256').update(lockText).digest('hex');
    assert.equal(policy.lockSha256, hash, 'Lockfile changed: reassess the dependency paths before renewing exceptions');
  }
  const exceptions = new Map();
  for (const exception of policy.exceptions) {
    assert(isObject(exception) && typeof exception.package === 'string' && packagePattern.test(exception.package), 'Invalid exception package');
    assert(/^GHSA-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}$/.test(exception.advisory), 'Invalid exception advisory');
    assert(typeof exception.version === 'string' && exception.version.trim(), 'Missing exception version');
    assert(severities.includes(exception.severity), 'Invalid exception severity');
    assert(typeof exception.reason === 'string' && exception.reason.trim(), 'Missing exception rationale');
    checkNodes(exception.nodes, exception.package);
    const expires = Date.parse(exception.expiresAt);
    assert(Number.isFinite(expires) && new Date(expires).toISOString() === exception.expiresAt, 'Invalid exception expiry');
    assert(now < expires, `${exception.advisory}: exception expired at ${exception.expiresAt}`);
    const key = `${exception.package}:${exception.advisory}`;
    assert(!exceptions.has(key), `${key}: duplicate exception`);
    exceptions.set(key, exception);
  }

  const origins = new Map();
  const graph = new Map();
  const observedCounts = Object.fromEntries(severities.map((severity) => [severity, 0]));
  for (const [name, entry] of entries) {
    assert(packagePattern.test(name) && isObject(entry) && entry.name === name, 'Invalid vulnerability entry');
    assert(severities.includes(entry.severity), `${name}: unknown severity`);
    observedCounts[entry.severity]++;
    assert(Array.isArray(entry.via) && entry.via.length > 0, `${name}: missing advisory origins`);
    checkNodes(entry.nodes, name);
    for (const node of entry.nodes) {
      const version = lock.packages[node]?.version;
      assert(typeof version === 'string' && version, `${node}: not found in lockfile`);
      assert.equal(readVersion(node), version, `${node}: installed version differs from lockfile; run npm ci`);
    }
    const edges = [];
    for (const via of entry.via) {
      if (typeof via === 'string') {
        assert(Object.hasOwn(report.vulnerabilities, via), `${name}: unresolved advisory reference ${via}`);
        edges.push({dependency: via});
        continue;
      }
      assert(isObject(via) && via.name === name && via.dependency === name &&
        severities.includes(via.severity) && typeof via.range === 'string', `${name}: invalid advisory`);
      const id = typeof via.url === 'string' && advisoryPattern.exec(via.url)?.[1];
      assert(id, `${name}: unsupported advisory URL`);
      const key = `${name}:${id}`;
      const exception = exceptions.get(key);
      assert(exception, `Unreviewed advisory: ${name} ${id} (${via.severity}) ${via.url}`);
      assert.equal(via.severity, exception.severity, `${key}: advisory severity changed`);
      assert.deepEqual([...entry.nodes].sort(), [...exception.nodes].sort(), `${key}: affected paths changed`);
      for (const node of entry.nodes) {
        assert.equal(lock.packages[node].version, exception.version, `${key}: affected version changed`);
      }
      origins.set(key, {...exception, severity: via.severity});
      edges.push({origin: key});
    }
    graph.set(name, edges);
  }
  for (const severity of severities) {
    assert.equal(observedCounts[severity], counts[severity], `Audit severity count mismatch: ${severity}`);
  }
  // npm's parent severity must match the highest reachable advisory severity.
  for (const [name, entry] of entries) {
    const pending = [name];
    const seen = new Set();
    let highestSeverity = -1;
    while (pending.length > 0) {
      const current = pending.pop();
      if (seen.has(current)) continue;
      seen.add(current);
      for (const edge of graph.get(current)) {
        if (edge.origin) {
          highestSeverity = Math.max(highestSeverity, severities.indexOf(origins.get(edge.origin).severity));
        } else {
          pending.push(edge.dependency);
        }
      }
    }
    assert(highestSeverity >= 0, `${name}: no advisory origin (unresolved reference cycle)`);
    assert.equal(entry.severity, severities[highestSeverity], `${name}: severity differs from advisory origins`);
  }
  for (const key of exceptions.keys()) {
    assert(origins.has(key), `${key}: unused exception; remove it instead of retaining an allowlist`);
  }
  return {counts, exceptions: [...origins.values()]};
}

export function checkAudit(root = siteRoot, {run = spawnSync, now = Date.now()} = {}) {
  const result = run('npm', ['audit', '--json', '--include=dev', '--include=optional', '--include=peer', '--audit-level=low'], {
    cwd: root,
    encoding: 'utf8',
    timeout: 120_000,
    maxBuffer: 16 * 1024 * 1024,
    shell: process.platform === 'win32',
  });
  assert(!result.error && !result.signal && [0, 1].includes(result.status), `npm audit failed: ${result.error?.message ?? result.signal ?? result.status}`);
  let report;
  try {
    report = JSON.parse(result.stdout);
  } catch {
    throw new Error('npm audit did not return valid JSON');
  }
  const summary = validateAudit({
    report,
    policy: JSON.parse(readFileSync(join(root, 'audit-exceptions.json'), 'utf8')),
    lockText: readFileSync(join(root, 'package-lock.json'), 'utf8'),
    readVersion: (node) => JSON.parse(readFileSync(join(root, node, 'package.json'), 'utf8')).version,
    now,
  });
  assert(result.status === 0 || summary.counts.total > 0, 'npm audit failed without reporting vulnerabilities');
  return summary;
}

if (process.argv[1] && resolve(process.argv[1]) === scriptPath) {
  try {
    const summary = checkAudit();
    console.log(`Audit: ${summary.counts.total} affected package entries; ${summary.exceptions.length} temporarily excepted advisories.`);
    for (const exception of summary.exceptions) {
      console.warn(`UNFIXED ${exception.severity}: ${exception.package}@${exception.version} ${exception.advisory}; expires ${exception.expiresAt}\n${exception.reason}`);
    }
  } catch (error) {
    console.error(error.message);
    process.exitCode = 1;
  }
}
