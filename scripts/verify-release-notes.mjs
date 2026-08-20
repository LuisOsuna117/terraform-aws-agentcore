import { readFile } from "node:fs/promises";
import { generateNotes } from "@semantic-release/release-notes-generator";

const config = JSON.parse(await readFile(".releaserc.json", "utf8"));
const releaseNotesPlugin = config.plugins.find(
  (plugin) =>
    Array.isArray(plugin) &&
    plugin[0] === "@semantic-release/release-notes-generator",
);

if (!releaseNotesPlugin) {
  throw new Error("Release notes generator configuration was not found");
}

const notes = await generateNotes(releaseNotesPlugin[1], {
  commits: [
    {
      hash: "0123456789abcdef0123456789abcdef01234567",
      message: "feat(runtime): add IAM extensions and MMDSv2 enforcement",
    },
    {
      hash: "89abcdef0123456789abcdef0123456789abcdef",
      message: "fix(release): pin and verify changelog generation",
    },
  ],
  lastRelease: {
    gitHead: "1111111111111111111111111111111111111111",
    gitTag: "v0.7.0",
  },
  nextRelease: {
    gitHead: "2222222222222222222222222222222222222222",
    gitTag: "v0.8.0",
    version: "0.8.0",
  },
  options: {
    repositoryUrl: "https://github.com/LuisOsuna117/terraform-aws-agentcore.git",
  },
  cwd: process.cwd(),
});

const expectedFragments = [
  "🚀 Features",
  "add IAM extensions and MMDSv2 enforcement",
  "🐛 Bug Fixes",
  "pin and verify changelog generation",
];
const missingFragments = expectedFragments.filter(
  (fragment) => !notes.includes(fragment),
);

if (missingFragments.length > 0) {
  throw new Error(
    `Generated release notes are missing: ${missingFragments.join(", ")}\n\n${notes}`,
  );
}

console.log(notes);
