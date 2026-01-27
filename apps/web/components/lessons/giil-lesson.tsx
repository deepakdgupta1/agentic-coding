'use client';

import {
  Terminal,
  Image as ImageIcon,
  Cloud,
  Download,
  Eye,
  Share2,
  CheckCircle,
  AlertCircle,
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

export function GiilLesson() {
  return (
    <div className="space-y-8">
      <GoalBanner>
        Download cloud-hosted images for visual debugging with giil.
      </GoalBanner>

      {/* Section 1: What Is GIIL */}
      <Section title="What Is GIIL?" icon={<ImageIcon className="h-5 w-5" />} delay={0.1}>
        <Paragraph>
          <Highlight>GIIL</Highlight> (Get Image from Internet Link) downloads full-resolution images
          from cloud sharing services directly to your terminal. When a user shares a screenshot via
          iCloud, Dropbox, or Google Photos, GIIL fetches the actual image for AI agent analysis.
        </Paragraph>
        <Paragraph>
          This bridges the gap between mobile screenshots and terminal-based debugging. Users capture
          bugs on their phone, share a link, and agents can immediately view and analyze the image.
        </Paragraph>

        <div className="mt-8">
          <FeatureGrid>
            <FeatureCard
              icon={<Cloud className="h-5 w-5" />}
              title="Multi-Platform"
              description="iCloud, Dropbox, Google Photos, Drive"
              gradient="from-blue-500/20 to-cyan-500/20"
            />
            <FeatureCard
              icon={<Download className="h-5 w-5" />}
              title="Full Resolution"
              description="Downloads original quality images"
              gradient="from-emerald-500/20 to-teal-500/20"
            />
            <FeatureCard
              icon={<Eye className="h-5 w-5" />}
              title="Visual Debugging"
              description="AI agents can analyze images"
              gradient="from-purple-500/20 to-pink-500/20"
            />
            <FeatureCard
              icon={<Share2 className="h-5 w-5" />}
              title="Album Support"
              description="Download all photos with --all"
              gradient="from-amber-500/20 to-orange-500/20"
            />
          </FeatureGrid>
        </div>
      </Section>

      <Divider />

      {/* Section 2: Supported Platforms */}
      <Section title="Supported Platforms" icon={<Cloud className="h-5 w-5" />} delay={0.15}>
        <Paragraph>
          GIIL extracts images from these cloud sharing services:
        </Paragraph>
        <div className="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="p-4 rounded-lg bg-gradient-to-br from-slate-800/50 to-slate-900/50 border border-slate-700/50">
            <h4 className="font-semibold text-white mb-2">iCloud</h4>
            <code className="text-xs text-slate-400">share.icloud.com/*</code>
          </div>
          <div className="p-4 rounded-lg bg-gradient-to-br from-slate-800/50 to-slate-900/50 border border-slate-700/50">
            <h4 className="font-semibold text-white mb-2">Dropbox</h4>
            <code className="text-xs text-slate-400">dropbox.com/s/*, dl.dropbox.com/*</code>
          </div>
          <div className="p-4 rounded-lg bg-gradient-to-br from-slate-800/50 to-slate-900/50 border border-slate-700/50">
            <h4 className="font-semibold text-white mb-2">Google Photos</h4>
            <code className="text-xs text-slate-400">photos.google.com/*</code>
          </div>
          <div className="p-4 rounded-lg bg-gradient-to-br from-slate-800/50 to-slate-900/50 border border-slate-700/50">
            <h4 className="font-semibold text-white mb-2">Google Drive</h4>
            <code className="text-xs text-slate-400">drive.google.com/*</code>
          </div>
        </div>
      </Section>

      <Divider />

      {/* Section 3: Essential Commands */}
      <Section title="Essential Commands" icon={<Terminal className="h-5 w-5" />} delay={0.2}>
        <CommandList
          commands={[
            { command: 'giil "<url>"', description: 'Download image from cloud link' },
            { command: 'giil "<url>" --output ~/screenshots', description: 'Save to custom directory' },
            { command: 'giil "<url>" --json', description: 'Output JSON metadata' },
            { command: 'giil "<url>" --all', description: 'Download all images from album' },
            { command: 'giil --help', description: 'Show all options' },
          ]}
        />

        <TipBox variant="info">
          Always wrap URLs in quotes to prevent shell expansion of special characters.
        </TipBox>
      </Section>

      <Divider />

      {/* Section 4: Visual Debugging Workflow */}
      <Section title="Visual Debugging Workflow" icon={<Eye className="h-5 w-5" />} delay={0.25}>
        <Paragraph>
          GIIL enables a powerful visual debugging pattern for AI-assisted development:
        </Paragraph>

        <div className="mt-6 space-y-4">
          <div className="flex items-start gap-4">
            <div className="flex-shrink-0 w-8 h-8 rounded-full bg-blue-500/20 flex items-center justify-center text-blue-400 font-bold">1</div>
            <div>
              <h4 className="font-semibold text-white">User Screenshots Bug</h4>
              <p className="text-slate-400 text-sm">User captures the issue on their phone or desktop</p>
            </div>
          </div>
          <div className="flex items-start gap-4">
            <div className="flex-shrink-0 w-8 h-8 rounded-full bg-emerald-500/20 flex items-center justify-center text-emerald-400 font-bold">2</div>
            <div>
              <h4 className="font-semibold text-white">Share Cloud Link</h4>
              <p className="text-slate-400 text-sm">User shares iCloud/Dropbox/Google Photos link with agent</p>
            </div>
          </div>
          <div className="flex items-start gap-4">
            <div className="flex-shrink-0 w-8 h-8 rounded-full bg-purple-500/20 flex items-center justify-center text-purple-400 font-bold">3</div>
            <div>
              <h4 className="font-semibold text-white">GIIL Downloads Image</h4>
              <p className="text-slate-400 text-sm"><code className="text-xs">giil &quot;&lt;url&gt;&quot;</code> fetches full-resolution image to working directory</p>
            </div>
          </div>
          <div className="flex items-start gap-4">
            <div className="flex-shrink-0 w-8 h-8 rounded-full bg-amber-500/20 flex items-center justify-center text-amber-400 font-bold">4</div>
            <div>
              <h4 className="font-semibold text-white">Agent Analyzes</h4>
              <p className="text-slate-400 text-sm">AI agent can now view and understand the visual context</p>
            </div>
          </div>
        </div>

        <CodeBlock code={`# Example: User reports UI bug
# They share: https://share.icloud.com/photos/abc123

# Download the screenshot
giil "https://share.icloud.com/photos/abc123"

# Image saved to current directory
# Agent can now analyze: screenshot.jpg`} />
      </Section>

      <Divider />

      {/* Section 5: Exit Codes */}
      <Section title="Exit Codes" icon={<CheckCircle className="h-5 w-5" />} delay={0.3}>
        <Paragraph>
          GIIL uses specific exit codes to indicate different outcomes:
        </Paragraph>

        <div className="mt-4 space-y-2">
          <div className="flex items-center gap-3 p-3 rounded-lg bg-emerald-500/10 border border-emerald-500/20">
            <CheckCircle className="h-5 w-5 text-emerald-400" />
            <span className="text-emerald-300 font-mono">0</span>
            <span className="text-slate-300">Success - Image downloaded</span>
          </div>
          <div className="flex items-center gap-3 p-3 rounded-lg bg-red-500/10 border border-red-500/20">
            <AlertCircle className="h-5 w-5 text-red-400" />
            <span className="text-red-300 font-mono">10</span>
            <span className="text-slate-300">Network error - Check connectivity</span>
          </div>
          <div className="flex items-center gap-3 p-3 rounded-lg bg-amber-500/10 border border-amber-500/20">
            <AlertCircle className="h-5 w-5 text-amber-400" />
            <span className="text-amber-300 font-mono">11</span>
            <span className="text-slate-300">Auth required - Link not publicly shared</span>
          </div>
          <div className="flex items-center gap-3 p-3 rounded-lg bg-orange-500/10 border border-orange-500/20">
            <AlertCircle className="h-5 w-5 text-orange-400" />
            <span className="text-orange-300 font-mono">12</span>
            <span className="text-slate-300">Not found - Link expired or deleted</span>
          </div>
          <div className="flex items-center gap-3 p-3 rounded-lg bg-slate-500/10 border border-slate-500/20">
            <AlertCircle className="h-5 w-5 text-slate-400" />
            <span className="text-slate-300 font-mono">13</span>
            <span className="text-slate-300">Unsupported type - Video or document</span>
          </div>
        </div>

        <TipBox variant="warning">
          Exit code 11 (auth required) means the link is private. Ask the user to update
          sharing settings to &quot;Anyone with the link.&quot;
        </TipBox>
      </Section>

      <Divider />

      {/* Section 6: Advanced Usage */}
      <Section title="Advanced Usage" icon={<Terminal className="h-5 w-5" />} delay={0.35}>
        <CodeBlock code={`# Download to specific directory
giil "https://share.icloud.com/photos/abc123" --output ~/debug-screenshots

# Get JSON metadata (useful for scripting)
giil "https://dropbox.com/s/xyz789/screenshot.png" --json

# Download all images from a shared album
giil "https://photos.google.com/share/album123" --all

# Check if download succeeded in a script
if giil "$URL" 2>/dev/null; then
  echo "Image ready for analysis"
else
  echo "Download failed with code $?"
fi`} />

        <TipBox variant="info">
          GIIL only supports images. For videos or documents, you&apos;ll need to download
          them manually or use a different tool.
        </TipBox>
      </Section>
    </div>
  );
}
