#!/usr/bin/env bun
import { $ } from "bun";

// Usage: bun run analyze-conflicts.ts <PR_URL>

const PR_URL = process.argv[2];
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

if (!PR_URL) {
    console.error("Usage: bun run analyze-conflicts.ts <PR_URL>");
    process.exit(1);
}

if (!OPENAI_API_KEY) {
    console.log("No OPENAI_API_KEY provided. Skipping AI analysis.");
    process.exit(0);
}

console.log(`Analyzing conflicts for PR: ${PR_URL}`);

// 1. Identify conflicting files
// We can check the git status or diff, but since we committed the markers, 
// we can grep for them in the changed files of the sync branch.

// Get list of changed files in the current commit (which should be the merge commit with conflicts)
// git show --name-only --format="" HEAD
const changedFilesOutput = await $`git show --name-only --format="" HEAD`.text();
const changedFiles = changedFilesOutput.trim().split("\n").filter((f: string) => f);

console.log(`Changed files: ${changedFiles.join(", ")}`);

// 2. For each file, find conflict markers
for (const file of changedFiles) {
    if (!file) continue;

    try {
        const content = await Bun.file(file).text();

        // Regex to find conflict blocks
        // <<<<<<< HEAD
        // ...
        // =======
        // ...
        // >>>>>>> upstream/main

        // Note: Standard JS regex for multiline matching
        const conflictRegex = /<<<<<<< HEAD([\s\S]*?)=======([\s\S]*?)>>>>>>> ([^\n]+)/g;

        let match;
        while ((match = conflictRegex.exec(content)) !== null) {
            const fullBlock = match[0];
            const localContent = match[1];
            const remoteContent = match[2];
            const remoteLabel = match[3];

            // Calculate line number (approximation)
            // detailed mapping is hard without keeping track of indices, 
            // but we can try to find the match index in the original file
            const linesPrefix = content.substring(0, match.index).split("\n");
            const startLine = linesPrefix.length;

            console.log(`Found conflict in ${file} at line ${startLine}`);

            // 3. Ask AI for resolution
            const resolution = await getAIResolution(file, localContent, remoteContent);

            // 4. Post comment to PR
            // Use gh cli to comment
            // gh pr comment <url> --body "..."
            // Trying to post a review comment on a specific line is tricky via CLI if the line hasn't been "changed" in the way GitHub expects for unified diffs, 
            // but since we *just* committed these lines, they are part of the diff.
            // However, figuring out the specific position in the diff is complex.
            // We will fallback to a general comment or trying to use the line number.

            const commentBody = `
**Conflict Detected at line ${startLine}**

**Local (Target):**
\`\`\`
${localContent.trim()}
\`\`\`

**Upstream:**
\`\`\`
${remoteContent.trim()}
\`\`\`

**AI Suggestion:**
${resolution}
`;

            // For simplicity, just posting a general comment for now. 
            // To post a review comment, we'd need to use the API directly with 'commit_id', 'path', 'line'.
            // Let's try to just post a regular comment clearly identifying the location.
            await $`gh pr comment ${PR_URL} --body ${commentBody}`;
        }
    } catch (e) {
        console.error(`Error processing file ${file}:`, e);
    }
}

async function getAIResolution(filename: string, local: string, remote: string): Promise<string> {
    const prompt = `
You are an expert Git Merge Conflict Resolver.
I have a merge conflict in file: "${filename}".

LOCAL CHANGE (Current Branch):
${local}

REMOTE CHANGE (Upstream):
${remote}

Please analyze the intent of both changes and provide a merged version that preserves the best of both, or explains why they conflict.
If it's code, provide the resolved code block.
Keep the explanation concise.
`;

    try {
        const response = await fetch("https://api.openai.com/v1/chat/completions", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${OPENAI_API_KEY}`
            },
            body: JSON.stringify({
                model: "gpt-4o", // or gpt-3.5-turbo
                messages: [
                    { role: "system", content: "You are a helpful coding assistant resolving git conflicts." },
                    { role: "user", content: prompt }
                ],
                max_tokens: 1000
            })
        });

        const data = await response.json();
        return data.choices[0].message.content;
    } catch (error) {
        console.error("AI Request failed:", error);
        return "AI Analysis failed to generate a suggestion.";
    }
}
