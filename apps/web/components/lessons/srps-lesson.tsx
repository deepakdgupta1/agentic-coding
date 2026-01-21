"use client";

import { motion } from "@/components/motion";
import {
  Shield,
  Activity,
  Gauge,
  Terminal,
  Settings,
  Zap,
  Monitor,
  Cpu,
} from "lucide-react";
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
  BulletList,
} from "./lesson-components";

export function SrpsLesson() {
  return (
    <div className="space-y-8">
      <GoalBanner>
        Keep your workstation responsive under heavy AI agent load.
      </GoalBanner>

      <Section
        title="What Is SRPS?"
        icon={<Shield className="h-5 w-5" />}
        delay={0.1}
      >
        <Paragraph>
          <Highlight>SRPS (System Resource Protection Script)</Highlight> installs
          ananicy-cpp with 1700+ rules to automatically deprioritize background
          processes, plus sysmoni TUI for real-time monitoring. When AI agents
          run heavy builds, SRPS keeps your terminal responsive.
        </Paragraph>
        <Paragraph>
          Think of it as automatic resource management: compilers, bundlers, and
          test runners get deprioritized so your interactive sessions stay snappy.
        </Paragraph>

        <div className="mt-8">
          <FeatureGrid>
            <FeatureCard
              icon={<Cpu className="h-5 w-5" />}
              title="1700+ Rules"
              description="Pre-configured for compilers, bundlers, browsers, IDEs"
              gradient="from-yellow-500/20 to-orange-500/20"
            />
            <FeatureCard
              icon={<Activity className="h-5 w-5" />}
              title="sysmoni TUI"
              description="Real-time CPU/memory monitoring with ananicy status"
              gradient="from-emerald-500/20 to-teal-500/20"
            />
            <FeatureCard
              icon={<Gauge className="h-5 w-5" />}
              title="Sysctl Tweaks"
              description="Kernel optimizations for responsiveness under memory pressure"
              gradient="from-primary/20 to-violet-500/20"
            />
            <FeatureCard
              icon={<Settings className="h-5 w-5" />}
              title="Zero Config"
              description="Install once, benefits forever - no tuning needed"
              gradient="from-sky-500/20 to-blue-500/20"
            />
          </FeatureGrid>
        </div>
      </Section>

      <Divider />

      <Section
        title="Installation"
        icon={<Terminal className="h-5 w-5" />}
        delay={0.15}
      >
        <Paragraph>
          SRPS installs the ananicy-cpp daemon and sysmoni monitoring tool in
          one command.
        </Paragraph>

        <div className="mt-6">
          <CodeBlock
            code={`# Install SRPS with all components
$ curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/system_resource_protection_script/main/install.sh | bash -s -- --install

# Verify daemon is running
$ systemctl status ananicy-cpp
> Active: active (running)`}
            language="bash"
          />
        </div>

        <TipBox variant="info">
          Installation requires sudo for systemd service setup and sysctl changes.
          The script will prompt for confirmation before making system changes.
        </TipBox>
      </Section>

      <Divider />

      <Section
        title="Real-Time Monitoring with sysmoni"
        icon={<Monitor className="h-5 w-5" />}
        delay={0.2}
      >
        <Paragraph>
          The <Highlight>sysmoni</Highlight> TUI shows real-time CPU and memory
          usage per process, along with the ananicy rule being applied to each.
        </Paragraph>

        <div className="mt-6">
          <CodeBlock
            code={`# Launch the monitoring TUI
$ sysmoni

# See per-process CPU/memory with ananicy rule status
# q to quit, arrows to navigate, s to sort, f to filter`}
            language="bash"
          />
        </div>

        <BulletList
          items={[
            "Per-process CPU and memory usage",
            "ananicy rule status for each process",
            "Nice level and scheduling class",
            "Real-time updates (configurable interval)",
          ]}
        />
      </Section>

      <Divider />

      <Section
        title="Essential Commands"
        icon={<Terminal className="h-5 w-5" />}
        delay={0.25}
      >
        <CommandList
          commands={[
            {
              command: "sysmoni",
              description: "Launch real-time process monitoring TUI",
            },
            {
              command: "systemctl status ananicy-cpp",
              description: "Check daemon status",
            },
            {
              command: "ls /etc/ananicy.d/",
              description: "List active rule directories",
            },
            {
              command: "journalctl -u ananicy-cpp",
              description: "View daemon logs",
            },
            {
              command: "sudo systemctl restart ananicy-cpp",
              description: "Restart after adding custom rules",
            },
          ]}
        />
      </Section>

      <Divider />

      <Section
        title="What Gets Managed"
        icon={<Gauge className="h-5 w-5" />}
        delay={0.3}
      >
        <Paragraph>
          SRPS automatically deprioritizes resource-intensive processes while
          keeping interactive sessions responsive:
        </Paragraph>

        <BulletList
          items={[
            <>
              <Highlight>Compilers:</Highlight> rustc, gcc, clang, tsc, swc
            </>,
            <>
              <Highlight>Bundlers:</Highlight> webpack, esbuild, vite, rollup
            </>,
            <>
              <Highlight>Test runners:</Highlight> cargo test, jest, pytest
            </>,
            <>
              <Highlight>Browsers:</Highlight> Chrome, Firefox, Electron apps
            </>,
            <>
              <Highlight>IDEs:</Highlight> VS Code, JetBrains, language servers
            </>,
          ]}
        />

        <TipBox variant="tip">
          Your terminal emulator, tmux sessions, and input handling stay at
          normal priority. Heavy builds run in the background without freezing
          your interactive work.
        </TipBox>
      </Section>

      <Divider />

      <Section
        title="Adding Custom Rules"
        icon={<Settings className="h-5 w-5" />}
        delay={0.35}
      >
        <Paragraph>
          You can add rules for any process that SRPS does not know about.
        </Paragraph>

        <div className="mt-6">
          <CodeBlock
            code={`# Example: add rule for a custom heavy process
$ echo '{"name": "my-heavy-process", "nice": 19, "sched": "idle", "ioclass": "idle"}' | \\
    sudo tee /etc/ananicy.d/00-default/99-custom.rules

# Restart to apply
$ sudo systemctl restart ananicy-cpp`}
            language="bash"
          />
        </div>

        <TipBox variant="warning">
          Be careful with nice values below 0 (higher priority). Only root can
          set negative nice values, and overusing them can make your system less
          responsive, not more.
        </TipBox>
      </Section>

      <Divider />

      <Section
        title="Synergies with Other Tools"
        icon={<Zap className="h-5 w-5" />}
        delay={0.4}
      >
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="rounded-2xl border border-white/[0.08] bg-white/[0.02] p-6"
        >
          <BulletList
            items={[
              <>
                <Highlight>ntm:</Highlight> Keeps tmux sessions responsive when
                agents spawn heavy builds
              </>,
              <>
                <Highlight>slb:</Highlight> Prevents multiple agents from
                starving each other for CPU/memory
              </>,
              <>
                <Highlight>dcg:</Highlight> Combined safety - DCG prevents
                destructive commands, SRPS prevents resource exhaustion
              </>,
            ]}
          />
        </motion.div>

        <TipBox variant="info">
          When running multi-agent sessions with SLB, SRPS is especially valuable.
          Each agent may spawn compilers, test runners, and other heavy processes.
          SRPS ensures they do not overwhelm your system.
        </TipBox>
      </Section>

      <Divider />

      <Section
        title="Troubleshooting"
        icon={<Terminal className="h-5 w-5" />}
        delay={0.45}
      >
        <Paragraph>
          If SRPS is not working as expected, check these common issues:
        </Paragraph>

        <div className="mt-6 space-y-4">
          <CodeBlock
            code={`# Check if daemon is running
$ systemctl status ananicy-cpp

# View recent logs
$ journalctl -u ananicy-cpp -n 50

# Validate all rule files
$ ananicy-cpp --config-test

# Uninstall if needed
$ curl -fsSL https://raw.githubusercontent.com/Dicklesworthstone/system_resource_protection_script/main/install.sh | bash -s -- --uninstall`}
            language="bash"
          />
        </div>

        <TipBox variant="info">
          If you need to temporarily disable SRPS, use{" "}
          <Highlight>sudo systemctl stop ananicy-cpp</Highlight>. Re-enable with{" "}
          <Highlight>sudo systemctl start ananicy-cpp</Highlight>.
        </TipBox>
      </Section>
    </div>
  );
}

export default SrpsLesson;
