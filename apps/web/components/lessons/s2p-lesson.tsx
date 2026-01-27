'use client';

import {
  Terminal,
  Zap,
  FileCode,
  Clipboard,
  ListFilter,
  Play,
  Calculator,
  FolderOpen,
} from 'lucide-react';
import {
  Section,
  Paragraph,
  CodeBlock,
  TipBox,
  Highlight,
  Divider,
  GoalBanner,
  CommandList,
  FeatureCard,
  FeatureGrid,
} from './lesson-components';

export function S2pLesson() {
  return (
    <div className="space-y-8">
      <GoalBanner>
        Combine source code files into LLM-ready prompts with interactive file selection and token counting.
      </GoalBanner>

      {/* Section 1: What Is S2P */}
      <Section title="What Is S2P?" icon={<FileCode className="h-5 w-5" />} delay={0.1}>
        <Paragraph>
          <Highlight>S2P (Source to Prompt TUI)</Highlight> is a terminal-based tool for combining
          source code files into a single, LLM-ready prompt. It provides an interactive file browser
          where you can select exactly which files to include, see the combined output in real-time,
          and track your token count as you go.
        </Paragraph>
        <Paragraph>
          Crafting prompts with code context is tedious when done manually. S2P lets you interactively
          navigate your codebase, toggle files on/off, preview the combined output, and copy
          everything to your clipboard in one keystroke. It respects your .gitignore automatically.
        </Paragraph>

        <div className="mt-8">
          <FeatureGrid>
            <FeatureCard
              icon={<FolderOpen className="h-5 w-5" />}
              title="Interactive Selection"
              description="Browse and toggle files visually"
              gradient="from-green-500/20 to-emerald-500/20"
            />
            <FeatureCard
              icon={<Calculator className="h-5 w-5" />}
              title="Token Counting"
              description="tiktoken-accurate, real-time"
              gradient="from-blue-500/20 to-indigo-500/20"
            />
            <FeatureCard
              icon={<Clipboard className="h-5 w-5" />}
              title="Clipboard Copy"
              description="One keystroke to copy output"
              gradient="from-purple-500/20 to-violet-500/20"
            />
            <FeatureCard
              icon={<ListFilter className="h-5 w-5" />}
              title="Gitignore-Aware"
              description="Respects .gitignore automatically"
              gradient="from-amber-500/20 to-orange-500/20"
            />
          </FeatureGrid>
        </div>
      </Section>

      <Divider />

      {/* Section 2: Essential Commands */}
      <Section title="Essential Commands" icon={<Terminal className="h-5 w-5" />} delay={0.2}>
        <CommandList
          commands={[
            { command: 's2p', description: 'Launch interactive TUI in current directory' },
            { command: 's2p /path/to/project', description: 'Open specific directory' },
            { command: 's2p --help', description: 'Show all options' },
          ]}
        />

        <TipBox variant="info">
          S2P is built with React and Ink, giving you a beautiful terminal UI. Use arrow keys to
          navigate, Space to toggle files, and Enter to confirm your selection.
        </TipBox>
      </Section>

      <Divider />

      {/* Section 3: TUI Navigation */}
      <Section title="TUI Navigation" icon={<Zap className="h-5 w-5" />} delay={0.3}>
        <Paragraph>
          Once you launch S2P, you get an interactive file browser. Here are the key controls:
        </Paragraph>
        <CodeBlock code={`# Keyboard Controls
↑/↓          Navigate between files
Space        Toggle file selection
Enter        Expand/collapse directories
a            Select all files
n            Deselect all files
c            Copy to clipboard
q / Esc      Quit`} />

        <Paragraph>
          The interface shows you the total token count in real-time as you select files. This helps
          you stay within Claude&apos;s or GPT&apos;s context window limits.
        </Paragraph>
      </Section>

      <Divider />

      {/* Section 4: Example Workflow */}
      <Section title="Example Workflow" icon={<Play className="h-5 w-5" />} delay={0.4}>
        <CodeBlock code={`# Navigate to your project
cd /data/projects/my-app

# Launch S2P
s2p

# In the TUI:
# 1. Navigate to src/ directory
# 2. Select relevant TypeScript files
# 3. Watch token count update
# 4. Press 'c' to copy to clipboard

# Now paste into Claude/GPT with your question:
# "Here's my source code. Can you help me..."`} />

        <TipBox variant="tip">
          S2P formats the output with clear file path headers and syntax-appropriate code blocks,
          making it easy for LLMs to understand the code structure.
        </TipBox>
      </Section>

      <Divider />

      {/* Section 5: Synergies */}
      <Section title="Synergies with Other Tools" icon={<FileCode className="h-5 w-5" />} delay={0.5}>
        <Paragraph>
          S2P works great alongside other flywheel tools:
        </Paragraph>
        <ul className="list-disc pl-6 space-y-2 text-muted-foreground">
          <li>
            <strong>CASS:</strong> The prompts you create with S2P can be searched later in your
            agent session history.
          </li>
          <li>
            <strong>CM (CASS Memory):</strong> Use S2P outputs as reference material when extracting
            rules for your memory playbook.
          </li>
          <li>
            <strong>NTM:</strong> Launch S2P in a dedicated tmux pane while your agent works in
            another.
          </li>
        </ul>
      </Section>
    </div>
  );
}
