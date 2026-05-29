#!/usr/bin/env node
import { execFileSync } from 'node:child_process';
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const rootDir = dirname(dirname(fileURLToPath(import.meta.url)));
const outDir = join(rootDir, 'dist');
const version = (process.env.RELEASE_VERSION || readFileSync(join(rootDir, 'VERSION'), 'utf8')).trim().replace(/^v/, '');
const tagName = `v${version}`;
const releaseUrl = `https://github.com/manix84/ttt_karma_tracker/releases/tag/${tagName}`;

const runGit = (args) => {
  try {
    return execFileSync('git', args, { cwd: rootDir, encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }).trim();
  } catch {
    return '';
  }
};

const previousTag = () => {
  const tags = runGit(['tag', '--merged', 'HEAD', '--sort=-creatordate', '--list', 'v[0-9]*'])
    .split('\n')
    .map((tag) => tag.trim())
    .filter(Boolean)
    .filter((tag) => tag !== tagName);

  return tags[0] || '';
};

const replacements = new Map([
  [
    'Add CI and deployment workflows, validation scripts, and update documentation',
    'Added CI, deployment workflows, validation scripts, and documentation'
  ],
  [
    'Add local install helper for Garry\'s Mod testing and update documentation',
    'Added local install helper for Garry\'s Mod testing'
  ],
  [
    'Add first-publish helper script and update documentation for Steam Workshop integration',
    'Added first-publish helper for Steam Workshop integration'
  ],
  [
    'Initial production-ready structure for TTT Karma Market addon',
    'Added the initial production-ready TTT Karma Market addon'
  ],
  ['Complete re-write, simplification.', 'Simplified the addon implementation and folder structure'],
  ['Adding screenshots', 'Added screenshots'],
  [
    'Add support for Steam loginusers.vdf in deployment workflow and update README instructions',
    'Added Steam loginusers.vdf support to the deployment workflow and updated setup instructions'
  ],
  [
    'Enhance SteamCMD deployment workflow with validation for config files and update README instructions for creating auth secrets',
    'Enhanced SteamCMD deployment validation and documented auth secret setup'
  ],
  [
    'Correct image URL and update manual install link in README',
    'Corrected README image and manual install links'
  ]
]);

const ignoredSubjects = [
  /^Update README\.md$/i,
  /^Updated README\.md$/i,
  /^Bump version\b/i,
  /^Initial commit$/i,
  /^Create sh_karma_tracker\.lua$/i,
  /^Create logging\.lua$/i,
  /^Fixing stupid error\.$/i,
  /^More folder structures updates\.$/i
];

const cleanSubject = (subject) => {
  const cleaned = subject
    .replace(/^\w+(?:\([^)]+\))?!?:\s*/, '')
    .replace(/^./, (character) => character.toUpperCase())
    .trim();

  return (replacements.get(cleaned) ?? cleaned)
    .replace(/^Add\b/, 'Added')
    .replace(/^Enhance\b/, 'Enhanced')
    .replace(/^Update\b/, 'Updated')
    .replace(/^Correct\b/, 'Corrected')
    .replace(/^Clarify\b/, 'Clarified');
};

const categoryFor = (subject) => {
  if (/^feat(?:\([^)]+\))?!?:/i.test(subject)) return 'Added';
  if (/^fix(?:\([^)]+\))?!?:/i.test(subject)) return 'Fixed';
  if (/^(docs|chore|ci|build|refactor|style|test)(?:\([^)]+\))?!?:/i.test(subject)) return 'Maintenance';
  return 'Changed';
};

const commitRange = previousTag();
const logRange = commitRange ? `${commitRange}..HEAD` : 'HEAD';
const subjects = runGit(['log', '--no-merges', '--format=%s', logRange])
  .split('\n')
  .map((subject) => subject.trim())
  .filter(Boolean)
  .filter((subject) => !/^chore(?:\([^)]+\))?: release\b/i.test(subject));

const grouped = new Map();

for (const subject of subjects.reverse()) {
  const category = categoryFor(subject);
  const summary = cleanSubject(subject);

  if (!summary) continue;
  if (ignoredSubjects.some((pattern) => pattern.test(summary))) continue;
  if (!grouped.has(category)) grouped.set(category, []);
  if (!grouped.get(category).includes(summary)) {
    grouped.get(category).push(summary);
  }
}

if (grouped.size === 0) {
  grouped.set('Changed', ['Published the latest TTT Karma Market package.']);
}

const orderedCategories = ['Added', 'Changed', 'Fixed', 'Maintenance'];
const markdownLines = [`# TTT Karma Market ${tagName}`, ''];
const steamLines = [`[h1]TTT Karma Market ${tagName}[/h1]`, ''];

if (commitRange) {
  markdownLines.push(`Changes since ${commitRange}.`, '');
  steamLines.push(`Changes since ${commitRange}.`, '');
}

for (const category of orderedCategories) {
  const entries = grouped.get(category);
  if (!entries?.length) continue;

  markdownLines.push(`## ${category}`);
  steamLines.push(`[h2]${category}[/h2]`);
  steamLines.push('[list]');

  for (const entry of entries) {
    markdownLines.push(`- ${entry}`);
    steamLines.push(`[*]${entry}`);
  }

  markdownLines.push('');
  steamLines.push('[/list]', '');
}

steamLines.push(`Tagged release: [url=${releaseUrl}]${tagName}[/url]`);

mkdirSync(outDir, { recursive: true });
writeFileSync(join(outDir, 'release-notes.md'), `${markdownLines.join('\n').trim()}\n`);
writeFileSync(join(outDir, 'steam-change-notes.txt'), `${steamLines.join('\n').trim()}\n`);

console.log(`Generated release notes for ${tagName}${commitRange ? ` from ${commitRange}` : ''}.`);
