#!/usr/bin/env node
import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';

const releaseType = process.argv[2] ?? 'auto';
const explicitReleaseTypes = new Set(['major', 'minor', 'patch']);
const automaticReleaseTypes = new Set(['auto', 'prepush']);
const hookReleaseTypes = new Set(['precommit']);
const versionTagPattern = /^v(\d+\.\d+\.\d+)$/;
const versionFile = new URL('../VERSION', import.meta.url);

const runGit = (args) => {
  try {
    return execFileSync('git', args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
  } catch {
    return '';
  }
};

const latestVersionTag = () => runGit(['describe', '--tags', '--abbrev=0', '--match', 'v[0-9]*']);

const currentVersion = () => readFileSync(versionFile, 'utf8').trim().replace(/^v/, '');

const compareVersions = (left, right) => {
  const leftParts = left.split('.').map(Number);
  const rightParts = right.split('.').map(Number);

  for (let index = 0; index < 3; index += 1) {
    if (leftParts[index] > rightParts[index]) { return 1; }
    if (leftParts[index] < rightParts[index]) { return -1; }
  }

  return 0;
};

const latestTaggedVersion = () => {
  const tag = latestVersionTag();
  const match = tag.match(versionTagPattern);
  return match?.[1];
};

const upstreamRef = () => runGit(['rev-parse', '--abbrev-ref', '--symbolic-full-name', '@{upstream}']);

const defaultBaseRef = () => {
  const originHead = runGit(['symbolic-ref', '--quiet', '--short', 'refs/remotes/origin/HEAD']);
  if (originHead) { return originHead; }
  if (runGit(['rev-parse', '--verify', 'origin/main'])) { return 'origin/main'; }
  if (runGit(['rev-parse', '--verify', 'origin/master'])) { return 'origin/master'; }
  return undefined;
};

const versionAtRef = (ref) => {
  if (!ref) { return undefined; }

  try {
    return execFileSync('git', ['show', `${ref}:VERSION`], { encoding: 'utf8' }).trim().replace(/^v/, '');
  } catch {
    return undefined;
  }
};

const commitsSinceLatestVersion = (baseRef) => {
  if (baseRef) {
    return runGit(['log', '--format=%B%n---COMMIT-END---', `${baseRef}..HEAD`]);
  }

  const tag = latestVersionTag();
  const range = tag ? `${tag}..HEAD` : 'HEAD';

  return runGit(['log', '--format=%B%n---COMMIT-END---', range]);
};

const inferReleaseType = (baseRef) => {
  const commits = commitsSinceLatestVersion(baseRef);

  if (/BREAKING CHANGE:/m.test(commits) || /^[a-z]+(?:\([^)]+\))?!:/m.test(commits)) {
    return 'major';
  }

  if (/^feat(?:\([^)]+\))?:/m.test(commits)) {
    return 'minor';
  }

  return 'patch';
};

const bumpVersion = (version, bumpType) => {
  const match = version.match(/^(\d+)\.(\d+)\.(\d+)$/);

  if (!match) {
    console.error(`Current version must be semver, got: ${version}`);
    process.exit(1);
  }

  let [, major, minor, patch] = match.map(Number);

  if (bumpType === 'major') {
    major += 1;
    minor = 0;
    patch = 0;
  } else if (bumpType === 'minor') {
    minor += 1;
    patch = 0;
  } else {
    patch += 1;
  }

  return `${major}.${minor}.${patch}`;
};

const explicitVersion = releaseType.match(/^v?(\d+\.\d+\.\d+)$/)?.[1];
const prepushBaseRef = releaseType === 'prepush' ? upstreamRef() || defaultBaseRef() : undefined;
const hookReleaseType = hookReleaseTypes.has(releaseType) ? process.env.VERSION_BUMP ?? 'patch' : undefined;
const nextReleaseType = explicitVersion
  ? undefined
  : hookReleaseType ?? (automaticReleaseTypes.has(releaseType) ? inferReleaseType(prepushBaseRef) : releaseType);

if (!explicitVersion && !explicitReleaseTypes.has(nextReleaseType)) {
  console.error('Usage: node scripts/bump-version.mjs [auto|precommit|prepush|major|minor|patch|x.y.z|vx.y.z]');
  console.error('Set VERSION_BUMP=major|minor|patch when using precommit mode.');
  process.exit(1);
}

const taggedVersion = latestTaggedVersion();

if (releaseType === 'precommit') {
  const version = currentVersion();
  const headVersion = versionAtRef('HEAD');

  if (headVersion && compareVersions(version, headVersion) > 0) {
    console.log(`Version ${version} is already ahead of HEAD ${headVersion}; skipping pre-commit bump.`);
    process.exit(0);
  }
}

if (automaticReleaseTypes.has(releaseType)) {
  const version = currentVersion();
  const upstreamVersion = versionAtRef(prepushBaseRef);

  if (upstreamVersion && compareVersions(version, upstreamVersion) > 0) {
    console.log(`Version ${version} is already ahead of upstream ${upstreamVersion}.`);
    process.exit(0);
  }

  if (taggedVersion && compareVersions(version, taggedVersion) > 0) {
    console.log(`Version ${version} is already ahead of latest tag v${taggedVersion}.`);
    process.exit(0);
  }

  if (releaseType === 'prepush' && !prepushBaseRef && !taggedVersion) {
    console.log('No upstream, default branch, or version tag found; skipping automatic pre-push version bump.');
    process.exit(0);
  }
}

const previousVersion = currentVersion();
const nextVersion = explicitVersion ?? bumpVersion(previousVersion, nextReleaseType);

writeFileSync(versionFile, `${nextVersion}\n`);
console.log(`${previousVersion} -> ${nextVersion}`);
